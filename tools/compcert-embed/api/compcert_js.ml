(* Backend-neutral compile API over one CompCert embed variant: preprocessed C
   source text in, assembly text or CompCert's diagnostics out.

   [Embed_cc.CC] is the embed library of the package this is built in. The
   input is read from memory ([Embed_source_in]) and the assembly is printed
   into a buffer ([Embed_asm_out]); the rest is CompCert's own pipeline, driven
   as `ccomp -S` drives it.

   CompCert keeps its state in globals, so compiles must not overlap. Every
   call starts from the same state: options, diagnostics, atom tables and the
   label counter are reset first. *)

module CC = Embed_cc.CC

type opt_level = O0 | O1 | O2 | Os

type options = {
  name : string;
  opt_level : opt_level;
  struct_passing : bool;
  pie : bool;
  debug : bool;
  extra : string list;
}

let default_options =
  { name = "input.c"; opt_level = O2; struct_passing = true; pie = false; debug = false; extra = [] }

type error =
  | Diagnostics of string
  | Too_deep of string
  | Unsupported of string
  | Internal of string

type outcome = { result : (string, error) result; diagnostics : string }

let target = CC.Configuration.arch
let version = CC.Version.version

(* The flags [extra] may carry, each as the ref it sets and the value it sets
   it to. Anything else is rejected, as there is no command-line parser here:
   the option table lives in the driver. *)
let extra_flags =
  let open CC.Clflags in
  [
    ("-fbitfields", None);
    ("-fpacked-structs", Some (option_fpacked_structs, true));
    ("-fno-packed-structs", Some (option_fpacked_structs, false));
    ("-funstructured-switch", Some (option_funstructured_switch, true));
    ("-fno-unstructured-switch", Some (option_funstructured_switch, false));
    ("-finline-asm", Some (option_finline_asm, true));
    ("-fno-inline-asm", Some (option_finline_asm, false));
  ]

(* The refs a call may change, with the value each held before the first call. *)
let option_refs =
  let open CC.Clflags in
  [
    option_fstruct_passing; option_fpie; option_fpic; option_mthumb; option_g;
    option_Osize; option_fpacked_structs; option_funstructured_switch;
    option_finline_asm; option_ftailcalls; option_fifconversion;
    option_fconstprop; option_fcse; option_fredundancy; option_finline;
    option_finline_functions_called_once;
  ]

let initial_options = lazy (List.map (fun r -> !r) option_refs)

let apply_options o =
  List.iter2 (fun r v -> r := v) option_refs (Lazy.force initial_options);
  let open CC.Clflags in
  (match o.opt_level with
   | O0 ->
       List.iter (fun r -> r := false)
         [ option_ftailcalls; option_fifconversion; option_fconstprop; option_fcse;
           option_fredundancy; option_finline; option_finline_functions_called_once ]
   | O1 | O2 -> ()
   | Os -> option_Osize := true);
  option_fstruct_passing := o.struct_passing;
  option_fpie := o.pie;
  option_fpic := false;
  option_mthumb := false;
  option_g := o.debug

let apply_extra flags =
  let rec go = function
    | [] -> Ok ()
    | f :: rest -> (
        match List.assoc_opt f extra_flags with
        | None -> Error (Unsupported ("unsupported option " ^ f))
        | Some None -> go rest
        | Some (Some (r, v)) ->
            r := v;
            go rest)
  in
  go flags

(* CompCert reports through [Format.err_formatter], except for syntax errors,
   which the embed variant sends to [Embed_diag_out.stderr]. Diverting the
   formatter into a buffer for the duration of [f] keeps diagnostics off the
   host's stderr and gives them back to the caller. *)
let capturing_diagnostics f =
  let buf = Buffer.create 256 in
  let saved = Format.pp_get_formatter_out_functions Format.err_formatter () in
  Format.pp_print_flush Format.err_formatter ();
  Format.pp_set_formatter_out_functions Format.err_formatter
    { saved with Format.out_string = Buffer.add_substring buf; out_flush = ignore };
  let restore () =
    Format.pp_print_flush Format.err_formatter ();
    Format.pp_set_formatter_out_functions Format.err_formatter saved
  in
  Buffer.clear CC.Embed_diag_out.stderr;
  match f () with
  | v ->
      restore ();
      (* A raw fatal error is always the last thing reported: it raises
         [Abort] as soon as it is printed. *)
      (v, Buffer.contents buf, Buffer.contents CC.Embed_diag_out.stderr)
  | exception e ->
      restore ();
      (* The text so far is lost with the exception. *)
      raise e

(* CompCert's atom tables intern every identifier ever seen, for the life of
   the process: ccomp compiles one unit per process, so it never notices. Here
   they leak between compiles, visibly (literal names skip any interned name)
   and without bound. So they are put back, before every compile, to what they
   held before the first one. *)
let atoms_at_start =
  lazy
    ( Hashtbl.copy CC.Camlcoq.atom_of_string,
      Hashtbl.copy CC.Camlcoq.string_of_atom,
      !CC.Camlcoq.next_atom )

let restore_atoms () =
  let a, s, n = Lazy.force atoms_at_start in
  let refill dst src =
    Hashtbl.reset dst;
    Hashtbl.iter (Hashtbl.add dst) src
  in
  refill CC.Camlcoq.atom_of_string a;
  refill CC.Camlcoq.string_of_atom s;
  CC.Camlcoq.next_atom := n

let too_deep_message = "stack exhausted while compiling; the input is nested or long beyond the supported limits"

(* An exception that means the host stack ran out. Native OCaml raises
   [Stack_overflow]; the JavaScript backends add their own forms, which the
   bindings recognise through [overflow_hooks]. *)
let overflow_hooks : (exn -> bool) list ref = ref []
let is_overflow e = e = Stack_overflow || List.exists (fun p -> p e) !overflow_hooks

let compile_ex o source =
  let name = o.name in
  match
    (* Argument checks come before any global state is touched. *)
    apply_extra o.extra
  with
  | Error e -> { result = Error e; diagnostics = "" }
  | Ok () -> (
      restore_atoms ();
      apply_options o;
      ignore (apply_extra o.extra);
      CC.Diagnostics.reset ();
      CC.Frontend.init ();
      CC.DebugInit.init ();
      CC.Embed_argv.Commandline.argv.(2) <- name;
      Hashtbl.replace CC.Embed_source_in.files name source;
      let compile () =
        let csyntax = CC.Frontend.parse_c_file name name in
        match
          CC.Compiler.apply_partial
            (CC.Compiler.transf_c_program csyntax)
            CC.Asmexpand.expand_program
        with
        | CC.Errors.OK asm ->
            (* The printer numbers its own labels from a process-wide counter
               that starts at 100; ccomp prints one unit per process, so it
               always starts there. *)
            CC.PrintAsmaux.next_label := 100;
            let out = Buffer.create 4096 in
            CC.PrintAsm.print_program out asm;
            CC.Diagnostics.check_errors ();
            Ok (Buffer.contents out)
        | CC.Errors.Error msg ->
            CC.Diagnostics.fatal_error (CC.Diagnostics.file_loc name) "%a" CC.Driveraux.print_error msg
      in
      let outcome =
        match
          capturing_diagnostics (fun () -> try compile () with CC.Diagnostics.Abort -> Error ())
        with
        | Ok asm, d, raw -> { result = Ok asm; diagnostics = d ^ raw }
        | Error (), d, raw ->
            (* ccomp ends an aborted run with the error count. *)
            let (), summary, _ = capturing_diagnostics CC.Diagnostics.error_summary in
            let text = d ^ raw ^ summary in
            { result = Error (Diagnostics text); diagnostics = text }
        | exception e when is_overflow e ->
            { result = Error (Too_deep too_deep_message); diagnostics = "" }
        | exception e -> { result = Error (Internal (Printexc.to_string e)); diagnostics = "" }
      in
      Hashtbl.remove CC.Embed_source_in.files name;
      outcome)

let compile o source = (compile_ex o source).result
