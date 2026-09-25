module R = Isa_source_record
open Isa_norm_model

type operand =
  | Gpr of { field : string; lsb : int; nonzero : bool }
  | Fpr of { field : string; lsb : int }
  | Uimm of { field : string; lsb : int; width : int }
  | Fixed_gpr of int
  | Rm of { lsb : int; default : int }
  | Tied of { lsb : int }
  | Mem_i of { base : int }
  | Mem_s of { base : int }
  | Keyword of string
  | Fli of { lsb : int }
  | Mem_zero of { base : int }
  | Mem_hi of { base : int }
  | Gpr_pair of { field : string; lsb : int; below : int }
  | Fence_set of { field : string; lsb : int }

type spec = {
  record_id : string;
  native_name : string;
  mnemonic : string;
  extension : string;
  width_bits : int;
  mask : string;
  match_ : string;
  operands : operand list;
  xlen : int;
  feature : string;
  isa : string;
  ordering : bool;
}

(* The families admitted through the table: extension file, admitted native
   names ([None]: every table-expressible record of the file; a list: only
   those, because the rest of the file is owned by the hand-written
   encoder), the feature, and the -march ISA string after "rv32"/"rv64"
   (probed against GNU as 2.44 / 2.43.1). *)
let allowlist =
  let fcsr = [ "frcsr"; "frflags"; "frrm"; "fscsr"; "fsflags"; "fsflagsi"; "fsrm"; "fsrmi" ] in
  [
    ("rv_zimop", None, "zimop", "im_zimop");
    ("rv_zicfiss", None, "zicfiss", "im_zimop_zicfiss");
    ("rv64_zba", Some [ "add.uw"; "slli.uw"; "zext.w" ], "zba", "im_zba");
    ("rv_f", Some fcsr, "f", "imf");
    ("rv64_d", Some [ "fmv.x.d"; "fmv.d.x" ], "d", "imfd");
    ("rv_q", None, "q", "imfdq");
    ("rv64_q", None, "q", "imfdq");
    ("rv_zfh", None, "zfh", "imf_zfh");
    ("rv64_zfh", None, "zfh", "imf_zfh");
    ("rv_zfhmin", None, "zfhmin", "imf_zfhmin");
    ("rv_d_zfhmin", None, "zfhmin", "imfd_zfhmin");
    ("rv_q_zfhmin", None, "zfhmin", "imfdq_zfhmin");
    ("rv_zfbfmin", None, "zfbfmin", "imf_zfbfmin");
    ("rv_f_zfa", None, "zfa", "imf_zfa");
    ("rv_d_zfa", None, "zfa", "imfd_zfa");
    ("rv32_d_zfa", None, "zfa", "imfd_zfa");
    ("rv_q_zfa", None, "zfa", "imfdq_zfa");
    ("rv64_q_zfa", None, "zfa", "imfdq_zfa");
    ("rv_zfh_zfa", None, "zfa", "imf_zfh_zfa");
    ("rv_zabha", None, "zabha", "ima_zabha");
    ("rv_zabha_zacas", None, "zacas", "ima_zabha_zacas");
    ("rv_zacas", None, "zacas", "ima_zacas");
    ("rv64_zacas", None, "zacas", "ima_zacas");
    ("rv_zawrs", None, "zawrs", "im_zawrs");
    ("rv_h", None, "h", "im_h");
    ("rv64_h", None, "h", "im_h");
    ("rv_s", None, "s", "im");
    ("rv_system", None, "system", "im");
    ("rv_svinval", None, "svinval", "im_svinval");
    ("rv_svinval_h", None, "svinval", "im_h_svinval");
    ("rv_sdext", None, "sdext", "im");
    ("rv_ssctr", None, "ssctr", "im_ssctr");
    ("rv_zihintntl", None, "zihintntl", "im_zihintntl");
    ("rv_zicntr", None, "zicntr", "im_zicntr");
    ("rv32_zicntr", None, "zicntr", "im_zicntr");
    ("rv_zicfilp", None, "zicfilp", "im_zicfilp");
    ("rv_zicbo", None, "zicbom", "im_zicbom");
    ("rv_zifencei", None, "zifencei", "im_zifencei");
    ("rv_i", Some [ "fence" ], "i", "im");
  ]

(* Zicbo's file holds three extensions, each with its own -march name. *)
let isa_overrides =
  [
    ("cbo.zero", ("zicboz", "im_zicboz"));
    ("prefetch.i", ("zicbop", "im_zicbop"));
    ("prefetch.r", ("zicbop", "im_zicbop"));
    ("prefetch.w", ("zicbop", "im_zicbop"));
  ]

let starts_with ~prefix s =
  String.length s >= String.length prefix && String.sub s 0 (String.length prefix) = prefix

let ends_with ~suffix s =
  let n = String.length s and k = String.length suffix in
  n >= k && String.sub s (n - k) k = suffix

(* Words GNU as requires after the operands although the encoding fixes
   them: fcvtmod.w.d is always round-towards-zero and must say so. *)
let keywords = [ ("fcvtmod.w.d", "rtz") ]

(* Admitted by the table rule (normalized forms and cases) but already
   encoded by the hand-written RISC-V encoder, so no row is emitted: a row
   would be shadowed by the hand-written mnemonic. *)
let hand_encoded = [ "fmv.x.d"; "fence.i"; "fence" ]
let emits_row spec = not (List.mem spec.native_name hand_encoded)

let popcount_hex h =
  let v = Int64.of_string h in
  let rec go v n =
    if v = 0L then n else go (Int64.shift_right_logical v 1) (n + Int64.to_int (Int64.logand v 1L))
  in
  go v 0

(* [sspopchk.x1] is spelled [sspopchk x1]: the suffix names a register the
   encoding fixes. *)
let split_fixed_register native_name =
  match String.rindex_opt native_name '.' with
  | Some i when i + 2 < String.length native_name && native_name.[i + 1] = 'x' -> (
      let digits = String.sub native_name (i + 2) (String.length native_name - i - 2) in
      match int_of_string_opt digits with
      | Some n when n >= 0 && n < 32 && string_of_int n = digits ->
          (String.sub native_name 0 i, Some n)
      | _ -> (native_name, None))
  | _ -> (native_name, None)

let fcsr_pseudos = [ "frcsr"; "frflags"; "frrm"; "fscsr"; "fsflags"; "fsflagsi"; "fsrm"; "fsrmi" ]

let fp_files =
  [
    "rv_f";
    "rv64_d";
    "rv_q";
    "rv64_q";
    "rv_zfh";
    "rv64_zfh";
    "rv_zfhmin";
    "rv_d_zfhmin";
    "rv_q_zfhmin";
    "rv_zfbfmin";
    "rv_f_zfa";
    "rv_d_zfa";
    "rv32_d_zfa";
    "rv_q_zfa";
    "rv64_q_zfa";
    "rv_zfh_zfa";
  ]

let fp_file extension = List.mem extension fp_files

(* Register class of a register field. Integer and fcsr-access forms use
   GPRs throughout; in the floating-point files every register field is an
   FPR except the integer side of a move/convert/classify/compare. *)
let register_class ~extension ~mnemonic field =
  if (not (fp_file extension)) || List.mem mnemonic fcsr_pseudos then `Gpr
  else
    let gpr_rd =
      List.exists
        (fun p -> starts_with ~prefix:p mnemonic)
        [
          "fmv.x.";
          "fmvh.x.";
          "fclass.";
          "feq.";
          "flt.";
          "fle.";
          "fleq.";
          "fltq.";
          "fcvt.w.";
          "fcvt.wu.";
          "fcvt.l.";
          "fcvt.lu.";
          "fcvtmod.w.";
        ]
    in
    let gpr_rs1 =
      (starts_with ~prefix:"fmv." mnemonic || starts_with ~prefix:"fcvt." mnemonic)
      && List.exists (fun suffix -> ends_with ~suffix mnemonic) [ ".x"; ".w"; ".wu"; ".l"; ".lu" ]
      || starts_with ~prefix:"fmvp." mnemonic
    in
    let gpr_rs2 = starts_with ~prefix:"fmvp." mnemonic in
    match field with
    | "rd" when gpr_rd -> `Gpr
    | "rs1" when gpr_rs1 -> `Gpr
    | "rs2" when gpr_rs2 -> `Gpr
    | _ -> `Fpr

(* The rounding mode GNU as encodes when the spelling omits it: dynamic (7),
   except for a conversion that is always exact - to a wider floating-point
   format, or from a 32-bit integer to d/q or any integer to q - which uses
   round-to-nearest-even (0). *)
let default_rm mnemonic =
  let rank = function
    | "h" | "bf16" -> Some 1
    | "s" -> Some 2
    | "d" -> Some 3
    | "q" -> Some 4
    | _ -> None
  in
  match String.split_on_char '.' mnemonic with
  | [ "fcvt"; dst; src ] -> (
      match (rank dst, rank src, src) with
      | Some d, Some s, _ when d > s -> 0
      | Some d, None, ("w" | "wu") when d >= 3 -> 0
      | Some 4, None, ("l" | "lu") -> 0
      | _ -> 7)
  | _ -> 7

let field_of (fields : R.field list) name =
  List.find_opt (fun (f : R.field) -> f.field_name = name) fields

let operands_of ~extension ~mnemonic (fields : R.field list) variable_fields =
  let reg name (f : R.field) =
    match register_class ~extension ~mnemonic name with
    | `Gpr -> Gpr { field = name; lsb = f.lsb; nonzero = false }
    | `Fpr -> Fpr { field = name; lsb = f.lsb }
  in
  let one name =
    match field_of fields name with
    | None -> None
    | Some f -> (
        match name with
        (* Zfa's fli.*: rs1 holds the constant's index, spelled as the constant *)
        | "rs1" when starts_with ~prefix:"fli." mnemonic -> Some (Fli { lsb = f.lsb })
        | "rd" | "rs1" | "rs2" | "rs3" -> Some (reg name f)
        | "rd_n0" -> Some (Gpr { field = name; lsb = f.lsb; nonzero = true })
        | "rs2=rs1" -> Some (Tied { lsb = f.lsb })
        | "rm" -> Some (Rm { lsb = f.lsb; default = default_rm mnemonic })
        | "shamtd" | "shamtw" | "zimm5" | "imm20" ->
            Some (Uimm { field = name; lsb = f.lsb; width = f.width })
        | _ -> None)
  in
  let all l = if List.mem None l then None else Some (List.filter_map Fun.id l) in
  let lsb name = Option.map (fun (f : R.field) -> f.lsb) (field_of fields name) in
  let gpr name = Option.map (fun l -> Gpr { field = name; lsb = l; nonzero = false }) (lsb name) in
  let with_base base ops =
    match lsb base with Some b -> all (ops @ [ Some (Mem_zero { base = b }) ]) | None -> None
  in
  let prefixed p = starts_with ~prefix:p mnemonic in
  match variable_fields with
  | [ "rd"; "rs1"; "rs2"; "aq"; "rl" ] ->
      (* an AMO: [rd, rs2, (rs1)], with the ordering as a mnemonic suffix;
         Zacas's double-width forms take even/odd register pairs *)
      let reg name =
        match (mnemonic, lsb name) with
        | "amocas.d", Some l -> Some (Gpr_pair { field = name; lsb = l; below = 64 })
        | "amocas.q", Some l -> Some (Gpr_pair { field = name; lsb = l; below = 128 })
        | _ -> gpr name
      in
      with_base "rs1" [ reg "rd"; reg "rs2" ]
  | [ "rd"; "rs1" ] when prefixed "hlv" -> with_base "rs1" [ gpr "rd" ]
  | [ "rs1"; "rs2" ] when prefixed "hsv" -> with_base "rs1" [ gpr "rs2" ]
  | [ "rs1" ] when prefixed "cbo." -> with_base "rs1" []
  | [ "rs1"; "imm12hi" ] when prefixed "prefetch." ->
      Option.map (fun b -> [ Mem_hi { base = b } ]) (lsb "rs1")
  | [ "imm12"; "rs1"; "rd" ] when mnemonic = "fence.i" -> Some []
  | [ "fm"; "pred"; "succ"; "rs1"; "rd" ] when mnemonic = "fence" -> (
      match (lsb "pred", lsb "succ") with
      | Some p, Some q ->
          Some [ Fence_set { field = "pred"; lsb = p }; Fence_set { field = "succ"; lsb = q } ]
      | _ -> None)
  | [ "rd"; "rs1"; "imm12" ] when fp_file extension -> (
      (* an FP load: [rd, imm12(rs1)] *)
      match (field_of fields "rd", field_of fields "rs1") with
      | Some rd, Some rs1 -> Some [ reg "rd" rd; Mem_i { base = rs1.lsb } ]
      | _ -> None)
  | [ "imm12hi"; "rs1"; "rs2"; "imm12lo" ] when fp_file extension -> (
      (* an FP store: [rs2, imm12(rs1)] *)
      match (field_of fields "rs2", field_of fields "rs1") with
      | Some rs2, Some rs1 -> Some [ reg "rs2" rs2; Mem_s { base = rs1.lsb } ]
      | _ -> None)
  | names -> all (List.map one names)

let spec_of_record (rec_ : R.t) =
  match (rec_.encoding, rec_.provenance) with
  | ( R.Fixed_bits { width_bits = 32; mask; value; fields },
      R.Riscv_provenance { extension = Some extension; variable_fields; _ } ) -> (
      match List.find_opt (fun (e, _, _, _) -> e = extension) allowlist with
      | None -> None
      | Some (_, names, feature, isa) -> (
          let admitted = match names with None -> true | Some l -> List.mem rec_.native_name l in
          if not admitted then None
          else
            let mnemonic, fixed = split_fixed_register rec_.native_name in
            match operands_of ~extension ~mnemonic fields variable_fields with
            | None -> None
            | Some operands ->
                let operands =
                  operands
                  @ (match fixed with Some n -> [ Fixed_gpr n ] | None -> [])
                  @
                  match List.assoc_opt rec_.native_name keywords with
                  | Some k -> [ Keyword k ]
                  | None -> []
                in
                let xlen =
                  if starts_with ~prefix:"rv64_" extension then 64
                  else if starts_with ~prefix:"rv32_" extension then 32
                  else 0
                in
                Some
                  {
                    record_id = rec_.record_id;
                    native_name = rec_.native_name;
                    mnemonic;
                    extension;
                    width_bits = 32;
                    mask;
                    match_ = value;
                    operands;
                    xlen;
                    feature =
                      (match List.assoc_opt rec_.native_name isa_overrides with
                      | Some (f, _) -> f
                      | None -> feature);
                    isa =
                      (match List.assoc_opt rec_.native_name isa_overrides with
                      | Some (_, i) -> i
                      | None -> isa);
                    ordering = List.mem "aq" variable_fields && List.mem "rl" variable_fields;
                  }))
  | _ -> None

let imm_kind ~width ~signed runs =
  Immediate { width_bits = width; signed; implicit_low_zero_bits = 0; nonzero = false; runs }

let form ~requirement (rec_ : R.t) spec =
  let reg_op ~class_ ~excluded field =
    {
      op_name = field;
      op_kind = Register { class_; excluded };
      role = (if field = "rd" || field = "rd_n0" then Out else In);
      explicit = true;
    }
  in
  let mem_ops runs =
    [
      reg_op ~class_:Riscv_gpr ~excluded:[] "base";
      {
        op_name = "offset";
        op_kind = imm_kind ~width:12 ~signed:true runs;
        role = In;
        explicit = true;
      };
    ]
  in
  let operand = function
    | Gpr { field; nonzero; _ } ->
        [ reg_op ~class_:Riscv_gpr ~excluded:(if nonzero then [ "x0" ] else []) field ]
    | Fpr { field; _ } -> [ reg_op ~class_:Riscv_fpr ~excluded:[] field ]
    | Uimm { field; width; _ } ->
        [
          {
            op_name = field;
            op_kind =
              imm_kind ~width ~signed:false
                [
                  {
                    field_name = field;
                    field_hi = width - 1;
                    field_lo = 0;
                    dest_hi = width - 1;
                    dest_lo = 0;
                  };
                ];
            role = In;
            explicit = true;
          };
        ]
    | Rm _ -> [ { op_name = "rm"; op_kind = Rounding_mode; role = In; explicit = false } ]
    | Mem_i _ ->
        mem_ops [ { field_name = "imm12"; field_hi = 11; field_lo = 0; dest_hi = 11; dest_lo = 0 } ]
    | Mem_s _ ->
        mem_ops
          [
            { field_name = "imm12hi"; field_hi = 6; field_lo = 0; dest_hi = 11; dest_lo = 5 };
            { field_name = "imm12lo"; field_hi = 4; field_lo = 0; dest_hi = 4; dest_lo = 0 };
          ]
    | Fli _ ->
        [
          {
            op_name = "constant";
            op_kind =
              imm_kind ~width:5 ~signed:false
                [ { field_name = "rs1"; field_hi = 4; field_lo = 0; dest_hi = 4; dest_lo = 0 } ];
            role = In;
            explicit = true;
          };
        ]
    | Gpr_pair { field; _ } -> [ reg_op ~class_:Riscv_gpr ~excluded:[] field ]
    | Mem_zero _ -> [ reg_op ~class_:Riscv_gpr ~excluded:[] "base" ]
    | Mem_hi _ ->
        [
          reg_op ~class_:Riscv_gpr ~excluded:[] "base";
          {
            op_name = "offset";
            op_kind =
              Immediate
                {
                  width_bits = 12;
                  signed = true;
                  implicit_low_zero_bits = 5;
                  nonzero = false;
                  runs =
                    [
                      {
                        field_name = "imm12hi";
                        field_hi = 6;
                        field_lo = 0;
                        dest_hi = 11;
                        dest_lo = 5;
                      };
                    ];
                };
            role = In;
            explicit = true;
          };
        ]
    | Fence_set { field; _ } ->
        [
          {
            op_name = field;
            op_kind =
              imm_kind ~width:4 ~signed:false
                [ { field_name = field; field_hi = 3; field_lo = 0; dest_hi = 3; dest_lo = 0 } ];
            role = In;
            explicit = true;
          };
        ]
    | Fixed_gpr _ | Tied _ | Keyword _ -> []
  in
  let syntax_token = function
    | Gpr { field; _ } | Fpr { field; _ } | Uimm { field; _ } -> Some (Syn_operand field)
    | Fli _ -> Some (Syn_operand "constant")
    | Gpr_pair { field; _ } | Fence_set { field; _ } -> Some (Syn_operand field)
    | Mem_zero _ -> Some (Syn_group [ Syn_literal "("; Syn_operand "base"; Syn_literal ")" ])
    | Mem_hi _ ->
        Some
          (Syn_group [ Syn_operand "offset"; Syn_literal "("; Syn_operand "base"; Syn_literal ")" ])
    | Fixed_gpr n -> Some (Syn_literal (Printf.sprintf "x%d" n))
    | Keyword k -> Some (Syn_literal k)
    | Mem_i _ | Mem_s _ ->
        Some
          (Syn_group [ Syn_operand "offset"; Syn_literal "("; Syn_operand "base"; Syn_literal ")" ])
    | Rm _ | Tied _ -> None
  in
  let rm_fact =
    List.find_map
      (function
        | Rm { default; _ } ->
            Some
              {
                label = Inferred;
                note =
                  Printf.sprintf
                    "the rounding-mode operand is omitted, so GNU as encodes its default (%d)"
                    default;
              }
        | _ -> None)
      spec.operands
  in
  {
    form_id = "riscv:" ^ spec.native_name;
    arch = Riscv;
    native_name = rec_.native_name;
    source_record_ids = [ rec_.record_id ];
    requirement;
    encoding =
      Riscv_encoding { width_bits = spec.width_bits; mask = spec.mask; value = spec.match_ };
    operands = List.concat_map operand spec.operands;
    syntax =
      {
        dialect = "gas-att";
        mnemonic = spec.mnemonic;
        operands = List.filter_map syntax_token spec.operands;
      };
    concreteness = (if rec_.kind = "pseudo-op" then Alias_of spec.mnemonic else Concrete);
    facts =
      [
        {
          label = Upstream;
          note = "mask, match and field positions taken verbatim from the fixed_bits record";
        };
        {
          label = Inferred;
          note =
            Printf.sprintf
              "field domains and GNU syntax order from the DEC-RV-TABLE rule; enabled by -march \
               extension %s"
              spec.feature;
        };
      ]
      @ Option.to_list rm_fact;
    diagnostics = [];
  }

let march target spec =
  let xlen, abi = match target with Target.Riscv32 -> ("rv32", "ilp32") | _ -> ("rv64", "lp64") in
  [ "-march=" ^ xlen ^ spec.isa; "-mabi=" ^ abi; "-mno-relax" ]

let rows_path repo =
  Fpath.(Repo.path repo / "asm" / "targets" / "riscv_family" / "riscv_table_rows.ml")

let ( let* ) = Result.bind

let render_operand = function
  | Gpr { lsb; nonzero; _ } -> Printf.sprintf "Gpr { lsb = %d; nonzero = %b }" lsb nonzero
  | Fpr { lsb; _ } -> Printf.sprintf "Fpr { lsb = %d }" lsb
  | Uimm { lsb; width; _ } -> Printf.sprintf "Uimm { lsb = %d; width = %d }" lsb width
  | Fixed_gpr n -> Printf.sprintf "Fixed_gpr %d" n
  | Rm { lsb; default } -> Printf.sprintf "Rm { lsb = %d; default = %d }" lsb default
  | Tied { lsb } -> Printf.sprintf "Tied { lsb = %d }" lsb
  | Mem_i { base } -> Printf.sprintf "Mem_i { base = %d }" base
  | Mem_s { base } -> Printf.sprintf "Mem_s { base = %d }" base
  | Keyword k -> Printf.sprintf "Keyword %S" k
  | Fli { lsb } -> Printf.sprintf "Fli { lsb = %d }" lsb
  | Mem_zero { base } -> Printf.sprintf "Mem_zero { base = %d }" base
  | Mem_hi { base } -> Printf.sprintf "Mem_hi { base = %d }" base
  | Gpr_pair { lsb; below; _ } -> Printf.sprintf "Gpr_pair { lsb = %d; below = %d }" lsb below
  | Fence_set _ -> invalid_arg "Isa_riscv_table: fence rows are hand-encoded, never emitted"

let render_row (spec, xlen) =
  Printf.sprintf
    "    {\n\
    \      mnemonic = %S;\n\
    \      mask = %sL;\n\
    \      match_ = %sL;\n\
    \      operands = [ %s ];\n\
    \      xlen = %d;\n\
    \      feature = %S;\n\
    \      source = %S;\n\
    \    };\n"
    spec.mnemonic spec.mask spec.match_
    (String.concat "; " (List.map render_operand spec.operands))
    xlen spec.feature
    (spec.extension ^ "/" ^ spec.native_name)

let emit repo =
  let specs target =
    let* records =
      Isa_source_record.read_file (Repo.isa_db_export repo ~source:"riscv_opcodes" target)
    in
    Ok (List.filter_map spec_of_record records)
  in
  let* rv32 = specs Target.Riscv32 in
  let* rv64 = specs Target.Riscv64 in
  let same a b = a.record_id = b.record_id && a.mask = b.mask && a.match_ = b.match_ in
  let rows =
    List.map (fun s -> (s, if List.exists (same s) rv32 then 0 else 64)) rv64
    @ List.filter_map (fun s -> if List.exists (same s) rv64 then None else Some (s, 32)) rv32
    |> List.filter (fun (s, _) -> emits_row s)
    (* an AMO's aq/rl bits are spelled as a mnemonic suffix: one row each *)
    |> List.concat_map (fun (s, x) ->
        if not s.ordering then [ (s, x) ]
        else
          let bits = 0x6000000L in
          let hex v = Printf.sprintf "0x%Lx" v in
          List.map
            (fun (suffix, set) ->
              ( {
                  s with
                  mnemonic = s.mnemonic ^ suffix;
                  mask = hex (Int64.logor (Int64.of_string s.mask) bits);
                  match_ = hex (Int64.logor (Int64.of_string s.match_) set);
                },
                x ))
            [ ("", 0L); (".aq", 0x4000000L); (".rl", 0x2000000L); (".aqrl", bits) ])
    (* one row per distinct encoding: an import repeats its record in
       another extension file *)
    |> List.fold_left
         (fun acc (s, x) ->
           if
             List.exists
               (fun (t, y) ->
                 t.mnemonic = s.mnemonic && t.mask = s.mask && t.match_ = s.match_ && x = y)
               acc
           then acc
           else (s, x) :: acc)
         []
    |> List.rev
    (* Decode tries rows in order: a row whose mask fixes more bits comes
       first ([zext.w] is [add.uw] with rs2 = x0), and among equal masks a
       row with a tied register ([fmv.h] is [fsgnj.h] with rs2 = rs1). *)
    |> List.stable_sort (fun (a, _) (b, _) ->
        let tied s = List.exists (function Tied _ -> true | _ -> false) s.operands in
        compare (popcount_hex b.mask, tied b) (popcount_hex a.mask, tied a))
  in
  Ok
    (String.concat ""
       ([
          "(* Generated by [compcert_tools isa-table riscv-emit] from the committed riscv-opcodes\n\
          \   exports (isa-db/export/riscv_opcodes); do not edit by hand. The selection and field\n\
          \   domains are Isa_riscv_table's DEC-RV-TABLE rule. *)\n\n\
           open Riscv_table_row\n\n\
           let rows : row array =\n\
          \  [|\n";
        ]
       @ List.map render_row rows @ [ "  |]\n" ]))

let fatal op detail =
  Command.of_error (Err.Error.make ~pos:__POS__ ~pp_error:Tool_error.pp (Tool_error.v op detail))

let run_emit repo =
  match
    let* text = emit repo in
    Tool_fs.write (rows_path repo) text
  with
  | Ok () ->
      Command.ok [ Diagnostic.stdout ("isa-table: wrote " ^ Fpath.to_string (rows_path repo)) ]
  | Error e -> Command.of_error e

let run_check repo =
  match
    let* text = emit repo in
    let* committed = Tool_fs.read (rows_path repo) in
    Ok (String.equal text committed)
  with
  | Ok true -> Command.ok [ Diagnostic.stdout "isa-table: riscv_table_rows.ml is current" ]
  | Ok false ->
      fatal Tool_error.Validate
        "isa-table: riscv_table_rows.ml differs from a fresh emission - run isa-table riscv-emit"
  | Error e -> Command.of_error e
