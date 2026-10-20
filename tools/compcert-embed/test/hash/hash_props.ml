(* Native_hash against Hashtbl.hash, on random keys of every type the embed
   variant hashes. Any difference is a failure; run natively, where
   Hashtbl.hash is the reference. *)

module CC = Embed_cc.CC
open CC
module H = Embed_cc.Tr_list.Native_hash
module E = CC.Embed_hash

let () = Random.init (try int_of_string (Sys.getenv "HASH_SEED") with Not_found -> 5)
let failures = ref 0
let checks = ref 0

let check what key expected got =
  incr checks;
  if expected <> got then begin
    incr failures;
    if !failures <= 20 then Printf.printf "MISMATCH %s: %s expected %d got %d\n" what key expected got
  end

let random_string () =
  let n = match Random.int 4 with 0 -> Random.int 4 | 1 -> Random.int 20 | 2 -> Random.int 70 | _ -> Random.int 300 in
  String.init n (fun _ -> Char.chr (Random.int 256))

let rec random_positive depth : BinNums.positive =
  if depth = 0 || Random.int 8 = 0 then BinNums.Coq_xH
  else if Random.bool () then BinNums.Coq_xI (random_positive (depth - 1))
  else BinNums.Coq_xO (random_positive (depth - 1))

let random_int64 () =
  match Random.int 4 with
  | 0 -> Int64.of_int (Random.int 256)
  | 1 -> Int64.of_int (Random.bits ())
  | 2 -> Int64.neg (Int64.of_int (Random.bits ()))
  | _ -> Int64.logor (Int64.shift_left (Int64.of_int (Random.bits ())) 33) (Int64.of_int (Random.bits ()))

let all_ikinds = [ C.IBool; C.IChar; C.ISChar; C.IUChar; C.IShort; C.IUShort; C.IInt; C.IUInt; C.ILong; C.IULong; C.ILongLong; C.IULongLong ]

let () =
  (* Raw cases of the description language. *)
  check "int" "0" (Hashtbl.hash 0) (H.hash (H.Int 0));
  for _ = 1 to 2000 do
    let n = Random.bits () - (1 lsl 29) in
    check "int" (string_of_int n) (Hashtbl.hash n) (H.hash (H.Int n))
  done;
  for _ = 1 to 5000 do
    let s = random_string () in
    check "string" (String.escaped s) (Hashtbl.hash s) (E.hash_string s)
  done;
  for _ = 1 to 3000 do
    let l = List.init (Random.int 160) (fun _ -> random_int64 ()) in
    let ik = List.nth all_ikinds (Random.int (List.length all_ikinds)) in
    let k = (l, ik) in
    check "int64 list * ikind" (Printf.sprintf "len %d" (List.length l)) (Hashtbl.hash k) (E.hash_wide_string k)
  done;
  for _ = 1 to 5000 do
    let r = random_positive (1 + Random.int 40) in
    let ty = [| AST.Tint; AST.Tfloat; AST.Tlong; AST.Tsingle; AST.Tany32; AST.Tany64 |].(Random.int 6) in
    let v = XTL.V (r, ty) in
    check "var V" "" (Hashtbl.hash v) (E.hash_var v)
  done;
  let mregs = Array.of_list CC.Machregs.all_mregs in
  let random_mreg () = mregs.(Random.int (Array.length mregs)) in
  let random_ty () = [| AST.Tint; AST.Tfloat; AST.Tlong; AST.Tsingle; AST.Tany32; AST.Tany64 |].(Random.int 6) in
  let random_slot () = [| Locations.Local; Locations.Incoming; Locations.Outgoing |].(Random.int 3) in
  let random_z () =
    match Random.int 3 with
    | 0 -> BinNums.Z0
    | 1 -> BinNums.Zpos (random_positive (1 + Random.int 20))
    | _ -> BinNums.Zneg (random_positive (1 + Random.int 20))
  in
  for _ = 1 to 5000 do
    let l =
      if Random.bool () then Locations.R (random_mreg ()) else Locations.S (random_slot (), random_z (), random_ty ())
    in
    let v = XTL.L l in
    check "var L" "" (Hashtbl.hash v) (E.hash_var v)
  done;
  (* The whole description language against hand-built native values. *)
  for _ = 1 to 2000 do
    let a = random_int64 () and b = random_string () in
    let native = (a, [ b; b ], 7) in
    let described = H.Block (0, [| H.Int64 a; H.Block (0, [| H.Str b; H.Block (0, [| H.Str b; H.Int 0 |]) |]); H.Int 7 |]) in
    check "tuple" "" (Hashtbl.hash native) (H.hash described)
  done;
  Printf.printf "%d checks, %d mismatches\n" !checks !failures;
  if !failures > 0 then exit 1
