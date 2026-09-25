(** The table-driven RISC-V forms (DEC-RV-TABLE): which captured
    riscv-opcodes records become rows of the assembler's generated
    [asm/targets/riscv_family/riscv_table_rows.ml], and the reviewed rule that
    gives each of their fields an operand domain.

    One rule serves three consumers, so they cannot disagree: the emitter
    that writes the checked-in rows, the normalizer ({!Isa_norm_riscv}) that
    turns the same records into {!Isa_norm_model.form}s, and the case
    generator ({!Isa_gen_difficult.table_entries}). A record is a row only
    when its extension (and, where listed, its native name) is on the
    allowlist and every variable field is a contiguous field with a known
    domain; everything else stays with the hand-written encoder or blocked. *)

type operand =
  | Gpr of { field : string; lsb : int; nonzero : bool }
  | Fpr of { field : string; lsb : int }
  | Uimm of { field : string; lsb : int; width : int }
  | Fixed_gpr of int  (** spelled in the source but fixed by the encoding, e.g. [sspopchk x1] *)

type spec = {
  record_id : string;
  native_name : string;
  mnemonic : string;  (** the GNU spelling: the native name without a [.xN] register suffix *)
  extension : string;
  width_bits : int;
  mask : string;
  match_ : string;
  operands : operand list;  (** GNU syntax order *)
  xlen : int;  (** 0 unless the extension file is [rv32_*]/[rv64_*] *)
  feature : string;  (** the [-march] extension, e.g. ["zimop"], ["zba"], ["f"] *)
}

val spec_of_record : Isa_source_record.t -> spec option
(** [Some] exactly for allowlisted, table-expressible records. *)

val form :
  requirement:Isa_norm_model.requirement -> Isa_source_record.t -> spec -> Isa_norm_model.form
(** The normalized form of a table record: operands named after their
    fields, GNU syntax in field order, the fixed register as a literal. *)

val march : Target.t -> spec -> string list
(** The GAS configuration a case of this row needs, e.g.
    [["-march=rv64im_zimop"; "-mabi=lp64"; "-mno-relax"]]. *)

val rows_path : Repo.t -> Fpath.t
(** [asm/targets/riscv_family/riscv_table_rows.ml]. *)

val emit : Repo.t -> (string, Tool_error.t) Err.t
(** The generated OCaml source for {!rows_path}, from both committed
    riscv-opcodes exports: a record present in both profiles becomes one row
    with [xlen = 0], otherwise the row carries its profile's XLEN. *)

val run_emit : Repo.t -> Command.t
(** Write {!emit} to {!rows_path}. *)

val run_check : Repo.t -> Command.t
(** Fail unless {!rows_path} equals a fresh {!emit}. Toolchain-free. *)
