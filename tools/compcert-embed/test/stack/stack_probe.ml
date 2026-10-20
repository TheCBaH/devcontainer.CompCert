(* Opened into every module of a scratch copy of the embed library (see
   probe.sh). The list functions that are not tail-recursive on OCaml < 5.1
   record, for a long argument, the CompCert code that called them: the
   function, the call site and the longest list seen, printed at exit. The
   limit is PROBE_LIMIT (default 2000).

   It also samples the call stack every 10 ms and keeps the deepest
   one, printed at exit as a histogram of the code locations on it: a
   recursion proportional to the input shows up as locations with thousands
   of frames, whatever the innermost frame is. *)

let limit = try int_of_string (Sys.getenv "PROBE_LIMIT") with _ -> 2000
let sites : (string, int) Hashtbl.t = Hashtbl.create 16

let () =
  at_exit (fun () ->
      Hashtbl.fold (fun k v acc -> (k, v) :: acc) sites []
      |> List.sort compare
      |> List.iter (fun (k, v) -> Printf.eprintf "probe: %s (up to %d)\n" k v))

let calls = ref 0
let deepest = ref (Printexc.get_callstack 0)
let deepest_len = ref 0

let sample () =
  let cs = Printexc.get_callstack 10_000_000 in
  let n = Printexc.raw_backtrace_length cs in
  if n > !deepest_len then begin deepest := cs; deepest_len := n end

(* A timer signal samples the stack of whatever code is running. *)
let () =
  Sys.set_signal Sys.sigalrm (Sys.Signal_handle (fun _ -> sample ()));
  ignore (Unix.setitimer Unix.ITIMER_REAL { Unix.it_interval = 0.01; it_value = 0.01 })

let dump_deepest () =
  match Printexc.backtrace_slots !deepest with
  | None -> ()
  | Some slots ->
      let h = Hashtbl.create 64 in
      Array.iter
        (fun s ->
          match Printexc.Slot.location s with
          | Some { Printexc.filename; line_number; _ } ->
              let k = Printf.sprintf "%s:%d" filename line_number in
              Hashtbl.replace h k (1 + try Hashtbl.find h k with Not_found -> 0)
          | None -> ())
        slots;
      let top =
        Hashtbl.fold (fun k v acc -> (v, k) :: acc) h [] |> List.sort (fun a b -> compare b a)
      in
      Printf.eprintf "probe: deepest sampled stack %d frames\n" !deepest_len;
      List.iteri (fun i (v, k) -> if i < 12 && v > 20 then Printf.eprintf "probe:   %6d x %s\n" v k) top

let () = at_exit dump_deepest

let check name l =
  if Stdlib.List.compare_length_with l limit > 0 then begin
    let n = Stdlib.List.length l in
    let cs = Printexc.get_callstack 4 in
    let site =
      match Printexc.backtrace_slots cs with
      | Some slots ->
          let frames =
            Array.to_list slots
            |> List.filter_map (fun s ->
                   match Printexc.Slot.location s with
                   | Some { Printexc.filename; line_number; _ } when filename <> "probe/stack_probe.ml" ->
                       Some (Printf.sprintf "%s:%d" filename line_number)
                   | _ -> None)
          in
          (match frames with f :: _ -> f | [] -> "?")
      | None -> "?"
    in
    let key = name ^ " at " ^ site in
    if n > (try Hashtbl.find sites key with Not_found -> 0) then Hashtbl.replace sites key n
  end

let ( @ ) a b = check "@" a; Stdlib.( @ ) a b

module List = struct
  include Stdlib.List
  let append a b = check "append" a; append a b
  let map f l = check "map" l; map f l
  let mapi f l = check "mapi" l; mapi f l
  let map2 f a b = check "map2" a; map2 f a b
  let fold_right f l a = check "fold_right" l; fold_right f l a
  let flatten l = check "flatten" l; List.iter (check "flatten (inner)") l; flatten l
  let concat l = check "concat" l; List.iter (check "concat (inner)") l; concat l
  let split l = check "split" l; split l
  let combine a b = check "combine" a; combine a b
  let concat_map f l = check "concat_map" l; concat_map f l
end
