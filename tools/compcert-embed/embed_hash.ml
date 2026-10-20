(* Injected into the embed variant of CompCert (see ../compcert-embed-target.sh).

   The hashtables whose iteration order reaches the output, made with
   [Hashtbl.Make] and a hash that is [Hashtbl.hash] of the native runtime
   (Native_hash), so that they iterate in the same order on every backend and
   under OCAMLRUNPARAM=R. Each key type is described to Native_hash the way
   ocamlopt represents it; test/hash/hash_props.ml checks every conversion
   against [Hashtbl.hash] natively.

   The tables must be [reset], not [clear]ed, between compiles: [clear] keeps a
   table that grew large, and a larger table iterates in another order, so a
   compile would depend on the files compiled before it.

   A constant constructor is an immediate holding its index, which is what
   [Obj.magic] to int returns on every backend. A list or a chain of
   [positive]s deeper than the hash can look (100 values) is cut: the hash
   never reaches the rest. *)

module H = Native_hash

let const_ctor (x : 'a) : H.v = H.Int (Obj.magic x : int)

let depth_limit = 120

let rec positive_at d (p : BinNums.positive) : H.v =
  if d >= depth_limit then H.Int 0
  else
    match p with
    | BinNums.Coq_xI q -> H.Block (0, [| positive_at (d + 1) q |])
    | BinNums.Coq_xO q -> H.Block (1, [| positive_at (d + 1) q |])
    | BinNums.Coq_xH -> H.Int 0

let positive p = positive_at 0 p

let zint (z : BinNums.coq_Z) : H.v =
  match z with
  | BinNums.Z0 -> H.Int 0
  | BinNums.Zpos p -> H.Block (0, [| positive p |])
  | BinNums.Zneg p -> H.Block (1, [| positive p |])

let rec int64_list_at d (l : int64 list) : H.v =
  if d >= depth_limit then H.Int 0
  else
    match l with
    | [] -> H.Int 0
    | x :: t -> H.Block (0, [| H.Int64 x; int64_list_at (d + 1) t |])

let bool_ (b : bool) : H.v = H.Int (if b then 1 else 0)

let binary_float (f : Binary.binary_float) : H.v =
  match f with
  | Binary.B754_zero s -> H.Block (0, [| bool_ s |])
  | Binary.B754_infinity s -> H.Block (1, [| bool_ s |])
  | Binary.B754_nan (s, p) -> H.Block (2, [| bool_ s; positive p |])
  | Binary.B754_finite (s, m, e) -> H.Block (3, [| bool_ s; positive m; zint e |])

let symbol_offset ((id, ofs) : BinNums.positive * BinNums.coq_Z) : H.v =
  H.Block (0, [| positive id; zint ofs |])

let loc (l : Locations.loc) : H.v =
  match l with
  | Locations.R m -> H.Block (0, [| const_ctor m |])
  | Locations.S (sl, ofs, ty) -> H.Block (1, [| const_ctor sl; zint ofs; const_ctor ty |])

let var (v : XTL.var) : H.v =
  match v with
  | XTL.V (r, ty) -> H.Block (0, [| positive r; const_ctor ty |])
  | XTL.L l -> H.Block (1, [| loc l |])

let wide_string ((l, ik) : int64 list * C.ikind) : H.v =
  H.Block (0, [| int64_list_at 0 l; const_ctor ik |])

let hash_string (s : string) = H.hash (H.Str s)
let hash_int (n : int) = H.hash (H.Int n)
let hash_wide_string (k : int64 list * C.ikind) = H.hash (wide_string k)
let hash_var (v : XTL.var) = H.hash (var v)
let hash_float (f : Binary.binary_float) = H.hash (binary_float f)
let hash_symbol_offset (k : BinNums.positive * BinNums.coq_Z) = H.hash (symbol_offset k)

module StringTbl = Hashtbl.Make (struct
  type t = string
  let equal (a : string) b = a = b
  let hash = hash_string
end)

module IntTbl = Hashtbl.Make (struct
  type t = int
  let equal (a : int) b = a = b
  let hash = hash_int
end)

module WideStringTbl = Hashtbl.Make (struct
  type t = int64 list * C.ikind
  let equal (a : t) b = a = b
  let hash = hash_wide_string
end)

module VarTbl = Hashtbl.Make (struct
  type t = XTL.var
  let equal (a : t) b = a = b
  let hash = hash_var
end)

(* ARM's literal pools. *)
module FloatTbl = Hashtbl.Make (struct
  type t = Binary.binary_float
  let equal (a : t) b = a = b
  let hash = hash_float
end)

module SymbolTbl = Hashtbl.Make (struct
  type t = BinNums.positive * BinNums.coq_Z
  let equal (a : t) b = a = b
  let hash = hash_symbol_offset
end)
