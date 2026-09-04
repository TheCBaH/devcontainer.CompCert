let ( let* ) = Result.bind
let err op detail = Err.fail ~pos:__POS__ ~pp_error:Tool_error.pp (Tool_error.v op detail)
let riscv_targets = [ Target.Riscv32; Target.Riscv64 ]

let submodule_commit dir =
  match
    Tool_process.exec
      (Tool_process.spec ~cwd:dir ~stdout:Tool_process.Out_capture ~stderr:Tool_process.Err_capture
         ~accepted:Process_status.Zero_only ~label:"isa-inventory git rev-parse" "git"
         [ "rev-parse"; "HEAD" ])
  with
  | Ok { Tool_process.stdout; _ } -> Ok (String.trim (Option.value stdout ~default:""))
  | Error e -> Error e

let write_target repo ~source_commit target =
  let* entries = Isa_inventory_riscv.entries_for_target repo target in
  if entries = [] then
    err Tool_error.Validate
      (Printf.sprintf "riscv-opcodes produced no entries for %s" (Target.to_string target))
  else
    let dest = Repo.isa_inventory repo target in
    let* () = Tool_fs.mkdir_p dest in
    let* () =
      Tool_fs.write
        Fpath.(dest / "manifest.txt")
        (Isa_inventory_riscv.render_manifest ~source_commit target entries)
    in
    let* () =
      Tool_fs.write Fpath.(dest / "summary.txt") (Isa_inventory_riscv.render_summary target entries)
    in
    Ok (List.length entries)

let regen repo =
  let step =
    let* source_commit = submodule_commit (Repo.isa_data_riscv_opcodes repo) in
    List.fold_left
      (fun acc target ->
        let* lines = acc in
        let* n = write_target repo ~source_commit target in
        Ok ((Target.to_string target, n) :: lines))
      (Ok []) riscv_targets
  in
  match step with
  | Error e -> Command.of_error e
  | Ok counts ->
      let summary =
        List.rev counts
        |> List.map (fun (t, n) -> Printf.sprintf "%s: %d entries" t n)
        |> String.concat ", "
      in
      Command.ok [ Diagnostic.stdout (Printf.sprintf "isa-inventory: %s" summary) ]
