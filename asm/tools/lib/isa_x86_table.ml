module R = Isa_source_record
open Isa_norm_model

type rclass = Gpr8 | Gpr16 | Gpr32 | Gpr64 | Xmm | Ymm
type field = Modrm_reg | Modrm_rm | Vvvv | Is4

type operand =
  | Reg of { cls : rclass; field : field }
  | Mem of { bits : int }
  | Imm of { bytes : int }

type spec = {
  record_id : string;
  iform : string;
  isa_set : string;
  mnemonic : string;
  space : [ `Legacy | `Vex ];
  map : int;
  opcode : int;
  prefix : int;
  osz : bool;
  w : int;
  l : int;
  digit : int;
  operands : operand list;
  mode : int;
}

let starts_with ~prefix s =
  String.length s >= String.length prefix && String.sub s 0 (String.length prefix) = prefix

let after ~prefix s = String.sub s (String.length prefix) (String.length s - String.length prefix)

(* The pattern tokens this rule understands, with what each says. Any other
   token leaves the record to hand-written work: an unknown constraint must
   never be silently dropped. *)
type pattern = {
  vex : bool;
  vex_prefix : int option;
  vl : int;
  rexw : int;
  memory : bool option;  (** [Some true]: MOD!=3; [Some false]: MOD=3 *)
  digit : int;
  mode64 : bool;
  modrm : bool;
  osz : int;  (** OSZ=: -1 unconstrained, 0, 1 *)
  rep : int;  (** REP=: -1 unconstrained, 0, 2 (F2), 3 (F3) *)
}

let parse_pattern pattern =
  let tokens = String.split_on_char ' ' pattern |> List.filter (fun t -> t <> "") in
  let binary s = int_of_string_opt ("0b" ^ s) in
  List.fold_left
    (fun acc t ->
      match acc with
      | None -> None
      | Some p -> (
          if starts_with ~prefix:"0x" t then Some p
          else
            match t with
            | "VEXVALID=1" -> Some { p with vex = true }
            | "MOD[mm]" | "RM[nnn]" | "REG[rrr]" | "SKIP_OSZ=1" | "MODRM()" | "SE_IMM8()"
            | "UIMM8()" | "VEXDEST3=0b1" | "VEXDEST210=0b111" ->
                Some { p with modrm = p.modrm || t = "MOD[mm]" || t = "RM[nnn]" || t = "REG[rrr]" }
            | "MOD!=3" -> Some { p with memory = Some true; modrm = true }
            | "MOD=3" | "MOD[0b11]" -> Some { p with memory = Some false; modrm = true }
            | "MODE=2" -> Some { p with mode64 = true }
            | "VL=0" -> Some { p with vl = 0 }
            | "VL=1" -> Some { p with vl = 1 }
            | "REXW=0" -> Some { p with rexw = 0 }
            | "REXW=1" -> Some { p with rexw = 1 }
            | "OSZ=0" -> Some { p with osz = 0 }
            | "OSZ=1" -> Some { p with osz = 1 }
            | "REP=0" -> Some { p with rep = 0 }
            | "REP=2" -> Some { p with rep = 2 }
            | "REP=3" -> Some { p with rep = 3 }
            (* no constraint on the encoding: a 0x66 is tolerated, REX2 is APX's *)
            | "IGNORE66()" | "NOREX2=1" | "REX2=0" | "SIMM8()" | "REFINING66()" -> Some p
            | _ when starts_with ~prefix:"VEX_PREFIX=" t ->
                Option.map
                  (fun v -> { p with vex_prefix = Some v })
                  (int_of_string_opt (after ~prefix:"VEX_PREFIX=" t))
            | _ when starts_with ~prefix:"MAP=" t -> Some p
            | _ when starts_with ~prefix:"REG[0b" t && String.length t = 10 ->
                Option.map (fun d -> { p with digit = d; modrm = true }) (binary (String.sub t 6 3))
            | _ -> None))
    (Some
       {
         vex = false;
         vex_prefix = None;
         vl = -1;
         rexw = -1;
         memory = None;
         digit = -1;
         mode64 = false;
         modrm = false;
         osz = -1;
         rep = -1;
       })
    tokens

let class_of_lookup lookup =
  let classes =
    [
      ("XMM_", (Xmm : rclass));
      ("YMM_", Ymm);
      ("VGPR32_", Gpr32);
      ("VGPR64_", Gpr64);
      ("GPR32_", Gpr32);
      ("GPR64_", Gpr64);
    ]
  in
  match List.find_opt (fun (p, _) -> starts_with ~prefix:p lookup) classes with
  | None -> None
  | Some (p, cls) -> (
      match after ~prefix:p lookup with
      | "R" -> Some (cls, Modrm_reg)
      | "B" -> Some (cls, Modrm_rm)
      | "N" -> Some (cls, Vvvv)
      | "SE" -> Some (cls, Is4)
      | _ -> None)

let mem_bits = function
  | Some "b" -> 8
  | Some "w" -> 16
  | Some "d" -> 32
  | Some "q" -> 64
  | Some "dq" -> 128
  | Some "qq" -> 256
  | _ -> 0

(* XED lists the destination first; AT&T lists it last. *)
let operand_of (o : R.x86_operand) =
  if o.visibility = "SUPPRESSED" then Some None
  else if o.visibility <> "DEFAULT" then None
  else
    match (o.op_type, o.lookupfn_name) with
    | "nt_lookup_fn", Some lookup ->
        Option.map (fun (cls, field) -> Some (Reg { cls; field })) (class_of_lookup lookup)
    | "imm_const", _ when starts_with ~prefix:"MEM0" o.op_name ->
        Some (Some (Mem { bits = mem_bits o.oc2 }))
    | "imm_const", _ when starts_with ~prefix:"IMM0" o.op_name && o.oc2 = Some "b" ->
        Some (Some (Imm { bytes = 1 }))
    | _ -> None

(* VEX forms whose AT&T spelling GNU as resolves to the EVEX twin by default;
   the VEX encoding needs a {vex} pseudo-prefix this assembler does not parse. *)
let needs_vex_pseudo_prefix = [ "AVX_VNNI"; "AVX_IFMA"; "AVX_NE_CONVERT" ]

(* The AT&T spelling of an iclass: lower case, XED's 64-bit-operand string
   compares spelled with GNU's [q] suffix, and the narrowing conversions whose
   memory source width AT&T states with an [x]/[y] suffix. *)
let att_mnemonic ~iclass operands =
  let lower = String.lowercase_ascii iclass in
  match iclass with
  | "VPCMPESTRI64" | "VPCMPESTRM64" -> String.sub lower 0 (String.length lower - 2) ^ "q"
  (* GNU as has no q spelling for these: they are twins of the W-ignored forms *)
  | "VPCMPISTRI64" | "VPCMPISTRM64" -> String.sub lower 0 (String.length lower - 2)
  | "VCVTPD2DQ" | "VCVTTPD2DQ" | "VCVTPD2PS" -> (
      match List.find_map (function Mem { bits } -> Some bits | _ -> None) operands with
      | Some 128 -> lower ^ "x"
      | Some 256 -> lower ^ "y"
      | _ -> lower)
  (* XED disambiguates a few iclasses with a suffix GNU does not spell: MOVSD_XMM, PEXTRW_SSE4 *)
  | _ when String.contains lower '_' -> String.sub lower 0 (String.index lower '_')
  | _ -> lower

(* A form the x86-32 export lists that 32-bit mode cannot encode: a legacy REX.W, a 64-bit GPR,
   or a 64-bit-mode-only pattern. GNU as rejects each ("bad register name %rax"). *)
let not_in_32bit_mode (rec_ : R.t) =
  match rec_.encoding with
  | R.X86_encoding { space; pattern; operands; _ } ->
      let tokens = String.split_on_char ' ' pattern in
      List.mem "MODE=2" tokens
      || (space = "legacy" && List.mem "REXW=1" tokens)
      || List.exists
           (fun (o : R.x86_operand) ->
             match o.lookupfn_name with
             | Some l -> starts_with ~prefix:"GPR64_" l || starts_with ~prefix:"VGPR64_" l
             | None -> false)
           operands
  | _ -> false

let spec_of_record (rec_ : R.t) =
  match (rec_.encoding, rec_.provenance) with
  | ( R.X86_encoding { space = "vex"; opcode_map; opcode; pattern; operands },
      R.Xed_provenance { iform = Some iform; isa_set = Some isa_set; _ } ) -> (
      match (parse_pattern pattern, int_of_string_opt opcode) with
      | _ when List.mem isa_set needs_vex_pseudo_prefix -> None
      | Some p, Some opcode when p.vex && p.modrm -> (
          let ops = List.map operand_of operands in
          if List.mem None ops then None
          else
            let xed_order = List.filter_map Fun.id (List.filter_map Fun.id ops) in
            let has_mem = List.exists (function Mem _ -> true | _ -> false) xed_order in
            let has_gpr =
              List.exists
                (function Reg { cls = Gpr8 | Gpr16 | Gpr32 | Gpr64; _ } -> true | _ -> false)
                xed_order
            in
            let prefix =
              match p.vex_prefix with
              | Some 1 -> Some 0x66
              | Some 2 -> Some 0xf2
              | Some 3 -> Some 0xf3
              | Some 0 -> Some 0
              | _ -> None
            in
            match prefix with
            | None -> None
            (* a GPR beside memory makes the AT&T spelling width-ambiguous (vcvtsi2sdl/q) *)
            | Some _ when has_mem && has_gpr -> None
            | Some _ when p.memory = Some true <> has_mem -> None
            | Some prefix ->
                Some
                  {
                    record_id = rec_.record_id;
                    iform;
                    isa_set;
                    mnemonic = att_mnemonic ~iclass:rec_.native_name xed_order;
                    space = `Vex;
                    map = opcode_map;
                    opcode;
                    prefix;
                    osz = false;
                    w = p.rexw;
                    l = p.vl;
                    digit = p.digit;
                    operands = List.rev xed_order;
                    mode = (if p.mode64 then 64 else 0);
                  })
      | _ -> None)
  | ( R.X86_encoding { space = "legacy"; opcode_map; opcode; pattern; operands },
      R.Xed_provenance { iform = Some iform; isa_set = Some isa_set; _ } ) -> (
      match (parse_pattern pattern, int_of_string_opt opcode) with
      | Some p, Some opcode when (not p.vex) && p.modrm -> (
          let ops = List.map operand_of operands in
          if List.mem None ops then None
          else
            let xed_order = List.filter_map Fun.id (List.filter_map Fun.id ops) in
            let has_mem = List.exists (function Mem _ -> true | _ -> false) xed_order in
            let has_gpr =
              List.exists
                (function Reg { cls = Gpr8 | Gpr16 | Gpr32 | Gpr64; _ } -> true | _ -> false)
                xed_order
            in
            let has_xmm =
              List.exists (function Reg { cls = Xmm; _ } -> true | _ -> false) xed_order
            in
            (* the SSE shape first: xmm operands, the mandatory prefix from REP/OSZ *)
            let prefix =
              match (p.rep, p.osz) with
              | 2, (-1 | 0) -> Some 0xf2
              | 3, (-1 | 0) -> Some 0xf3
              | (-1 | 0), 1 -> Some 0x66
              | (-1 | 0), (-1 | 0) -> Some 0
              | _ -> None
            in
            match prefix with
            | Some prefix
              when has_xmm
                   && (not (has_mem && has_gpr))
                   && p.memory = Some true = has_mem
                   && List.for_all
                        (function Reg { field = Vvvv | Is4; _ } -> false | _ -> true)
                        xed_order ->
                Some
                  {
                    record_id = rec_.record_id;
                    iform;
                    isa_set;
                    mnemonic = att_mnemonic ~iclass:rec_.native_name xed_order;
                    space = `Legacy;
                    map = opcode_map;
                    opcode;
                    prefix;
                    osz = false;
                    w = p.rexw;
                    l = -1;
                    digit = p.digit;
                    operands = List.rev xed_order;
                    mode = (if p.mode64 then 64 else 0);
                  }
            | _ -> None)
      | _ -> None)
  | _ -> None

let operand_name i = Printf.sprintf "op%d" i

let form ~requirement (rec_ : R.t) spec =
  let class_ = function
    | Xmm -> X86_xmm
    | Ymm -> X86_ymm
    | Gpr8 | Gpr16 | Gpr32 | Gpr64 -> X86_gpr
  in
  let operands =
    List.mapi
      (fun i o ->
        let op_kind =
          match o with
          | Reg { cls; _ } -> Register { class_ = class_ cls; excluded = [] }
          | Mem { bits } -> Memory { width_bits = (if bits = 0 then None else Some bits) }
          | Imm { bytes } ->
              Immediate
                {
                  width_bits = 8 * bytes;
                  signed = false;
                  implicit_low_zero_bits = 0;
                  nonzero = false;
                  runs = [];
                }
        in
        { op_name = operand_name i; op_kind; role = In; explicit = true })
      spec.operands
  in
  let syntax =
    List.mapi
      (fun i o ->
        match o with
        | Reg _ -> Syn_decorated ("%", Syn_operand (operand_name i))
        | Imm _ -> Syn_decorated ("$", Syn_operand (operand_name i))
        | Mem _ -> Syn_operand (operand_name i))
      spec.operands
  in
  {
    form_id = "x86:" ^ spec.iform;
    arch = X86;
    native_name = rec_.native_name;
    source_record_ids = [ rec_.record_id ];
    requirement;
    encoding =
      X86_encoding
        {
          space = (match spec.space with `Vex -> "vex" | `Legacy -> "legacy");
          opcode_map = spec.map;
          opcode = Printf.sprintf "0x%02X" spec.opcode;
          pattern = (match rec_.encoding with R.X86_encoding { pattern; _ } -> pattern | _ -> "");
        };
    operands;
    syntax = { dialect = "gas-att"; mnemonic = spec.mnemonic; operands = syntax };
    concreteness = Concrete;
    facts =
      [
        {
          label = Upstream;
          note = "space, map, opcode, pattern and operand lookups taken verbatim from the record";
        };
        {
          label = Inferred;
          note =
            "AT&T operand order is XED's explicit order reversed; the mnemonic is the XED iclass \
             in lower case (DEC-X86-TABLE)";
        };
      ];
    diagnostics = [];
  }

(* Two forms spelled the same way with the same operand shape (VMOVAPD's 0x28
   and 0x29 register forms, FMA4's W0 and W1 register forms): GNU as reaches
   only one of them from that spelling. The first in export order is the table
   form; each later one maps to it. *)
let twins specs =
  let shape spec =
    ( spec.mnemonic,
      List.map
        (function Reg { cls; _ } -> `Reg cls | Mem _ -> `Mem | Imm { bytes } -> `Imm bytes)
        spec.operands )
  in
  let groups = Hashtbl.create 64 in
  List.iter
    (fun spec ->
      let k = shape spec in
      Hashtbl.replace groups k (spec :: Option.value (Hashtbl.find_opt groups k) ~default:[]))
    specs;
  let secondaries = Hashtbl.create 16 in
  Hashtbl.iter
    (fun _ group ->
      let group = List.rev group in
      let records = List.sort_uniq compare (List.map (fun s -> s.record_id) group) in
      if List.length records > 1 then
        (* GNU as encodes an is4 register form with VEX.W = 1 (the last source in ModR/M.rm) *)
        let is4 s =
          List.exists (function Reg { field = Is4; _ } -> true | _ -> false) s.operands
        in
        (* GNU as's choice among same-spelled forms, in order: an is4 form takes VEX.W = 1
           (last source in ModR/M.rm) unless it also carries an immediate (vpermil2ps: W = 0);
           a register move puts its destination in ModR/M.reg (the load opcode); otherwise
           the W0 / W-ignored form. *)
        let has_imm s = List.exists (function Imm _ -> true | _ -> false) s.operands in
        let dest_in_reg s =
          match List.rev s.operands with Reg { field = Modrm_reg; _ } :: _ -> true | _ -> false
        in
        let rank s =
          ( (if is4 s then if has_imm s then s.w <> 1 else s.w = 1 else true),
            dest_in_reg s,
            s.w <> 1 )
        in
        let primary =
          List.fold_left
            (fun best s -> if compare (rank s) (rank best) > 0 then s else best)
            (List.hd group) group
        in
        List.iter
          (fun s ->
            if s.record_id <> primary.record_id then
              Hashtbl.replace secondaries s.record_id primary.iform)
          group)
    groups;
  secondaries
