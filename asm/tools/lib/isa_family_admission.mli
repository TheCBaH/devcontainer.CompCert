(** A complete, source-derived family-admission matrix.

    This is deliberately an accounting report, not an optimistic support
    table. Every selected source record belongs to exactly one source-native
    family and exactly one admission state. A normalized form reaches
    [Promoted_support] only when a committed differential case (the
    [isa-generated] pilot or the [isa-difficult] corpus) names that exact
    source record and normalized form and gives it positive support credit; a
    form with positive cases none of which earns credit remains
    [Gas_generatable]. All other successfully normalized forms are
    [Normalized_only]. A normalization diagnostic is preserved as its specific
    [Blocked] rule. Credit is derived from the corpora, never restated. *)

type state =
  | Normalized_only
  | Gas_generatable
  | Promoted_support
  | Oracle_unavailable of string
  | Blocked of string

type tally = {
  normalized_only : int;
  gas_generatable : int;
  promoted_support : int;
  oracle_unavailable : int;
  blocked : (string * int) list;
}

type family = { name : string; total : int; tally : tally }
type summary = { total : int; families : family list }

val summarize : Repo.t -> source:string -> Target.t -> (summary, Tool_error.t) Err.t
(** Read one checked-in export and classify every record. [source] is
    ["riscv_opcodes"] or ["xed_resolved"]. *)

val tally_total : tally -> int
val report_lines : label:string -> summary -> string list
val run : Repo.t -> Command.t
