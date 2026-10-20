(* Injected into the embed variant of CompCert (see ../compcert-embed-target.sh).

   The DWARF compile unit names the directory the compiler was run in
   ([DW_AT_comp_dir]), which ccomp reads from the process. An embedded
   compiler has no meaningful working directory and must not give a different
   answer from one host to another, so [Dwarfgen] opens this module and gets the
   directory the embedding sets, "/" by default. *)

let dir = ref "/"

module Sys = struct
  include Stdlib.Sys

  let getcwd () = !dir
end
