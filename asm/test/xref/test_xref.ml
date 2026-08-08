(* Do this assembler and GNU as produce the same bytes?

   test/differential asks that of one CompCert fixture per target. What it can
   establish is bounded by what those fixtures contain: 24 encoding forms, all
   of them a function prologue and epilogue. This file asks the same question
   over the corpus tools/asm-gas-xref.sh builds, and that corpus grows on its
   own - every entry test/snippets learns to assemble becomes a case here
   without anyone writing a fixture.

   The comparison is exact and unnormalized. There is no spelling normalization
   here of the kind test/differential needs for its disassembly comparison,
   because nothing is being compared as text: two assemblers were given one file
   and produced bytes, and the bytes either match or they do not.

   The input is *generated*, which is what makes a disagreement attributable.
   snippet_emit writes each case from the same canonical printer whose output
   test/snippets pins, so our bytes and GNU's come from one AST rather than from
   two hand-maintained descriptions of it. A hand-written .s would have left
   open the possibility that the two toolchains were reading different files. *)

let corpus_root = "../../fixtures/gas-xref"

let read path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

let hex s =
  String.concat " " (List.init (String.length s) (fun i -> Printf.sprintf "%02x" (Char.code s.[i])))

(* [text.hex] is a whitespace-separated byte list in memory order wrapped at
   sixteen bytes a line. Read back as bytes rather than compared as text, so a
   difference in line wrapping is not reported as a difference in code - the
   same decision, and the same reason, as test/differential. *)
let bytes_of_hex_file path =
  let buf = Buffer.create 64 in
  String.split_on_char '\n' (read path)
  |> List.iter (fun line ->
      String.split_on_char ' ' line
      |> List.iter (fun tok ->
          let tok = String.trim tok in
          if tok <> "" then Buffer.add_char buf (Char.chr (int_of_string ("0x" ^ tok)))));
  Buffer.contents buf

(* The canonical target order tools/target-matrix.sh fixes, which is the order
   every generated artifact and manifest in this project uses. *)
let targets = [ "x86_32"; "x86_64"; "arm"; "aarch64" ]

let cases target =
  let dir = Filename.concat corpus_root target in
  if not (Sys.file_exists dir) then []
  else Array.to_list (Sys.readdir dir) |> List.sort String.compare

(* Assemble one case with this project's assembler and bind it at zero, which is
   the base the GNU oracle's objcopy dump is relative to. Every M1 case is
   relocation-free, so the base cannot matter - and if one day it does, this is
   where that shows up as a difference rather than as a silent success. *)
let our_bytes target source_text =
  match Driver.Registry.find target with
  | None -> Error (target ^ ": no such target")
  | Some (module D : Target_intf.Target.DRIVER) -> (
      let source = Foundation.Span.source ~name:(target ^ ".s") ~contents:source_text in
      match D.assemble ~unit_name:"asm_snippet" ~source with
      | Error ds -> Error (String.trim (Foundation.Diagnostic.render_all ds))
      | Ok laid_out -> (
          let plan = Image.plan_of laid_out in
          let addresses =
            List.map (fun (s : Image.segment_plan) -> (s.Image.seg_name, 0L)) plan.Image.segments
          in
          match Image.bind_image laid_out ~addresses with
          | Error ds -> Error (String.trim (Foundation.Diagnostic.render_all ds))
          | Ok img -> (
              match img.Image.segments with
              | s :: _ -> Ok s.Image.bytes
              | [] -> Error "the image has no segment")))

type verdict = Agree | Differ of string | Rejected of string

let verdict_of target case =
  let dir = Filename.concat (Filename.concat corpus_root target) case in
  let gnu = bytes_of_hex_file (Filename.concat dir "text.hex") in
  match our_bytes target (read (Filename.concat dir "input.s")) with
  | Error msg -> Rejected msg
  | Ok ours when String.equal ours gnu -> Agree
  | Ok ours -> Differ (Printf.sprintf "ours %s\n      gnu  %s" (hex ours) (hex gnu))

let%expect_test "every corpus case: our bytes against GNU as" =
  let agree = ref 0 and other = ref 0 in
  List.iter
    (fun target ->
      List.iter
        (fun case ->
          match verdict_of target case with
          | Agree ->
              incr agree;
              Printf.printf "%-8s %-16s agree\n" target case
          | Differ d ->
              incr other;
              Printf.printf "%-8s %-16s DIFFER\n      %s\n" target case d
          | Rejected msg ->
              (* A rejection here is a failure, not a scope statement. The
                 corpus contains only cases this assembler produced the text
                 for, so refusing to read its own output back is a round-trip
                 bug - contracts.md §1 requires the canonical dump to be
                 exactly re-parseable. *)
              incr other;
              Printf.printf "%-8s %-16s REJECTED %s\n" target case msg)
        (cases target))
    targets;
  Printf.printf "\n%d agree, %d not\n" !agree !other;
  [%expect
    {|
    x86_32   return41         agree
    x86_32   return42         agree
    x86_64   return41         agree
    x86_64   return42         agree
    arm      callee_clobber   agree
    arm      return41         agree
    arm      return42         agree
    arm      sp_corrupt       agree
    aarch64  callee_clobber   agree
    aarch64  return41         agree
    aarch64  return42         agree

    11 agree, 0 not |}]
