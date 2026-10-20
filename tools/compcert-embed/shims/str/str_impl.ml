(* A pure-OCaml implementation of the part of the Str library that CompCert
   uses, for backends without Str's C stubs (Melange). It is a backtracking
   matcher over the same regular-expression syntax:

     c  .  [set]  [^set]  [a-z]   one character
     r*  r+  r?                    greedy repetition
     ^  $                          beginning and end of line
     \( r \)  \|                   group, alternation (first alternative that works)
     \1 .. \9                      back-reference to a group
     \b                            word boundary
     \c                            the character c, for any other c

   The last match is kept in global state, as Str does. Test/str_props.ml
   checks this module against the real Str. *)

type node =
  | Char of char
  | Any
  | Set of Bytes.t (* 256 flags *)
  | Bol
  | Eol
  | Wordb
  | Group of int * node
  | Backref of int
  | Seq of node list
  | Alt of node * node
  | Star of node
  | Plus of node
  | Opt of node

type regexp = { prog : node; ngroups : int }

let set_of_chars neg items =
  let b = Bytes.make 256 '\000' in
  List.iter (fun (lo, hi) -> for c = Char.code lo to Char.code hi do Bytes.set b c '\001' done) items;
  if neg then
    for c = 0 to 255 do
      Bytes.set b c (if Bytes.get b c = '\000' then '\001' else '\000')
    done;
  Set b

let parse (s : string) : regexp =
  let n = String.length s in
  let ngroups = ref 0 in
  let fail () = failwith "Str.regexp: invalid regular expression" in
  (* alternation <- sequence ( \| sequence )* *)
  let rec alt i =
    let r, i = seq i in
    if i + 1 < n && s.[i] = '\\' && s.[i + 1] = '|' then
      let r2, i = alt (i + 2) in
      (Alt (r, r2), i)
    else (r, i)
  and seq i =
    let rec go acc i =
      if i >= n then (List.rev acc, i)
      else if s.[i] = '\\' && i + 1 < n && (s.[i + 1] = '|' || s.[i + 1] = ')') then (List.rev acc, i)
      else
        let a, i = atom i in
        let a, i = postfix a i in
        go (a :: acc) i
    in
    let l, i = go [] i in
    ((match l with [ x ] -> x | l -> Seq l), i)
  and postfix a i =
    if i < n then
      match s.[i] with
      | '*' -> postfix (Star a) (i + 1)
      | '+' -> postfix (Plus a) (i + 1)
      | '?' -> postfix (Opt a) (i + 1)
      | _ -> (a, i)
    else (a, i)
  and atom i =
    match s.[i] with
    | '.' -> (Any, i + 1)
    | '^' -> (Bol, i + 1)
    | '$' -> (Eol, i + 1)
    | '[' -> bracket (i + 1)
    | '\\' ->
        if i + 1 >= n then (Char '\\', i + 1)
        else (
          match s.[i + 1] with
          | '(' ->
              incr ngroups;
              let g = !ngroups in
              let r, j = alt (i + 2) in
              if j + 1 < n && s.[j] = '\\' && s.[j + 1] = ')' then (Group (g, r), j + 2) else fail ()
          | '1' .. '9' as d -> (Backref (Char.code d - 48), i + 2)
          | 'b' -> (Wordb, i + 2)
          | c -> (Char c, i + 2))
    | c -> (Char c, i + 1)
  and bracket i =
    let neg, i = if i < n && s.[i] = '^' then (true, i + 1) else (false, i) in
    let items = ref [] in
    let rec go i first =
      if i >= n then fail ()
      else if s.[i] = ']' && not first then i + 1
      else
        let lo = s.[i] in
        if i + 2 < n && s.[i + 1] = '-' && s.[i + 2] <> ']' then (
          items := (lo, s.[i + 2]) :: !items;
          go (i + 3) false)
        else (
          items := (lo, lo) :: !items;
          go (i + 1) false)
    in
    let j = go i true in
    (set_of_chars neg !items, j)
  in
  let r, i = alt 0 in
  if i <> n then fail ();
  { prog = r; ngroups = !ngroups }

let regexp s = parse s

let quote s =
  let b = Buffer.create (String.length s + 8) in
  String.iter
    (fun c ->
      (match c with
       | '$' | '^' | '.' | '*' | '+' | '?' | '[' | ']' | '\\' -> Buffer.add_char b '\\'
       | _ -> ());
      Buffer.add_char b c)
    s;
  Buffer.contents b

let regexp_string s =
  { prog = Seq (List.init (String.length s) (fun i -> Char s.[i])); ngroups = 0 }

(* Last match: start and end of the whole match, then of each group. *)
let starts = Array.make 10 (-1)
let ends = Array.make 10 (-1)

let is_word c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_'

exception Hit_end

(* [m node s i k]: match [node] at [i], then call the continuation [k] with the
   position reached. [partial] is set when the match ran into the end of [s]. *)
let hit_end = ref false

let accepts r c =
  match r with
  | Char x -> c = x
  | Any -> c <> '\n'
  | Set b -> Bytes.get b (Char.code c) <> '\000'
  | _ -> false

(* Str compiles a repetition of a single character or set that is followed, in
   its sequence, by something that cannot start with the same character as a
   loop that never backtracks and does not report running into the end of the
   text. That is invisible to [string_match], but it decides [string_partial_match],
   so the same analysis is done here. *)
let full_set = Bytes.make 256 '\001'
let single_set c = let b = Bytes.make 256 '\000' in Bytes.set b (Char.code c) '\001'; b

let union_set a b =
  let r = Bytes.copy a in
  Bytes.iteri (fun i c -> if c <> '\000' then Bytes.set r i '\001') b;
  r

let disjoint_sets a b =
  let rec go i = i >= 256 || ((Bytes.get a i = '\000' || Bytes.get b i = '\000') && go (i + 1)) in
  go 0

let any_set = let b = Bytes.make 256 '\001' in Bytes.set b 10 '\000'; b

(* A set of characters that contains the first character of every string the
   node matches (everything, for a node that can match the empty string). *)
let rec first = function
  | Char c -> single_set c
  | Any -> any_set
  | Set b -> b
  | Seq l -> first_seq l
  | Alt (a, b) -> union_set (first a) (first b)
  | Star _ | Opt _ | Backref _ | Bol | Eol | Wordb -> full_set
  | Plus r | Group (_, r) -> first r

and first_seq = function
  | [] -> full_set
  | (Bol | Eol | Wordb) :: rl -> first_seq rl
  | (Star r | Opt r) :: rl -> union_set (first r) (first_seq rl)
  | r :: _ -> first r

let is_single = function Char _ | Any | Set _ -> true | _ -> false

let rec m node s i (k : int -> bool) : bool =
  let n = String.length s in
  match node with
  | Char c -> if i < n then s.[i] = c && k (i + 1) else (hit_end := true; false)
  | Any -> if i < n then s.[i] <> '\n' && k (i + 1) else (hit_end := true; false)
  | Set b -> if i < n then Bytes.get b (Char.code s.[i]) <> '\000' && k (i + 1) else (hit_end := true; false)
  | Bol -> (i = 0 || s.[i - 1] = '\n') && k i
  | Eol -> (i = n || s.[i] = '\n') && k i
  | Wordb ->
      if n = 0 then (hit_end := true; false)
      else
        let before = i > 0 && is_word s.[i - 1] and after = i < n && is_word s.[i] in
        before <> after && k i
  | Group (g, r) ->
      (* As in Str, the start and the end of a group are recorded apart, each
         undone when the match backtracks over it. *)
      let os = starts.(g) in
      starts.(g) <- i;
      m r s i (fun j ->
          let oe = ends.(g) in
          ends.(g) <- j;
          k j || (ends.(g) <- oe; false))
      || (starts.(g) <- os; false)
  | Backref g ->
      if starts.(g) < 0 || ends.(g) < 0 then false
      else
        let rec cmp p i =
          if p >= ends.(g) then k i
          else if i >= n then (hit_end := true; false)
          else s.[p] = s.[i] && cmp (p + 1) (i + 1)
        in
        cmp starts.(g) i
  | Seq l ->
      let rec go l i =
        match l with
        | [] -> k i
        | (Star r | Plus r | Opt r as x) :: rest when is_single r && disjoint_sets (first r) (first_seq rest) -> (
            (* Str's simple loops: no backtracking, no end-of-text report
               except for the first character of a repetition with [+]. *)
            let n = String.length s in
            let one j = j < n && accepts r s.[j] in
            match x with
            | Star _ ->
                let j = ref i in
                while one !j do incr j done;
                go rest !j
            | Plus _ ->
                if i >= n then (hit_end := true; false)
                else if not (one i) then false
                else begin
                  let j = ref (i + 1) in
                  while one !j do incr j done;
                  go rest !j
                end
            | _ -> go rest (if one i then i + 1 else i))
        | x :: rest -> m x s i (fun j -> go rest j)
      in
      go l i
  | Alt (a, b) -> m a s i k || m b s i k
  | Opt r -> m r s i k || k i
  | Star r -> star r s i k
  | Plus r -> m r s i (fun j -> star r s j k)

and star r s i k =
  (* Single-character bodies are matched in a loop: longest first. *)
  match r with
  | Char _ | Any | Set _ ->
      let n = String.length s in
      let j = ref i in
      while !j < n && accepts r s.[!j] do incr j done;
      if !j >= n then hit_end := true;
      let rec back j = k j || (j > i && back (j - 1)) in
      back !j
  | _ -> m r s i (fun j -> j > i && star r s j k) || k i

let reset_groups () =
  Array.fill starts 0 10 (-1);
  Array.fill ends 0 10 (-1)

let match_at re s pos =
  reset_groups ();
  let result = ref (-1) in
  if m re.prog s pos (fun j -> result := j; true) then begin
    starts.(0) <- pos;
    ends.(0) <- !result;
    true
  end
  else false

let string_match re s pos =
  if pos < 0 || pos > String.length s then invalid_arg "Str.string_match";
  match_at re s pos

let string_partial_match re s pos =
  if pos < 0 || pos > String.length s then invalid_arg "Str.string_partial_match";
  hit_end := false;
  match_at re s pos || !hit_end

let search_forward re s pos =
  let n = String.length s in
  if pos < 0 || pos > n then invalid_arg "Str.search_forward";
  let rec go i = if i > n then raise Not_found else if match_at re s i then i else go (i + 1) in
  go pos

let search_backward re s pos =
  if pos < 0 || pos > String.length s then invalid_arg "Str.search_backward";
  let rec go i = if i < 0 then raise Not_found else if match_at re s i then i else go (i - 1) in
  go pos

let last_s = ref ""

(* The string the last match was made on is needed by the accessors; the real
   Str takes it as an argument too. *)
let matched_group g s =
  if g < 0 || g > 9 then invalid_arg "Str.matched_group";
  if starts.(g) < 0 || ends.(g) < 0 then raise Not_found;
  String.sub s starts.(g) (ends.(g) - starts.(g))

let match_beginning () = if starts.(0) < 0 then raise Not_found else starts.(0)
let match_end () = if ends.(0) < 0 then raise Not_found else ends.(0)
let matched_string s = String.sub s starts.(0) (ends.(0) - starts.(0))

let group_beginning g =
  if g < 0 || g > 9 then invalid_arg "Str.group_beginning";
  if starts.(g) < 0 then raise Not_found else starts.(g)

let group_end g =
  if g < 0 || g > 9 then invalid_arg "Str.group_end";
  if ends.(g) < 0 then raise Not_found else ends.(g)

let string_before s n = String.sub s 0 n
let string_after s n = String.sub s n (String.length s - n)
let first_chars s n = String.sub s 0 n
let last_chars s n = String.sub s (String.length s - n) n

let opt_search_forward re s pos = try Some (search_forward re s pos) with Not_found -> None

(* A search that must advance: an empty match at [start] is skipped. *)
let opt_search_forward_progress re s start =
  match opt_search_forward re s start with
  | None -> None
  | Some pos ->
      if match_end () > start then Some pos
      else if start < String.length s then opt_search_forward re s (start + 1)
      else None

let replace_matched repl s =
  let b = Buffer.create (String.length repl) in
  let n = String.length repl in
  let rec go i =
    if i < n then
      if repl.[i] = '\\' then begin
        if i + 1 >= n then failwith "Str.replace: illegal backslash sequence";
        (match repl.[i + 1] with
         | '\\' -> Buffer.add_char b '\\'
         | '0' .. '9' as d -> Buffer.add_string b (matched_group (Char.code d - 48) s)
         | _ -> failwith "Str.replace: illegal backslash sequence");
        go (i + 2)
      end
      else (Buffer.add_char b repl.[i]; go (i + 1))
  in
  go 0;
  Buffer.contents b

let global_substitute re f s =
  let n = String.length s in
  let rec replace acc start last_was_empty =
    let startpos = if last_was_empty then start + 1 else start in
    if startpos > n then string_after s start :: acc
    else
      match opt_search_forward re s startpos with
      | None -> string_after s start :: acc
      | Some pos ->
          let end_pos = match_end () in
          let repl_text = f s in
          replace (repl_text :: String.sub s start (pos - start) :: acc) end_pos (end_pos = pos)
  in
  String.concat "" (List.rev (replace [] 0 false))

let global_replace re templ s = global_substitute re (replace_matched templ) s

let substitute_first re f s =
  match opt_search_forward re s 0 with
  | None -> s
  | Some pos -> String.concat "" [ string_before s pos; f s; string_after s (match_end ()) ]

let replace_first re templ s = substitute_first re (replace_matched templ) s

type split_result = Text of string | Delim of string

let bounded_split re s num =
  let start = if string_match re s 0 then match_end () else 0 in
  let rec split acc start n =
    if start >= String.length s then acc
    else if n = 1 then string_after s start :: acc
    else
      match opt_search_forward_progress re s start with
      | None -> string_after s start :: acc
      | Some pos -> split (String.sub s start (pos - start) :: acc) (match_end ()) (n - 1)
  in
  List.rev (split [] start num)

let split re s = bounded_split re s 0

let bounded_split_delim re s num =
  let rec split acc start n =
    if start > String.length s then acc
    else if n = 1 then string_after s start :: acc
    else
      match opt_search_forward_progress re s start with
      | None -> string_after s start :: acc
      | Some pos -> split (String.sub s start (pos - start) :: acc) (match_end ()) (n - 1)
  in
  if s = "" then [] else List.rev (split [] 0 num)

let split_delim re s = bounded_split_delim re s 0

let bounded_full_split re s num =
  let rec split acc start n =
    if start >= String.length s then acc
    else if n = 1 then Text (string_after s start) :: acc
    else
      match opt_search_forward_progress re s start with
      | None -> Text (string_after s start) :: acc
      | Some pos ->
          let d = matched_string s in
          if pos = start then split (Delim d :: acc) (match_end ()) (n - 1)
          else split (Delim d :: Text (String.sub s start (pos - start)) :: acc) (match_end ()) (n - 1)
  in
  List.rev (split [] 0 num)

let full_split re s = bounded_full_split re s 0
