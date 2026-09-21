(** The RISC-V M (integer multiply/divide) component.

    Only the forms the assembler implements are listed: [mul], [remu], and the RV64-only [mulw]. The
    rest of the extension is captured by the ISA database but not admitted, and stays visible as
    unimplemented rather than being described here. *)

type form = {
  mnemonic : string;
  opcode : int;  (** major opcode, bits 6..0 *)
  funct3 : int;
  funct7 : int;
  rv64_only : bool;
  source : string;  (** the riscv-opcodes record this form corresponds to *)
}

val forms : form list

val find : string -> form option
(** The form spelled [mnemonic], if this component owns it. *)

val component : Target_component.t
