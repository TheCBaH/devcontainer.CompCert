(* Str_impl against the real Str: usage str_props <src-dir>.

   The patterns are every regular expression literal in the sources in
   <src-dir> (found by scanning them, so new ones are picked up), plus random
   patterns from the shim's grammar. The subjects are the lines of those
   sources and random strings over each pattern's own alphabet. For each pair
   the two libraries must agree on every operation CompCert uses: matches at a
   position, searches, partial matches, groups, replacements, substitutions
   and the three splits. *)

let () = Random.init (try int_of_string (Sys.getenv "STR_SEED") with Not_found -> 7)
let failures = ref 0
let checks = ref 0

let read_file p = In_channel.with_open_bin p In_channel.input_all

(* OCaml string literals following "Str.regexp", "Str.regexp_string" or
   "_Regexp": plain "..." or quoted {|...|}. *)
let patterns_in text =
  let n = String.length text in
  let found = ref [] in
  let find_after key =
    let k = String.length key in
    let rec go i =
      match if i + k <= n then Some (String.sub text i k) else None with
      | None -> ()
      | Some s when s = key ->
          let j = ref (i + k) in
          while !j < n && (text.[!j] = ' ' || text.[!j] = '(' || text.[!j] = '\n') do incr j done;
          if !j < n && text.[!j] = '"' then begin
            let e = ref (!j + 1) in
            while !e < n && text.[!e] <> '"' do (if text.[!e] = '\\' then incr e); incr e done;
            (try found := (`Regexp (Scanf.unescaped (String.sub text (!j + 1) (!e - !j - 1)))) :: !found
             with _ -> ())
          end
          else if !j + 1 < n && text.[!j] = '{' && text.[!j + 1] = '|' then begin
            let e = ref (!j + 2) in
            while !e + 1 < n && not (text.[!e] = '|' && text.[!e + 1] = '}') do incr e done;
            found := `Regexp (String.sub text (!j + 2) (!e - !j - 2)) :: !found
          end;
          go (i + 1)
      | _ -> go (i + 1)
    in
    go 0
  in
  find_after "Str.regexp";
  find_after "_Regexp";
  List.rev !found

let literal_strings text =
  (* Str.regexp_string "..." arguments are literal. *)
  let key = "Str.regexp_string " in
  let k = String.length key and n = String.length text in
  let found = ref [] in
  let rec go i =
    if i + k <= n then begin
      if String.sub text i k = key && i + k < n && text.[i + k] = '"' then begin
        let e = ref (i + k + 1) in
        while !e < n && text.[!e] <> '"' do (if text.[!e] = '\\' then incr e); incr e done;
        (try found := Scanf.unescaped (String.sub text (i + k + 1) (!e - i - k - 1)) :: !found with _ -> ())
      end;
      go (i + 1)
    end
  in
  go 0;
  !found

(* Compare one pattern with one subject. [re_a]/[re_b] are the two compiled
   forms. *)
let trace = Sys.getenv_opt "STR_TRACE" <> None

let compare_on name re_a re_b subject =
  if trace then Printf.printf "%S on %S\n%!" name subject;
  let n = String.length subject in
  let fail what =
    incr failures;
    if !failures <= 30 then Printf.printf "MISMATCH %s on %S: %s\n%!" (String.escaped name) (String.escaped subject) what
  in
  let ck what a b = incr checks; if a <> b then fail what in
  let positions = if n = 0 then [ 0 ] else [ 0; n / 2; n ] in
  List.iter
    (fun pos ->
      let ma = Str.string_match re_a subject pos and mb = Str_impl.string_match re_b subject pos in
      ck (Printf.sprintf "string_match@%d" pos) ma mb;
      if ma && mb then begin
        ck "match_end" (Str.match_end ()) (Str_impl.match_end ());
        for g = 0 to 9 do
          ck (Printf.sprintf "group %d" g)
            (try Some (Str.matched_group g subject) with Not_found -> None | Invalid_argument _ -> None)
            (try Some (Str_impl.matched_group g subject) with Not_found -> None | Invalid_argument _ -> None)
        done
      end;
      ck (Printf.sprintf "partial@%d" pos) (Str.string_partial_match re_a subject pos) (Str_impl.string_partial_match re_b subject pos);
      let sa = try Some (Str.search_forward re_a subject pos) with Not_found -> None
      and sb = try Some (Str_impl.search_forward re_b subject pos) with Not_found -> None in
      ck (Printf.sprintf "search_forward@%d" pos) sa sb;
      if sa <> None && sb <> None then begin
        ck "search match_end" (Str.match_end ()) (Str_impl.match_end ());
        for g = 0 to 9 do
          ck (Printf.sprintf "search group %d" g)
            (try Some (Str.matched_group g subject) with Not_found -> None | Invalid_argument _ -> None)
            (try Some (Str_impl.matched_group g subject) with Not_found -> None | Invalid_argument _ -> None)
        done
      end)
    positions;
  ck "global_replace" (Str.global_replace re_a "<\\0>" subject) (Str_impl.global_replace re_b "<\\0>" subject);
  ck "global_substitute"
    (Str.global_substitute re_a (fun s -> "[" ^ Str.matched_string s ^ "]") subject)
    (Str_impl.global_substitute re_b (fun s -> "[" ^ Str_impl.matched_string s ^ "]") subject);
  ck "replace_first" (Str.replace_first re_a "#" subject) (Str_impl.replace_first re_b "#" subject);
  ck "split" (Str.split re_a subject) (Str_impl.split re_b subject);
  ck "split_delim" (Str.split_delim re_a subject) (Str_impl.split_delim re_b subject);
  let conv = List.map (function Str.Text s -> `T s | Str.Delim s -> `D s)
  and conv' = List.map (function Str_impl.Text s -> `T s | Str_impl.Delim s -> `D s) in
  ck "full_split" (conv (Str.full_split re_a subject)) (conv' (Str_impl.full_split re_b subject))

(* Random subjects over the characters a pattern mentions, plus a few
   separators. *)
let alphabet_of pattern =
  let b = Buffer.create 32 in
  String.iter (fun c -> if c <> '\\' && c <> '[' && c <> ']' && c <> '^' && c <> '*' && c <> '+' && c <> '?' && c <> '(' && c <> ')' && c <> '|' then Buffer.add_char b c) pattern;
  Buffer.add_string b "a0 _\n%$";
  Buffer.contents b

let random_subject alphabet =
  String.init (Random.int 10) (fun _ -> alphabet.[Random.int (String.length alphabet)])

(* Random patterns from the grammar. *)
let random_pattern () =
  let atoms = [| "a"; "b"; "."; "[ab]"; "[^a]"; "[a-c0-1]"; "x"; "_"; "%"; " "; "\\b"; "\\1"; "a" |] in
  let rec go depth =
    let one () =
      let a = if depth > 0 && Random.int 4 = 0 then "\\(" ^ go (depth - 1) ^ "\\)" else atoms.(Random.int (Array.length atoms)) in
      match Random.int 6 with 0 -> a ^ "*" | 1 -> a ^ "+" | 2 -> a ^ "?" | _ -> a
    in
    let seq () = String.concat "" (List.init (1 + Random.int 3) (fun _ -> one ())) in
    let s = seq () in
    let s = if Random.int 5 = 0 then "^" ^ s else s in
    let s = if Random.int 5 = 0 then s ^ "$" else s in
    if Random.int 4 = 0 then s ^ "\\|" ^ seq () else s
  in
  go 1

let () =
  let src = Sys.argv.(1) in
  let files = Sys.readdir src |> Array.to_list |> List.filter (fun f -> Filename.check_suffix f ".ml") |> List.sort compare in
  let texts = List.map (fun f -> read_file (Filename.concat src f)) files in
  let pats = List.concat_map patterns_in texts in
  let lits = List.concat_map literal_strings texts in
  let lines = List.concat_map (String.split_on_char '\n') texts in
  let sample_lines = List.filteri (fun i _ -> i mod 61 = 0) lines in
  Printf.printf "%d regexp literals, %d literal strings, %d subject lines\n%!" (List.length pats) (List.length lits) (List.length sample_lines);
  List.iter
    (fun (`Regexp p) ->
      match (try Some (Str.regexp p) with _ -> None) with
      | None -> () (* not valid for Str either: not a pattern *)
      | Some ra ->
          let rb = Str_impl.regexp p in
          let alpha = alphabet_of p in
          List.iter (compare_on p ra rb) sample_lines;
          for _ = 1 to 300 do compare_on p ra rb (random_subject alpha) done)
    pats;
  List.iter
    (fun l ->
      let ra = Str.regexp_string l and rb = Str_impl.regexp_string l in
      List.iter (compare_on ("literal " ^ l) ra rb) (l :: ("x" ^ l ^ "y") :: List.filteri (fun i _ -> i mod 211 = 0) lines))
    lits;
  for _ = 1 to 20000 do
    let p = random_pattern () in
    match (try Some (Str.regexp p) with _ -> None) with
    | None -> ()
    | Some ra ->
        let rb = Str_impl.regexp p in
        for _ = 1 to 10 do compare_on p ra rb (random_subject "ab_x0 \n%") done
  done;
  Printf.printf "%d comparisons, %d mismatches\n" !checks !failures;
  if !failures > 0 then exit 1
