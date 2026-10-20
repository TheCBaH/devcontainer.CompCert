(* The constant-stack rewrites against the definitions they replace.

   Each function is run on random inputs, some of whose elements fail, and
   must agree with the original on the result, on the exception it raises and
   on the order in which the argument function is applied. Then each is run on
   a list too long for the original to survive on a small stack. *)

module CC = Embed_cc.CC
module T = Embed_cc.Tr_list

let () = Random.init (try int_of_string (Sys.getenv "UNIT_SEED") with Not_found -> 42)
let failures = ref 0

let check name ok =
  if not ok then begin
    incr failures;
    Printf.printf "FAIL %s\n%!" name
  end

(* Run [run] on a function that logs its arguments; the outcome is the result
   or the exception, together with the log. *)
let observe run =
  let log = ref [] in
  let r = try Ok (run log) with e -> Error (Printexc.to_string e) in
  (r, List.rev !log)

let random_list n = List.init n (fun _ -> Random.int 20)
let boom x = if x = 13 then failwith "boom" else x * 2

(* Original definitions, as extracted or as in the stdlib. *)
let rec orig_app l m = match l with [] -> m | a :: l1 -> a :: orig_app l1 m
let rec orig_rev = function [] -> [] | x :: l' -> orig_app (orig_rev l') [ x ]
let rec orig_fold_right f a0 = function [] -> a0 | b :: l0 -> f b (orig_fold_right f a0 l0)

let rec orig_filter f = function
  | [] -> []
  | x :: l0 -> if f x then x :: orig_filter f l0 else orig_filter f l0

let rec orig_remove eq x = function
  | [] -> []
  | y :: tl -> if eq x y then orig_remove eq x tl else y :: orig_remove eq x tl

let rec orig_mmap f = function
  | [] -> CC.Errors.OK []
  | hd :: tl -> (
      match f hd with
      | CC.Errors.OK x -> (
          match orig_mmap f tl with
          | CC.Errors.OK x0 -> CC.Errors.OK (x :: x0)
          | CC.Errors.Error m -> CC.Errors.Error m)
      | CC.Errors.Error m -> CC.Errors.Error m)

let rec orig_transf_globdefs transf_fun transf_var = function
  | [] -> CC.Errors.OK []
  | (id, g) :: l' -> (
      let open CC in
      match g with
      | AST.Gfun f -> (
          match transf_fun id f with
          | Errors.OK tf -> (
              match orig_transf_globdefs transf_fun transf_var l' with
              | Errors.OK x -> Errors.OK ((id, AST.Gfun tf) :: x)
              | Errors.Error msg -> Errors.Error msg)
          | Errors.Error msg ->
              Errors.Error (Errors.MSG "In function " :: Errors.CTX id :: Errors.MSG ": " :: msg))
      | AST.Gvar v -> (
          match AST.transf_globvar transf_var id v with
          | Errors.OK tv -> (
              match orig_transf_globdefs transf_fun transf_var l' with
              | Errors.OK x -> Errors.OK ((id, AST.Gvar tv) :: x)
              | Errors.Error msg -> Errors.Error msg)
          | Errors.Error msg ->
              Errors.Error (Errors.MSG "In variable " :: Errors.CTX id :: Errors.MSG ": " :: msg)))

let logged f log x = log := x :: !log; f x

(* The stdlib list functions, replaced through Embed_list. *)
let () =
  for _ = 1 to 500 do
    let n = Random.int 25 in
    let l = random_list n and l2 = random_list (if Random.bool () then n else n + 1) in
    let same name a b = check name (a = b) in
    same "map" (observe (fun lg -> List.map (logged boom lg) l)) (observe (fun lg -> T.List.map (logged boom lg) l));
    same "mapi"
      (observe (fun lg -> List.mapi (fun i x -> logged boom lg (i + x)) l))
      (observe (fun lg -> T.List.mapi (fun i x -> logged boom lg (i + x)) l));
    same "map2"
      (observe (fun lg -> List.map2 (fun a b -> logged boom lg (a + b)) l l2))
      (observe (fun lg -> T.List.map2 (fun a b -> logged boom lg (a + b)) l l2));
    same "combine" (observe (fun _ -> List.combine l l2)) (observe (fun _ -> T.List.combine l l2));
    same "split" (observe (fun _ -> List.split (List.combine l l))) (observe (fun _ -> T.List.split (List.combine l l)));
    same "append" (observe (fun _ -> l @ l2)) (observe (fun _ -> T.List.append l l2));
    same "flatten" (observe (fun _ -> List.flatten [ l; l2; []; l ])) (observe (fun _ -> T.List.flatten [ l; l2; []; l ]));
    same "concat" (observe (fun _ -> List.concat [ []; l2; l ])) (observe (fun _ -> T.List.concat [ []; l2; l ]));
    same "fold_right"
      (observe (fun lg -> List.fold_right (fun x acc -> logged boom lg x + acc) l 0))
      (observe (fun lg -> T.List.fold_right (fun x acc -> logged boom lg x + acc) l 0));
    same "fold_right order"
      (observe (fun lg -> List.fold_right (fun x acc -> logged (fun x -> x) lg x :: acc) l []))
      (observe (fun lg -> T.List.fold_right (fun x acc -> logged (fun x -> x) lg x :: acc) l []))
  done

(* The extracted list functions. *)
let () =
  for _ = 1 to 500 do
    let l = random_list (Random.int 25) in
    let eq = ( = ) in
    check "Datatypes.app" (CC.Datatypes.app l [ 1; 2 ] = orig_app l [ 1; 2 ]);
    check "List0.rev" (CC.List0.rev l = orig_rev l);
    check "ListDef.map" (observe (fun lg -> CC.ListDef.map (logged succ lg) l) = observe (fun lg -> List.map (logged succ lg) l));
    check "List0.fold_right"
      (observe (fun lg -> CC.List0.fold_right (fun x acc -> logged (fun x -> x) lg x :: acc) [] l)
      = observe (fun lg -> orig_fold_right (fun x acc -> logged (fun x -> x) lg x :: acc) [] l));
    check "List0.filter" (CC.List0.filter (fun x -> x mod 3 = 0) l = orig_filter (fun x -> x mod 3 = 0) l);
    check "List0.remove" (CC.List0.remove eq 5 l = orig_remove eq 5 l);
    let f lg x = lg := x :: !lg; if x = 13 then CC.Errors.Error [ CC.Errors.MSG "bad" ] else CC.Errors.OK (x + 1) in
    check "Errors.mmap"
      (observe (fun lg -> CC.Errors.mmap (f lg) l) = observe (fun lg -> orig_mmap (f lg) l))
  done

(* AST.transf_globdefs, with failures in functions and in variables. *)
let () =
  let open CC in
  for _ = 1 to 500 do
    let n = Random.int 20 in
    let defs =
      List.init n (fun i ->
          let id = Camlcoq.P.of_int (i + 1) in
          if Random.bool () then (id, AST.Gfun (Random.int 20))
          else
            ( id,
              AST.Gvar
                { AST.gvar_info = Random.int 20; gvar_init = []; gvar_readonly = false; gvar_volatile = false } ))
    in
    let tf lg _ x = lg := ("f", x) :: !lg; if x = 13 then Errors.Error [ Errors.MSG "bad fun" ] else Errors.OK (x + 1)
    and tv lg _ x = lg := ("v", x) :: !lg; if x = 7 then Errors.Error [ Errors.MSG "bad var" ] else Errors.OK (x + 2) in
    check "AST.transf_globdefs"
      (observe (fun lg -> AST.transf_globdefs (tf lg) (tv lg) defs)
      = observe (fun lg -> orig_transf_globdefs (tf lg) (tv lg) defs))
  done

(* Lists far longer than the original can take on a small stack. *)
let () =
  let n = 3_000_000 in
  let l = List.init n (fun i -> i land 15) in
  let survives name f = match f () with _ -> () | exception Stack_overflow -> check (name ^ " overflowed") false in
  survives "map" (fun () -> ignore (T.List.map succ l));
  survives "append" (fun () -> ignore (T.List.append l l));
  survives "flatten" (fun () -> ignore (T.List.flatten [ l; l ]));
  survives "fold_right" (fun () -> ignore (T.List.fold_right ( + ) l 0));
  survives "split" (fun () -> ignore (T.List.split (T.List.combine l l)));
  survives "Datatypes.app" (fun () -> ignore (CC.Datatypes.app l l));
  survives "List0.rev" (fun () -> ignore (CC.List0.rev l));
  survives "ListDef.map" (fun () -> ignore (CC.ListDef.map succ l));
  survives "List0.filter" (fun () -> ignore (CC.List0.filter (fun x -> x > 3) l));
  survives "Errors.mmap" (fun () -> ignore (CC.Errors.mmap (fun x -> CC.Errors.OK x) l));
  survives "AST.transf_globdefs" (fun () ->
      let defs = List.init n (fun i -> (CC.Camlcoq.P.of_int (i + 1), CC.AST.Gfun i)) in
      ignore (CC.AST.transf_globdefs (fun _ x -> CC.Errors.OK x) (fun _ x -> CC.Errors.OK x) defs))

let () =
  if !failures > 0 then (Printf.printf "%d failures\n" !failures; exit 1) else print_endline "OK: rewrites agree with the originals"
