(* OCaml's [Hashtbl.hash] (caml_hash with count 10, limit 100, seed 0) in plain
   OCaml, for backends whose own hash differs (Melange). A hashtable that
   iterates in an order the output depends on is made with [Hashtbl.Make] and a
   hash from here, and then iterates exactly as the native one does.

   A value is described by [v], the shape the native runtime sees: an
   immediate, a 64-bit integer (a custom block), a string, or a block with a
   tag and fields. The conversion from a CompCert type to [v] mirrors how
   ocamlopt represents it and is written per type (see embed_hash.ml); the
   property test compares the result with [Hashtbl.hash] on random values.

   All arithmetic is on Int32 / Int64, so native, js_of_ocaml and Melange
   compute the same bits. *)

type v =
  | Int of int  (** an immediate: an int, a constant constructor *)
  | Int64 of int64
  | Str of string
  | Block of int * v array  (** tag, fields *)

let ( ^^ ) = Int32.logxor
let rotl x n = Int32.logor (Int32.shift_left x n) (Int32.shift_right_logical x (32 - n))

let mix h d =
  let d = Int32.mul d 0xcc9e2d51l in
  let d = rotl d 15 in
  let d = Int32.mul d 0x1b873593l in
  let h = h ^^ d in
  let h = rotl h 13 in
  Int32.add (Int32.mul h 5l) 0xe6546b64l

let final_mix h =
  let h = h ^^ Int32.shift_right_logical h 16 in
  let h = Int32.mul h 0x85ebca6bl in
  let h = h ^^ Int32.shift_right_logical h 13 in
  let h = Int32.mul h 0xc2b2ae35l in
  h ^^ Int32.shift_right_logical h 16

(* An immediate n, as the runtime sees it: the tagged word 2n+1 on 64 bits,
   folded to 32. *)
let mix_int h n =
  let d = Int64.add (Int64.mul 2L (Int64.of_int n)) 1L in
  let folded = Int64.logxor (Int64.shift_right d 32) (Int64.logxor (Int64.shift_right d 63) d) in
  mix h (Int64.to_int32 folded)

let mix_int64 h x =
  let lo = Int64.to_int32 x and hi = Int64.to_int32 (Int64.shift_right_logical x 32) in
  mix h (lo ^^ hi)

let mix_string h s =
  let len = String.length s in
  let byte i = Int32.of_int (Char.code (String.unsafe_get s i)) in
  let h = ref h in
  let i = ref 0 in
  while !i + 4 <= len do
    let w =
      Int32.logor (byte !i)
        (Int32.logor (Int32.shift_left (byte (!i + 1)) 8)
           (Int32.logor (Int32.shift_left (byte (!i + 2)) 16) (Int32.shift_left (byte (!i + 3)) 24)))
    in
    h := mix !h w;
    i := !i + 4
  done;
  (match len land 3 with
   | 3 ->
       h := mix !h (Int32.logor (byte !i) (Int32.logor (Int32.shift_left (byte (!i + 1)) 8) (Int32.shift_left (byte (!i + 2)) 16)))
   | 2 -> h := mix !h (Int32.logor (byte !i) (Int32.shift_left (byte (!i + 1)) 8))
   | 1 -> h := mix !h (byte !i)
   | _ -> ());
  !h ^^ Int32.of_int len

let queue_size = 256

(* Hashtbl.hash = caml_hash 10 100 0. *)
let hash_param count limit (x : v) : int =
  let sz = if limit < 0 || limit > queue_size then queue_size else limit in
  let queue = Array.make queue_size x in
  let rd = ref 0 and wr = ref 1 in
  let num = ref count in
  let h = ref 0l in
  while !rd < !wr && !num > 0 do
    let v = queue.(!rd) in
    incr rd;
    match v with
    | Int n -> h := mix_int !h n; decr num
    | Int64 x -> h := mix_int64 !h x; decr num
    | Str s -> h := mix_string !h s; decr num
    | Block (tag, fields) ->
        let len = Array.length fields in
        h := mix !h (Int32.of_int ((len lsl 10) lor tag));
        (try
           for i = 0 to len - 1 do
             if !wr >= sz then raise Exit;
             queue.(!wr) <- fields.(i);
             incr wr
           done
         with Exit -> ())
  done;
  Int32.to_int (Int32.logand (final_mix !h) 0x3FFFFFFFl)

let hash v = hash_param 10 100 v
