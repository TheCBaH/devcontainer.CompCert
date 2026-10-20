(* A preprocessor for the Melange build: evaluate arguments in the order
   ocamlopt does.

   OCaml leaves the evaluation order of the arguments of a function, of the
   fields of a tuple, constructor or record, and of array elements
   unspecified. ocamlopt and the bytecode compiler (so js_of_ocaml) evaluate
   them right to left; Melange emits JavaScript, which goes left to right.
   CompCert's output depends on the order (fresh names and numbers are drawn
   from counters), so each such expression with two or more arguments that can
   have effects is rewritten

       f a b          let v_b = b in let v_a = a in f v_a v_b

   Arguments that cannot have an effect (variables, constants, [function]
   expressions, and constructors or tuples of those) are left in place. A [fun]
   is one of these only where the AST has no separate [Pexp_fun] (ppxlib 0.36+);
   elsewhere it is bound like any other argument, which changes nothing. The function in an
   application is evaluated after its arguments, as ocamlopt does.

   Records are ordered by the order their fields are written, which is the order
   of their declaration in CompCert's sources, and [{ r with ... }] evaluates
   [r] first. [&&], [||], [|>] and [@@] are not touched. *)

open Ppxlib
open Ast_builder.Default

let rec simple e =
  match e.pexp_desc with
  | Pexp_ident _ | Pexp_constant _ | Pexp_function _ | Pexp_lazy _ -> true
  | Pexp_construct (_, None) | Pexp_variant (_, None) -> true
  | Pexp_construct (_, Some a) | Pexp_variant (_, Some a) -> simple a
  | Pexp_tuple l -> List.for_all simple l
  | Pexp_constraint (e, _) | Pexp_coerce (e, _, _) -> simple e
  | _ -> false

let counter = ref 0

let fresh loc =
  incr counter;
  (evar ~loc (Printf.sprintf "__eo%d" !counter), pvar ~loc (Printf.sprintf "__eo%d" !counter))

(* [reorder ~loc operands rebuild]: [operands] are in source order and are
   evaluated from the right. The non-simple ones are bound to variables, the
   rightmost outermost, and [rebuild] puts the (variables for the) operands
   back. *)
let reorder ~loc (operands : expression list) (rebuild : expression list -> expression) =
  let nonsimple = List.length (List.filter (fun e -> not (simple e)) operands) in
  if nonsimple < 2 then rebuild operands
  else begin
    let used = ref [] and bindings = ref [] in
    List.iter
      (fun e ->
        if simple e then used := e :: !used
        else begin
          let v, p = fresh loc in
          bindings := (p, e) :: !bindings;
          used := v :: !used
        end)
      (List.rev operands);
    (* [!bindings] starts with the leftmost binding, which must be innermost *)
    List.fold_left
      (fun body (p, e) -> pexp_let ~loc Nonrecursive [ value_binding ~loc ~pat:p ~expr:e ] body)
      (rebuild !used) !bindings
  end

let skip_ops = [ "&&"; "||"; "|>"; "@@"; "&"; "or" ]

let mapper =
  object (self)
    inherit Ast_traverse.map as super

    method! expression e =
      match e.pexp_desc with
      | Pexp_construct (lid, Some ({ pexp_desc = Pexp_tuple l; _ } as t)) ->
          (* the arguments of a constructor must stay a syntactic tuple *)
          let l = List.map self#expression l in
          let loc = e.pexp_loc in
          reorder ~loc l (fun l' ->
              { e with pexp_desc = Pexp_construct (lid, Some { t with pexp_desc = Pexp_tuple l' }) })
      | _ -> (
          let e = super#expression e in
          let loc = e.pexp_loc in
          match e.pexp_desc with
          | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident op; _ }; _ }, _) when List.mem op skip_ops -> e
          | Pexp_apply (f, args) ->
              (* arguments right to left, the function last *)
              reorder ~loc (f :: List.map snd args) (function
                | f' :: args' ->
                    { e with pexp_desc = Pexp_apply (f', List.map2 (fun (l, _) a -> (l, a)) args args') }
                | [] -> assert false)
          | Pexp_tuple l -> reorder ~loc l (fun l' -> { e with pexp_desc = Pexp_tuple l' })
          | Pexp_array l -> reorder ~loc l (fun l' -> { e with pexp_desc = Pexp_array l' })
          | Pexp_record (fields, base) -> (
              let rebuild b es =
                { e with pexp_desc = Pexp_record (List.map2 (fun (l, _) x -> (l, x)) fields es, b) }
              in
              match base with
              | None -> reorder ~loc (List.map snd fields) (rebuild None)
              | Some b when simple b -> reorder ~loc (List.map snd fields) (rebuild (Some b))
              | Some b ->
                  (* the base is evaluated before the fields *)
                  let v, p = fresh loc in
                  pexp_let ~loc Nonrecursive
                    [ value_binding ~loc ~pat:p ~expr:b ]
                    (reorder ~loc (List.map snd fields) (rebuild (Some v))))
          | _ -> e)
  end

let () = Driver.register_transformation "compcert_evalorder" ~impl:(fun str -> mapper#structure str)
