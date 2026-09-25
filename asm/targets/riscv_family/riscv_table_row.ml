(* One table-driven fixed-format RISC-V form (DEC-RV-TABLE). The rows
   themselves are generated from the captured riscv-opcodes export into
   Riscv_table_rows by [compcert_tools isa-table riscv-emit]; nothing here
   reads the capture at run time. *)

type operand =
  | Gpr of { lsb : int; nonzero : bool }  (** a 5-bit integer register field *)
  | Fpr of { lsb : int }  (** a 5-bit floating-point register field *)
  | Uimm of { lsb : int; width : int }  (** a contiguous unsigned immediate field *)
  | Simm of { lsb : int; width : int }  (** a contiguous two's-complement immediate field *)
  | Fixed_gpr of int
      (** a register the spelling names but the encoding fixes, e.g. [sspopchk x1] *)
  | Rm of { lsb : int; default : int }
      (** a 3-bit rounding mode; the GNU spelling may omit it (always last), and
          then [default] is encoded *)
  | Tied of { lsb : int }
      (** a register field that repeats the previous operand's register, e.g.
          [fmv.h rd, rs] is [fsgnj.h rd, rs, rs]; not spelled *)
  | Mem_i of { base : int }  (** [imm12(base)] with the signed offset in bits 31:20 *)
  | Keyword of string
      (** a word the spelling requires but the encoding fixes, e.g. the [rtz] of
          [fcvtmod.w.d rd, rs, rtz] *)
  | Fli of { lsb : int }
      (** Zfa's [fli.*] constant, spelled by name or value, encoded as its
          5-bit index into {!fli_constants} *)
  | Mem_s of { base : int }
      (** [imm12(base)] with the signed offset split into bits 31:25 and 11:7 *)

type row = {
  mnemonic : string;
  mask : int64;
  match_ : int64;
  operands : operand list;  (** in GNU assembler syntax order *)
  xlen : int;  (** 0 when the form exists on both RV32 and RV64 *)
  feature : string;  (** the GNU [-march] extension that enables it *)
  source : string;  (** the riscv-opcodes record, [<extension>/<native name>] *)
}

(* Zfa's [fli] constant table, index order (RISC-V Zfa specification); the
   spelling printed for each. Index 1 is the format's smallest normal number,
   which has no format-independent value, so it is only ever spelled [min]. *)
let fli_constants =
  [|
    "-1.0";
    "min";
    "1.52587890625e-05";
    "3.0517578125e-05";
    "0.00390625";
    "0.0078125";
    "0.0625";
    "0.125";
    "0.25";
    "0.3125";
    "0.375";
    "0.4375";
    "0.5";
    "0.625";
    "0.75";
    "0.875";
    "1.0";
    "1.25";
    "1.5";
    "1.75";
    "2.0";
    "2.5";
    "3.0";
    "4.0";
    "8.0";
    "16.0";
    "128.0";
    "256.0";
    "32768.0";
    "65536.0";
    "inf";
    "nan";
  |]

let fli_index text =
  let named = function "min" -> Some 1 | "inf" -> Some 30 | "nan" -> Some 31 | _ -> None in
  match named text with
  | Some _ as i -> i
  | None -> (
      match float_of_string_opt text with
      | None -> None
      | Some v ->
          let rec go i =
            if i >= Array.length fli_constants then None
            else if i <> 1 && i < 30 && float_of_string fli_constants.(i) = v then Some i
            else go (i + 1)
          in
          go 0)
