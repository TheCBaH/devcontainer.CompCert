(* The embed API as a command, for the differential driver and the repeat
   test: embed_cli [--repeat N] [-O0|-O1|-O2|-Os] <file.i>

   embed_cli [-g] ... also sets the debug option (-g).

   embed_cli --many <out-dir> <file.i>... compiles the files one after the
   other in this process, writing <out-dir>/<suite>/<name>.s, .err and .status
   for <dir>/<suite>/<name>.i, the layout test/diff/run.exe uses: a later
   compile must not depend on an earlier one.

   The assembly goes to stdout. A failed compile prints CompCert's diagnostics
   on stderr and exits 1. With --repeat N the file is compiled N times in this
   process; every output must equal the first, and the resident set at the end
   is reported on stderr. *)

let rss_kb () =
  try
    let ic = open_in "/proc/self/status" in
    let rec go () =
      match input_line ic with
      | l when String.length l > 6 && String.sub l 0 6 = "VmRSS:" ->
          Scanf.sscanf l "VmRSS: %d" (fun n -> n)
      | _ -> go ()
      | exception End_of_file -> 0
    in
    let n = go () in
    close_in ic;
    n
  with Sys_error _ -> 0

let many dir files =
  List.iter
    (fun file ->
      let suite = Filename.basename (Filename.dirname file) in
      let base = Filename.chop_suffix (Filename.basename file) ".i" in
      (try Sys.mkdir (Filename.concat dir suite) 0o755 with Sys_error _ -> ());
      let source = In_channel.with_open_bin file In_channel.input_all in
      let o = { Compcert_js.default_options with name = file } in
      let out = Compcert_js.compile_ex o source in
      let write ext s = Out_channel.with_open_bin (Filename.concat (Filename.concat dir suite) (base ^ ext)) (fun oc -> output_string oc s) in
      write ".err" out.diagnostics;
      (match out.result with
       | Ok asm -> write ".s" asm; write ".status" "0\n"
       | Error (Compcert_js.Diagnostics _) -> write ".s" ""; write ".status" "1\n"
       | Error _ -> write ".s" ""; write ".status" "3\n"))
    files

let () =
  match Array.to_list Sys.argv with
  | _ :: "--many" :: dir :: files -> many dir files; exit 0
  | _ -> ()

let () =
  let repeat = ref 1 and opt = ref Compcert_js.O2 and file = ref "" and debug = ref false in
  let rec args = function
    | "--repeat" :: n :: r -> repeat := int_of_string n; args r
    | "-O0" :: r -> opt := Compcert_js.O0; args r
    | "-O1" :: r -> opt := Compcert_js.O1; args r
    | "-O2" :: r -> opt := Compcert_js.O2; args r
    | "-Os" :: r -> opt := Compcert_js.Os; args r
    | "-g" :: r -> debug := true; args r
    | f :: r -> file := f; args r
    | [] -> ()
  in
  args (List.tl (Array.to_list Sys.argv));
  let source = In_channel.with_open_bin !file In_channel.input_all in
  let o = { Compcert_js.default_options with name = !file; opt_level = !opt; debug = !debug } in
  let out = Compcert_js.compile_ex o source in
  let first = out.result in
  prerr_string out.diagnostics;
  (match first with
   | Ok asm -> print_string asm
   | Error (Compcert_js.Diagnostics _) -> ()
   | Error (Too_deep m) -> prerr_endline ("error (too_deep): " ^ m)
   | Error (Unsupported m) -> prerr_endline ("error (unsupported): " ^ m)
   | Error (Internal m) -> prerr_endline ("error (internal): " ^ m));
  let r0 = ref 0 in
  for i = 2 to !repeat do
    if i = 11 then r0 := rss_kb ();
    if Compcert_js.compile o source <> first then begin
      Printf.eprintf "repeat %d differs\n" i;
      exit 3
    end
  done;
  if !repeat > 1 then Printf.eprintf "rss after warmup %d kB, at end %d kB\n" !r0 (rss_kb ());
  (* the same statuses as test/node/compile.js: 1 for a diagnosed error, 3 for the others *)
  exit (match first with Ok _ -> 0 | Error (Compcert_js.Diagnostics _) -> 1 | Error _ -> 3)
