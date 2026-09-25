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

type row = {
  mnemonic : string;
  mask : int64;
  match_ : int64;
  operands : operand list;  (** in GNU assembler syntax order *)
  xlen : int;  (** 0 when the form exists on both RV32 and RV64 *)
  feature : string;  (** the GNU [-march] extension that enables it *)
  source : string;  (** the riscv-opcodes record, [<extension>/<native name>] *)
}
