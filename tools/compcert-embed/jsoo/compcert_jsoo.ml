(* js_of_ocaml binding of Compcert_js.

   Exports one object, CompCert, with
     compile(source, options) -> { ok: true, asm, diagnostics }
                               | { ok: false, kind, message }
     version, target
   options: { name, opt: "O0"|"O1"|"O2"|"Os", structPassing, pie, debug, extra }.
   [kind] is "diagnostics", "too_deep", "unsupported", "internal" or "options".
   compile never throws. *)

open Js_of_ocaml

let str = Js.string
let get o k = Js.Unsafe.get o (str k)
let has o k = Js.Optdef.test (get o k)

(* jsoo reports an exhausted JavaScript stack as Stack_overflow when it can
   detect it, and as a Failure carrying V8's or Firefox's message when its own
   detection overflows. *)
let jsoo_overflow = function
  | Stack_overflow -> true
  | Failure m ->
      let has_sub s =
        let n = String.length s and l = String.length m in
        let rec go i = i + n <= l && (String.sub m i n = s || go (i + 1)) in
        go 0
      in
      has_sub "Maximum call stack size exceeded" || has_sub "maximum call stack"
      || has_sub "too much recursion"
  | _ -> false

let () = Compcert_js.overflow_hooks := [ jsoo_overflow ]

let opt_of_string = function
  | "O0" -> Some Compcert_js.O0
  | "O1" -> Some Compcert_js.O1
  | "O2" -> Some Compcert_js.O2
  | "Os" -> Some Compcert_js.Os
  | _ -> None

let options_of_js o =
  let d = Compcert_js.default_options in
  if not (Js.Optdef.test (Obj.magic o : _ Js.optdef)) then Ok d
  else
    let string_field k default = if has o k then Js.to_string (get o k) else default in
    let bool_field k default = if has o k then Js.to_bool (get o k) else default in
    match opt_of_string (string_field "opt" "O2") with
    | None -> Error "opt must be one of O0, O1, O2, Os"
    | Some opt_level ->
        let extra =
          if has o "extra" then Array.to_list (Js.to_array (get o "extra")) |> List.map Js.to_string
          else []
        in
        Ok
          {
            Compcert_js.name = string_field "name" d.name;
            opt_level;
            struct_passing = bool_field "structPassing" d.struct_passing;
            pie = bool_field "pie" d.pie;
            debug = bool_field "debug" d.debug;
            extra;
          }

let failure kind message =
  Js.Unsafe.obj
    [| ("ok", Js.Unsafe.inject Js._false); ("kind", Js.Unsafe.inject (str kind));
       ("message", Js.Unsafe.inject (str message)) |]

let compile source options =
  match options_of_js options with
  | Error m -> failure "options" m
  | Ok o -> (
      let out = Compcert_js.compile_ex o (Js.to_string source) in
      match out.result with
      | Ok asm ->
          Js.Unsafe.obj
            [| ("ok", Js.Unsafe.inject Js._true); ("asm", Js.Unsafe.inject (str asm));
               ("diagnostics", Js.Unsafe.inject (str out.diagnostics)) |]
      | Error (Diagnostics m) -> failure "diagnostics" m
      | Error (Too_deep m) -> failure "too_deep" m
      | Error (Unsupported m) -> failure "unsupported" m
      | Error (Internal m) -> failure "internal" m)

let () =
  Js.export "CompCert"
    (Js.Unsafe.obj
       [| ("compile", Js.Unsafe.inject (Js.wrap_callback compile));
          ("version", Js.Unsafe.inject (str Compcert_js.version));
          ("target", Js.Unsafe.inject (str Compcert_js.target)) |])
