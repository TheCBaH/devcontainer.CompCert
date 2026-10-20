(* Injected into the embed variant of CompCert (see ../compcert-embed-target.sh).

   [Diagnostics.fatal_error_raw], which reports syntax errors, prints straight
   to the standard error channel with [Printf.kfprintf] instead of going
   through [Format.err_formatter] like every other diagnostic. Shadowing both
   names sends that text to [stderr] below, a buffer the embedding drains
   after each compile. [out_channel] is shadowed for Diagnostics.mli, whose
   [fatal_error_raw] signature names the channel type. *)

type out_channel = Buffer.t

(* Diagnostics colors its messages when stderr is a terminal; the text it
   produces here goes to the caller, never to a terminal. *)
module Unix = struct
  include Unix

  let isatty (_ : file_descr) = false
end

let stderr = Buffer.create 256

module Printf = struct
  include Stdlib.Printf

  let kfprintf = kbprintf
end
