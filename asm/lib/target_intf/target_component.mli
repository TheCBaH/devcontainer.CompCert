(** Descriptors for a target family's separable instruction components.

    A component is an implementation boundary - a group of forms one module owns, such as RISC-V M
    or x86 x87. A feature is the architectural predicate that gates it. The two are related many to
    many in general; a descriptor records the one feature name a component is gated by today and
    leaves the feature vocabulary to the configuration layer.

    Descriptors are pure data. They carry no encoder: the family builds its codec alternatives from
    the same tables the descriptor is derived from, so the descriptor and the codec cannot drift
    apart, and {!check} catches the remaining ways two components can collide. *)

type source = { upstream : string; name : string }
(** One upstream record a form is known to correspond to: [upstream] names the ISA source (for
    example ["xed"] or ["riscv-opcodes"]) and [name] that source's own record identifier. The
    mapping is one to many by design: a single encoding can be described by several records, and
    one record can describe several spellings. *)

type form = {
  label : string;  (** the codec alternative's label, which is the stable [form_id] prefix *)
  mnemonics : string list;  (** the source spellings the form accepts *)
  sources : source list;
}

type t = {
  id : string;  (** stable, dot-separated component identity, for example ["riscv.m"] *)
  feature : string;  (** the feature name that gates this component *)
  summary : string;
  forms : form list;
}

val labels : t -> string list
val mnemonics : t -> string list

val owns_mnemonic : t -> string -> bool
(** Whether the component accepts [mnemonic] as a spelling of one of its forms. *)

val check : t list -> string list
(** Structural problems across a set of components composed into one family: duplicate component
    ids, duplicate labels, a mnemonic claimed by two components, a component or form with nothing
    in it, and a form with no source mapping. Empty means clean. It says nothing about whether the
    forms encode correctly - that is the codec and differential tests' job. *)
