(* The embed API as a command, for the differential driver and the repeat
   test: embed_cli [--repeat N] [-O0|-O1|-O2|-Os] <file.i>

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

let () =
  let repeat = ref 1 and opt = ref Compcert_js.O2 and file = ref "" in
  let rec args = function
    | "--repeat" :: n :: r -> repeat := int_of_string n; args r
    | "-O0" :: r -> opt := Compcert_js.O0; args r
    | "-O1" :: r -> opt := Compcert_js.O1; args r
    | "-O2" :: r -> opt := Compcert_js.O2; args r
    | "-Os" :: r -> opt := Compcert_js.Os; args r
    | f :: r -> file := f; args r
    | [] -> ()
  in
  args (List.tl (Array.to_list Sys.argv));
  let source = In_channel.with_open_bin !file In_channel.input_all in
  let o = { Compcert_js.default_options with name = !file; opt_level = !opt } in
  let out = Compcert_js.compile_ex o source in
  let first = out.result in
  prerr_string out.diagnostics;
  (match first with
   | Ok asm -> print_string asm
   | Error (Compcert_js.Diagnostics _) -> ()
   | Error (Too_deep m | Unsupported m | Internal m) -> prerr_endline ("error: " ^ m));
  let r0 = ref 0 in
  for i = 2 to !repeat do
    if i = 11 then r0 := rss_kb ();
    if Compcert_js.compile o source <> first then begin
      Printf.eprintf "repeat %d differs\n" i;
      exit 3
    end
  done;
  if !repeat > 1 then Printf.eprintf "rss after warmup %d kB, at end %d kB\n" !r0 (rss_kb ());
  exit (match first with Ok _ -> 0 | Error _ -> 1)
