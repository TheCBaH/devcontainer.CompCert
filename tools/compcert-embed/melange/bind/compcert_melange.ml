(* Melange binding of Compcert_js: the same JavaScript surface as the
   js_of_ocaml bundle.

     compile(source, options) -> { ok: true, asm, diagnostics }
                               | { ok: false, kind, message }
     version, target

   options: { name, opt: "O0"|"O1"|"O2"|"Os", structPassing, pie, debug, extra }.
   compile never throws. *)

type opts
type result

external as_result : 'a Js.t -> result = "%identity"

external get : opts -> string -> 'a Js.undefined = "" [@@mel.get_index]

external make_ok :
  ok:bool -> asm:string -> diagnostics:string -> unit -> < ok : bool ; asm : string ; diagnostics : string > Js.t
  = ""
[@@mel.obj]

external make_error : ok:bool -> kind:string -> message:string -> unit -> < ok : bool ; kind : string ; message : string > Js.t
  = ""
[@@mel.obj]

(* An exhausted JavaScript stack arrives as a RangeError ("Maximum call stack
   size exceeded"), as a Stack_overflow, or, when a handler runs out of stack
   itself, as another error carrying the same words. *)
let mentions_overflow m =
  let has_sub s =
    let n = String.length s and l = String.length m in
    let rec go i = i + n <= l && (String.sub m i n = s || go (i + 1)) in
    go 0
  in
  has_sub "Maximum call stack size exceeded" || has_sub "maximum call stack" || has_sub "too much recursion"

let () =
  Compcert_js.overflow_hooks :=
    [
      (function
        | Failure m -> mentions_overflow m
        | Js.Exn.Error e -> (match Js.Exn.message e with Some m -> mentions_overflow m | None -> false)
        | _ -> false);
    ]

(* A Melange string is a JavaScript string, but CompCert works on the bytes of
   the C source, which a JavaScript string holds as UTF-16 text. The text is
   passed in as its UTF-8 bytes (one character per byte), and what comes back
   is decoded from UTF-8 again, as js_of_ocaml does at its boundary. *)
let to_bytes : string -> string =
  [%mel.raw
    {|function (s) {
  var b = new TextEncoder().encode(s), out = [], chunk = 8192;
  for (var i = 0; i < b.length; i += chunk) out.push(String.fromCharCode.apply(null, b.subarray(i, i + chunk)));
  return out.join("");
}|}]

let of_bytes : string -> string =
  [%mel.raw
    {|function (s) {
  var b = new Uint8Array(s.length);
  for (var i = 0; i < s.length; i++) b[i] = s.charCodeAt(i);
  return new TextDecoder("utf-8").decode(b);
}|}]

let field_string o k default = match Js.Undefined.toOption (get o k) with Some (v : string) -> v | None -> default
let field_bool o k default = match Js.Undefined.toOption (get o k) with Some (v : bool) -> v | None -> default

let opt_of_string = function
  | "O0" -> Some Compcert_js.O0
  | "O1" -> Some Compcert_js.O1
  | "O2" -> Some Compcert_js.O2
  | "Os" -> Some Compcert_js.Os
  | _ -> None

let options_of_js (o : opts Js.undefined) =
  let d = Compcert_js.default_options in
  match Js.Undefined.toOption o with
  | None -> Ok d
  | Some o -> (
      match opt_of_string (field_string o "opt" "O2") with
      | None -> Error "opt must be one of O0, O1, O2, Os"
      | Some opt_level ->
          let extra =
            match Js.Undefined.toOption (get o "extra") with
            | Some (a : string array) -> Array.to_list a
            | None -> []
          in
          Ok
            {
              Compcert_js.name = to_bytes (field_string o "name" d.name);
              opt_level;
              struct_passing = field_bool o "structPassing" d.struct_passing;
              pie = field_bool o "pie" d.pie;
              debug = field_bool o "debug" d.debug;
              extra;
            })

let failure kind message = make_error ~ok:false ~kind ~message:(of_bytes message) ()

let compile (source : string) (options : opts Js.undefined) : result =
  match options_of_js options with
  | Error m -> as_result (failure "options" m)
  | Ok o -> (
      let out = Compcert_js.compile_ex o (to_bytes source) in
      match out.result with
      | Ok asm -> as_result (make_ok ~ok:true ~asm:(of_bytes asm) ~diagnostics:(of_bytes out.diagnostics) ())
      | Error (Diagnostics m) -> as_result (failure "diagnostics" m)
      | Error (Too_deep m) -> as_result (failure "too_deep" m)
      | Error (Unsupported m) -> as_result (failure "unsupported" m)
      | Error (Internal m) -> as_result (failure "internal" m))

let version = Compcert_js.version
let target = Compcert_js.target
