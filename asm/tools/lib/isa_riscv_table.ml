module R = Isa_source_record
open Isa_norm_model

type operand =
  | Gpr of { field : string; lsb : int; nonzero : bool }
  | Fpr of { field : string; lsb : int }
  | Uimm of { field : string; lsb : int; width : int }
  | Fixed_gpr of int

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
}

(* The families admitted through the table, and the -march extension that
   enables each (probed against GNU as 2.44 / 2.43.1). [None] admits every
   table-expressible record of the file; a list admits only those native
   names, because the rest of that file is owned by the hand-written
   encoder. *)
let allowlist =
  [
    ("rv_zimop", None, "zimop");
    ("rv_zicfiss", None, "zicfiss");
    ("rv64_zba", Some [ "add.uw"; "slli.uw"; "zext.w" ], "zba");
    ( "rv_f",
      Some [ "frcsr"; "frflags"; "frrm"; "fscsr"; "fsflags"; "fsflagsi"; "fsrm"; "fsrmi" ],
      "f" );
    ("rv64_d", Some [ "fmv.x.d"; "fmv.d.x" ], "d");
  ]

(* Admitted by the table rule (normalized forms and cases) but already
   encoded by the hand-written RISC-V encoder, so no row is emitted: a row
   would be shadowed by the hand-written mnemonic. *)
let hand_encoded = [ "fmv.x.d" ]
let emits_row spec = not (List.mem spec.native_name hand_encoded)

(* Decode tries rows in order, so a row whose mask fixes more bits comes
   first: [zext.w] is [add.uw] with rs2 = x0 and must win for that word. *)
let popcount_hex h =
  let v = Int64.of_string h in
  let rec go v n =
    if v = 0L then n else go (Int64.shift_right_logical v 1) (n + Int64.to_int (Int64.logand v 1L))
  in
  go v 0

let starts_with ~prefix s =
  String.length s >= String.length prefix && String.sub s 0 (String.length prefix) = prefix

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

(* Register class of a register field. Integer and fcsr-access forms use
   GPRs throughout; in the floating-point files every register field is an
   FPR except the integer side of a move/convert/classify/compare. *)
let register_class ~extension ~mnemonic field =
  let fp_file =
    List.exists
      (fun p -> starts_with ~prefix:p extension)
      [ "rv_f"; "rv_d"; "rv_q"; "rv_zfh"; "rv32_f"; "rv64_f"; "rv64_d"; "rv64_q"; "rv64_zfh" ]
  in
  if (not fp_file) || List.mem mnemonic fcsr_pseudos then `Gpr
  else
    let gpr_rd =
      List.exists
        (fun p -> starts_with ~prefix:p mnemonic)
        [
          "fmv.x.";
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
        ]
    in
    let gpr_rs1 =
      String.length mnemonic > 2
      && List.exists
           (fun s ->
             let n = String.length mnemonic and k = String.length s in
             n >= k && String.sub mnemonic (n - k) k = s)
           [ ".x"; ".w"; ".wu"; ".l"; ".lu" ]
      && (starts_with ~prefix:"fmv." mnemonic || starts_with ~prefix:"fcvt." mnemonic)
    in
    match field with "rd" when gpr_rd -> `Gpr | "rs1" when gpr_rs1 -> `Gpr | _ -> `Fpr

let operand_of ~extension ~mnemonic (fields : R.field list) name =
  match List.find_opt (fun (f : R.field) -> f.field_name = name) fields with
  | None -> None
  | Some f -> (
      match name with
      | "rd" | "rs1" | "rs2" | "rs3" -> (
          match register_class ~extension ~mnemonic name with
          | `Gpr -> Some (Gpr { field = name; lsb = f.lsb; nonzero = false })
          | `Fpr -> Some (Fpr { field = name; lsb = f.lsb }))
      | "rd_n0" -> Some (Gpr { field = name; lsb = f.lsb; nonzero = true })
      | "shamtd" | "shamtw" | "zimm5" -> Some (Uimm { field = name; lsb = f.lsb; width = f.width })
      | _ -> None)

let spec_of_record (rec_ : R.t) =
  match (rec_.encoding, rec_.provenance) with
  | ( R.Fixed_bits { width_bits = 32; mask; value; fields },
      R.Riscv_provenance { extension = Some extension; variable_fields; _ } ) -> (
      match List.find_opt (fun (e, _, _) -> e = extension) allowlist with
      | None -> None
      | Some (_, names, base_feature) ->
          let admitted = match names with None -> true | Some l -> List.mem rec_.native_name l in
          if not admitted then None
          else
            let mnemonic, fixed = split_fixed_register rec_.native_name in
            let operands = List.map (operand_of ~extension ~mnemonic fields) variable_fields in
            if List.mem None operands then None
            else
              let operands =
                List.filter_map Fun.id operands
                @ match fixed with Some n -> [ Fixed_gpr n ] | None -> []
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
                  feature = base_feature;
                })
  | _ -> None

let form ~requirement (rec_ : R.t) spec =
  let operand = function
    | Gpr { field; nonzero; _ } ->
        Some
          {
            op_name = field;
            op_kind = Register { class_ = Riscv_gpr; excluded = (if nonzero then [ "x0" ] else []) };
            role = (if field = "rd" || field = "rd_n0" then Out else In);
            explicit = true;
          }
    | Fpr { field; _ } ->
        Some
          {
            op_name = field;
            op_kind = Register { class_ = Riscv_fpr; excluded = [] };
            role = (if field = "rd" then Out else In);
            explicit = true;
          }
    | Uimm { field; width; _ } ->
        Some
          {
            op_name = field;
            op_kind =
              Immediate
                {
                  width_bits = width;
                  signed = false;
                  implicit_low_zero_bits = 0;
                  nonzero = false;
                  runs =
                    [
                      {
                        field_name = field;
                        field_hi = width - 1;
                        field_lo = 0;
                        dest_hi = width - 1;
                        dest_lo = 0;
                      };
                    ];
                };
            role = In;
            explicit = true;
          }
    | Fixed_gpr _ -> None
  in
  let syntax_token = function
    | Gpr { field; _ } | Fpr { field; _ } | Uimm { field; _ } -> Syn_operand field
    | Fixed_gpr n -> Syn_literal (Printf.sprintf "x%d" n)
  in
  {
    form_id = "riscv:" ^ spec.native_name;
    arch = Riscv;
    native_name = rec_.native_name;
    source_record_ids = [ rec_.record_id ];
    requirement;
    encoding =
      Riscv_encoding { width_bits = spec.width_bits; mask = spec.mask; value = spec.match_ };
    operands = List.filter_map operand spec.operands;
    syntax =
      {
        dialect = "gas-att";
        mnemonic = spec.mnemonic;
        operands = List.map syntax_token spec.operands;
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
      ];
    diagnostics = [];
  }

let march target spec =
  let xlen, abi = match target with Target.Riscv32 -> ("rv32", "ilp32") | _ -> ("rv64", "lp64") in
  let isa =
    match spec.feature with
    | "f" -> "imf"
    | "d" -> "imfd"
    | "zicfiss" -> "im_zimop_zicfiss"
    | multi -> "im_" ^ multi
  in
  [ "-march=" ^ xlen ^ isa; "-mabi=" ^ abi; "-mno-relax" ]

let rows_path repo =
  Fpath.(Repo.path repo / "asm" / "targets" / "riscv_family" / "riscv_table_rows.ml")

let ( let* ) = Result.bind

let render_operand = function
  | Gpr { lsb; nonzero; _ } -> Printf.sprintf "Gpr { lsb = %d; nonzero = %b }" lsb nonzero
  | Fpr { lsb; _ } -> Printf.sprintf "Fpr { lsb = %d }" lsb
  | Uimm { lsb; width; _ } -> Printf.sprintf "Uimm { lsb = %d; width = %d }" lsb width
  | Fixed_gpr n -> Printf.sprintf "Fixed_gpr %d" n

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
    |> List.stable_sort (fun (a, _) (b, _) -> compare (popcount_hex b.mask) (popcount_hex a.mask))
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
