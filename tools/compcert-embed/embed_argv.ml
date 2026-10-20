(* Injected into the embed variant of CompCert (see ../compcert-embed-target.sh).

   [PrintAsmaux.print_version_and_options] writes the host process's command
   line into the assembly header. Shadowing [Commandline] there with a fixed
   argument vector makes that line the same on every host: what `ccomp -S
   <name>` would print. The embedding stores the unit's name in the last slot
   before printing; element 0 is not printed. *)

module Commandline = struct
  let argv = [| "ccomp"; "-S"; "" |]
end
