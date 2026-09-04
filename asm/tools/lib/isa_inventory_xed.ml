let ( let* ) = Result.bind

let err ?path op detail =
  Err.fail ~pos:__POS__ ~pp_error:Tool_error.pp (Tool_error.v ?path op detail)

type entry = { mnemonic : string; extension : string; applies_32 : bool; applies_64 : bool }

let is_dir p = try Sys.is_directory (Fpath.to_string p) with Sys_error _ -> false

let list_extension_dirs repo =
  let dir = Repo.isa_data_xed repo in
  match Sys.readdir (Fpath.to_string dir) with
  | exception Sys_error msg -> err ~path:dir Tool_error.Read_file msg
  | names ->
      Array.to_list names
      |> List.filter (fun name -> is_dir Fpath.(dir / name))
      |> List.sort String.compare |> Result.ok

(* XED's own tables use runs of spaces for the field gutter ("ICLASS    :"
   and "ICLASS:" both occur), not tabs - the same tolerance
   Isa_inventory_riscv's tokens gives riscv-opcodes. *)
let tokens line =
  String.split_on_char ' ' line
  |> List.concat_map (String.split_on_char '\t')
  |> List.filter (fun s -> s <> "")

(* [line] is a [field] assignment iff it starts with [field] and the next
   character (if any) is whitespace or ':' - which is what rules out a
   longer identifier merely sharing the prefix. No XED field name is a
   prefix of another today, but the check is free. *)
let field_value line ~field =
  let flen = String.length field in
  if String.length line < flen || String.sub line 0 flen <> field then None
  else
    let next_ok =
      String.length line = flen || match line.[flen] with ' ' | '\t' | ':' -> true | _ -> false
    in
    if not next_ok then None
    else
      match String.index_opt line ':' with
      | None -> None
      | Some i -> Some (String.trim (String.sub line (i + 1) (String.length line - i - 1)))

(* One [{ ... }] block's accumulator. A block can carry several PATTERN
   lines (XED's hand-authored dialect) as well as just one (the generated
   dialect) - see the .mli and asm/docs/isa-inventory.md. *)
type block_state = {
  mutable iclass : string option;
  mutable saw_pattern : bool;
  mutable any_32_ok : bool;
  mutable any_64_ok : bool;
}

let fresh_block () = { iclass = None; saw_pattern = false; any_32_ok = false; any_64_ok = false }

let close_block ~extension (b : block_state) acc =
  match b.iclass with
  | None -> acc (* a block with no ICLASS field is not an instruction *)
  | Some name ->
      let applies_32 = if b.saw_pattern then b.any_32_ok else true in
      let applies_64 = if b.saw_pattern then b.any_64_ok else true in
      { mnemonic = String.lowercase_ascii name; extension; applies_32; applies_64 } :: acc

let parse_datafile ~extension text =
  let lines = String.split_on_char '\n' text in
  let rec go lines in_block block acc =
    match lines with
    | [] ->
        if in_block then
          err Tool_error.Parse (Printf.sprintf "%s: unterminated '{' at end of file" extension)
        else Ok (List.rev acc)
    | line :: rest ->
        let trimmed = String.trim line in
        if trimmed = "" || trimmed.[0] = '#' then go rest in_block block acc
        else if trimmed = "{" then
          if in_block then err Tool_error.Parse (Printf.sprintf "%s: nested '{'" extension)
          else go rest true (fresh_block ()) acc
        else if trimmed = "}" then
          if not in_block then err Tool_error.Parse (Printf.sprintf "%s: unmatched '}'" extension)
          else go rest false (fresh_block ()) (close_block ~extension block acc)
        else if not in_block then
          (* Text between blocks: section headers like "AVX_INSTRUCTIONS()::"
             and stray comments/tables that never form a standalone "{"/"}"
             line - see the .mli. Not a parse error. *)
          go rest in_block block acc
        else (
          (match field_value line ~field:"ICLASS" with
          | Some v -> if block.iclass = None then block.iclass <- Some v
          | None -> ());
          (match field_value line ~field:"PATTERN" with
          | Some v ->
              block.saw_pattern <- true;
              let toks = tokens v in
              if not (List.mem "mode64" toks) then block.any_32_ok <- true;
              if not (List.mem "not64" toks) then block.any_64_ok <- true
          | None -> ());
          go rest in_block block acc)
  in
  go lines false (fresh_block ()) []

let entries_in_dir repo extension =
  let dir = Fpath.(Repo.isa_data_xed repo / extension) in
  match Sys.readdir (Fpath.to_string dir) with
  | exception Sys_error msg -> err ~path:dir Tool_error.Read_file msg
  | files ->
      let txt_files =
        Array.to_list files
        |> List.filter (fun f -> Filename.check_suffix f ".txt")
        |> List.sort String.compare
      in
      List.fold_left
        (fun acc f ->
          let* entries = acc in
          let* text = Tool_fs.read Fpath.(dir / f) in
          let* file_entries = parse_datafile ~extension text in
          Ok (List.rev_append file_entries entries))
        (Ok []) txt_files

let compare_entry a b =
  match String.compare a.mnemonic b.mnemonic with
  | 0 -> String.compare a.extension b.extension
  | c -> c

(* Multiple blocks can share one (mnemonic, extension) - the same
   operand-form multiplicity Isa_inventory_riscv collapses - but here a
   later block can also have DIFFERENT mode applicability than an earlier
   one for the very same pair (see monitorx's not64-only forms alongside a
   plain BASE entry elsewhere). A plain sort_uniq would keep both as
   "different" records since their applies_* fields differ; this ORs them
   into one record instead; a mnemonic usable in a mode by ANY block counts
   as usable in that mode. *)
let merge_entries entries =
  let tbl = Hashtbl.create 8192 in
  List.iter
    (fun e ->
      let key = (e.mnemonic, e.extension) in
      match Hashtbl.find_opt tbl key with
      | None -> Hashtbl.replace tbl key (e.applies_32, e.applies_64)
      | Some (a32, a64) -> Hashtbl.replace tbl key (a32 || e.applies_32, a64 || e.applies_64))
    entries;
  Hashtbl.fold
    (fun (mnemonic, extension) (applies_32, applies_64) acc ->
      { mnemonic; extension; applies_32; applies_64 } :: acc)
    tbl []
  |> List.sort compare_entry

let entries_for_target repo (target : Target.t) =
  match target with
  | Target.Arm | Target.Aarch64 | Target.Riscv32 | Target.Riscv64 -> Ok []
  | Target.X86_32 | Target.X86_64 ->
      let* dirs = list_extension_dirs repo in
      let* all_entries =
        List.fold_left
          (fun acc extension ->
            let* entries = acc in
            let* dir_entries = entries_in_dir repo extension in
            Ok (List.rev_append dir_entries entries))
          (Ok []) dirs
      in
      let merged = merge_entries all_entries in
      let applies (e : entry) =
        match target with
        | Target.X86_32 -> e.applies_32
        | Target.X86_64 -> e.applies_64
        | _ -> false
      in
      Ok (List.filter applies merged)

let render_manifest ~source_commit (target : Target.t) entries =
  let b = Buffer.create 65536 in
  Buffer.add_string b "schema-version:1\n";
  Buffer.add_string b (Printf.sprintf "target:%s\n" (Target.to_string target));
  Buffer.add_string b "source:xed\n";
  Buffer.add_string b (Printf.sprintf "source-commit:%s\n" source_commit);
  Buffer.add_string b "source-license:Apache-2.0\n";
  List.iter
    (fun e ->
      Buffer.add_string b
        (Printf.sprintf
           "mnemonic:%s\textension:%s\tcompcert-emitted:unknown\tgcc-emitted:unknown\tstate:unknown\tdeferral-reason:-\tpromotion-trigger:-\n"
           (Manifest.escape e.mnemonic) (Manifest.escape e.extension)))
    entries;
  Buffer.contents b

let render_summary (target : Target.t) entries =
  let b = Buffer.create 4096 in
  Buffer.add_string b (Printf.sprintf "target:%s\n" (Target.to_string target));
  Buffer.add_string b (Printf.sprintf "total:%d\n" (List.length entries));
  let by_extension = Hashtbl.create 128 in
  List.iter
    (fun e ->
      Hashtbl.replace by_extension e.extension
        (1 + Option.value (Hashtbl.find_opt by_extension e.extension) ~default:0))
    entries;
  Hashtbl.to_seq by_extension |> List.of_seq
  |> List.sort (fun (a, _) (b, _) -> String.compare a b)
  |> List.iter (fun (ext, n) -> Buffer.add_string b (Printf.sprintf "by-extension:%s:%d\n" ext n));
  Buffer.add_string b (Printf.sprintf "by-state:unknown:%d\n" (List.length entries));
  Buffer.add_string b "compcert-emitted:0\n";
  Buffer.add_string b "gcc-emitted:0\n";
  Buffer.contents b
