type source = { upstream : string; name : string }
type form = { label : string; mnemonics : string list; sources : source list }
type t = { id : string; feature : string; summary : string; forms : form list }

let labels c = List.map (fun f -> f.label) c.forms
let mnemonics c = List.concat_map (fun f -> f.mnemonics) c.forms
let owns_mnemonic c m = List.exists (String.equal m) (mnemonics c)

let duplicates xs =
  let sorted = List.sort String.compare xs in
  let rec go acc = function
    | a :: (b :: _ as rest) -> go (if String.equal a b then a :: acc else acc) rest
    | _ -> acc
  in
  List.sort_uniq String.compare (go [] sorted)

let check components =
  let per_component c =
    (if c.forms = [] then [ Printf.sprintf "%s: no forms" c.id ] else [])
    @ List.concat_map
        (fun f ->
          (if f.mnemonics = [] then [ Printf.sprintf "%s: form %s has no mnemonic" c.id f.label ]
           else [])
          @
          if f.sources = [] then [ Printf.sprintf "%s: form %s has no source mapping" c.id f.label ]
          else [])
        c.forms
  in
  let dup what xs = List.map (fun d -> Printf.sprintf "duplicate %s %s" what d) (duplicates xs) in
  List.concat_map per_component components
  @ dup "component id" (List.map (fun c -> c.id) components)
  @ dup "form label" (List.concat_map labels components)
  @ dup "mnemonic" (List.concat_map mnemonics components)
