(* Section permissions, as metadata (.ai/asm_plan.md §9).

   Recorded, never applied: no production package changes memory protection.
   These travel from a section directive through the lowered module into the
   image's segments, where an embedding host may act on them. *)

type t = { read : bool; write : bool; execute : bool }

let rx = { read = true; write = false; execute = true }
let ro = { read = true; write = false; execute = false }
let rw = { read = true; write = true; execute = false }
let none = { read = false; write = false; execute = false }

let to_string t =
  (if t.read then "r" else "") ^ (if t.write then "w" else "") ^ if t.execute then "x" else ""

let pp ppf t = Fmt.string ppf (to_string t)
