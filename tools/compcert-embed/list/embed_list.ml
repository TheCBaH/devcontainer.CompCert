(* Opened into every module of the embed library (a dune flag, not a source
   edit). The stdlib list functions below recurse once per element on OCaml
   before 5.1, so a long list overflows a small stack. These versions give the
   same results, apply the functions to the elements in the same order and
   raise the same exceptions, in constant stack. Everything else in [List] is
   the stdlib's. *)

let ( @ ) a b = List.rev_append (List.rev a) b

module List = struct
  include Stdlib.List

  let append = ( @ )

  let map f l =
    let rec go acc = function [] -> rev acc | x :: t -> let y = f x in go (y :: acc) t in
    go [] l

  let mapi f l =
    let rec go i acc = function [] -> rev acc | x :: t -> let y = f i x in go (i + 1) (y :: acc) t in
    go 0 [] l

  let map2 f a b =
    let rec go acc a b =
      match (a, b) with
      | [], [] -> rev acc
      | x :: a, y :: b -> let z = f x y in go (z :: acc) a b
      | _ -> invalid_arg "List.map2"
    in
    go [] a b

  let concat ll = rev (fold_left (fun acc l -> rev_append l acc) [] ll)
  let flatten = concat
  let fold_right f l init = fold_left (fun acc x -> f x acc) init (rev l)

  let split l =
    let rec go xs ys = function
      | [] -> (rev xs, rev ys)
      | (x, y) :: t -> go (x :: xs) (y :: ys) t
    in
    go [] [] l

  let combine a b =
    let rec go acc a b =
      match (a, b) with
      | [], [] -> rev acc
      | x :: a, y :: b -> go ((x, y) :: acc) a b
      | _ -> invalid_arg "List.combine"
    in
    go [] a b
end
