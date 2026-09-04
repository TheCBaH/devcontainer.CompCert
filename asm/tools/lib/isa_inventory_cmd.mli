(** [compcert-tools isa-inventory regen] - rebuild the whole-ISA instruction
    inventory (asm/docs/isa-inventory.md).

    Toolchain-free: it reads only the vendored submodules under
    asm/vendor/isa-data/, never invokes a compiler or cross assembler.
    Currently RISC-V only ({!Isa_inventory_riscv}) - the "RISC-V-first pilot"
    named in .ai/isa-inventory-sources.md; an x86 generator against the
    already-vendored XED submodule is follow-up work (next.md). *)

val regen : Repo.t -> Command.t
