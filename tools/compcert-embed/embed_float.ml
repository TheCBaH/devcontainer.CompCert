(* Injected into the embed variant of CompCert (see ../compcert-embed-target.sh).

   [Printf "%.Ng"] of a negative zero prints "0" on Melange, whose
   caml_format_float tests [x < 0.] to find the sign. The assembly printers
   write floating-point constants in comments with this conversion, so they
   call [g] instead, which prints "-0" as every other backend does. *)

let g prec (x : float) =
  if x = 0.0 && 1.0 /. x < 0.0 then "-0" else Printf.sprintf "%.*g" prec x
