# err_trace: a review from one integration

Written after migrating `asm/` — a retargetable assembler, ~30k lines of OCaml
across 22 libraries — from string-built diagnostics to typed error domains
wrapped in err_trace. Thirteen commits, every error-producing module converted,
no committed baseline moved. Pinned at `ff50f853` (`origin/main`).

This is a report from one consumer, not a survey. That consumer is compiler-
shaped, which biases what looks essential and what looks like weight: the
findings below are worth reading with that in mind, and I've tried to mark where
a judgement is about *this* codebase rather than about the library.

The headline: **the core abstraction is right and it did the job.** A typed
payload plus an out-of-band bounded origin is exactly the shape a compiler wants,
and keeping the payload application-owned meant the migration could be
mechanical and baseline-preserving. Nothing about the design fought back. What
follows is mostly about ergonomics at scale and about surface that one consumer
never touched.

---

## What it was used for

Concrete usage counts from the finished tree, so the rest of this review is
anchored rather than impressionistic:

| API | Uses | Note |
|---|---:|---|
| `Err.Error.kind` | 36 | by a wide margin the most-called function |
| `Err.t` | 14 | in signatures |
| `Err.fail` | 12 | |
| `Err.Error.make` | 6 | where a bare wrapper, not a result, was needed |
| `Err.map_error` | 5 | domain crossings |
| `Err.or_raise` | 3 | the `*_exn` companions |
| `Err.protect` | 2 | the Menhir exception boundary |
| `Err.mark_error` | 1 | the phase trail |
| `Err.Syntax` | 1 | |
| `Err.Monitor` / `Observation.pp` | 1 | the CLI tracing switch |

Fifteen error domains were built on it, from `Bigint.error` (8 constructors) up
to `Image.link_error`/`bind_error` (21 between them).

---

## Missing

### 1. No way to bind `pp_error` once per domain

This is the finding I'd act on first.

Every failure-producing entry point — `fail`, `map_error`, `mark_error`,
`Error.make`, `Error.pp`, `protect`, `or_raise`, `to_exn` — takes `~pp_error`.
But a domain has exactly one printer, always. The consequence:
**13 of the tree's modules define a private wrapper whose entire purpose is to
bind that one argument**, and `~pp_error` is still written 23 times.

```ocaml
(* repeated, with the printer changed, in thirteen files *)
let fail ?pos e = Err.fail ?pos ~pp_error e
let diag ?pos ?origin kind = Err.Error.make ?pos ~pp_error (Target_error.make ~origin kind)
```

That is a library asking every consumer to write the same adapter. A first-class
domain would remove it — either a functor:

```ocaml
module Make (D : sig type t val pp : Format.formatter -> t -> unit end) : sig
  val fail : ?pos:Source.pos -> D.t -> ('a, D.t) Err.t
  val map_error : ?pos:Source.pos -> ('e -> D.t) -> ('a, 'e) Err.t -> ('a, D.t) Err.t
  (* ... *)
end
```

or a plain record passed once (`Err.domain ~pp:... |> fun d -> Err.fail d e`),
which composes better with polymorphic-variant rows than a functor does, since
domains here extend each other by inclusion.

The current design presumably keeps `pp_error` per-call so that the *destination*
printer is supplied at a `Map` boundary — a genuinely good rule, and one the
docs are right to emphasise. A functor or record doesn't break it: the
destination's module is what you call `map_error` on.

### 2. `Error.kind` is the most-used function and always appears inside a wrapper

36 uses, and nearly every one is one of two shapes:

```ocaml
Result.map_error Err.Error.kind r                        (* drop provenance *)
Fmt.to_to_string D.pp_error (Err.Error.kind e)           (* render the payload *)
```

There is no `('a, 'e) Err.t -> ('a, 'e) result`. Given that every erasure
boundary, every test assertion and every render-the-payload site needs it, it
belongs in the library:

```ocaml
val payload : ('a, 'e) t -> ('a, 'e) result   (* strip the wrapper *)
val pp_kind : (Format.formatter -> 'e -> unit) -> Format.formatter -> 'e Error.t -> unit
```

The second already exists for exceptions (`Exn.pp_kind`) and is documented with
exactly the right rationale — "at a boundary that must not emit provenance". The
same need arises for `Error.t`, far more often, and isn't served.

### 3. Nothing for accumulating errors

The library is entirely short-circuit: `bind`, `Syntax.let*`, and `List.map`/
`iter`/`fold_left` all stop at the first failure.

A compiler's dominant pattern is the opposite. Every pass in this tree collects
*all* failures for a translation unit and reports them together — a user wants
every bad instruction in the file, not the first. Five passes do this, and all
five use a hand-rolled `errors := e :: !errors` accumulator that err_trace has
no vocabulary for. The result is that the library's most idiomatic combinators
went unused (`Err.List.*`: zero uses) while the actual control flow was written
by hand.

A validation-style traversal would close it:

```ocaml
val all : ('a -> ('b, 'e) t) -> 'a list -> ('b list, 'e list) t
```

This is the single largest gap for the compiler/linter shape, and I'd guess for
any batch-processing consumer.

### 4. `Config.pp_backtrace` and `Config.of_strings` do not round-trip

A reproducible bug, not a preference. `pp_backtrace` prints `Never` as `"never"`;
`of_strings` accepts only `"off"`:

```
pp_backtrace prints: "never"
of_strings REJECTS its own output: unknown backtrace mode "never" (expected off, origin, or events)
```

So printing a policy and feeding it back — the obvious thing for a tool that
logs its configuration, or a test that pins one — fails. I hit this writing the
CLI switch and had to discover the spelling from the error message.

The vocabularies also disagree across axes: `trace` uses `off | boundaries |
all`, `backtrace` uses `off | origin | events`, and the constructor is `Never`.
Three names for the disabled state.

### 5. `Config.fast` is a trap for the case it looks made for

`fast` reads as *the* production preset, and the README presents it that way
("no events, no automatic stacks"). What it actually does is
`actions = Action.Set.empty` — which disables the **entire semantic event
trail**, not just stacks.

I nearly shipped it as this project's default. It would have silently discarded
the `parse → simplify → lower → bind` trail, which is a headline feature, while
appearing to be the recommended choice. What almost every production consumer
wants is *no automatic stack capture, but keep the trail*:

```ocaml
Err.Config.make ~actions:Err.Action.Set.boundaries ~backtrace:Never
  ~max_events:32 ~max_frames:0 ~max_external_bytes:0
```

That is nine lines of policy that every deterministic consumer will write
identically. It should be a named preset — `deterministic`, say — and `fast`
should be documented as "no provenance at all", because that is what it is.

Related: the two nondeterminism sources are independent (actions, and backtrace
capture) but the presets only offer them as a bundled ladder
`fast | default | debug`. The useful axis is *stacks on/off*, orthogonal to
*how much trail*.

### 6. No notion of a machine-readable error class

`pp_error` gives a human string. Every real reporter also needs a stable
identifier — a diagnostic code — for filtering, for documentation, and for tests
that assert *which* failure occurred without matching prose.

The library has no opinion here, so this project invented `code : t -> string`
in all fifteen domains, plus a cross-domain uniqueness test, plus a rule about
which layer owns the code when one domain wraps another. That last rule was the
subtlest part of the whole migration and it is entirely outside err_trace.

I'm least confident this belongs in the library — it is arguably an application
concern, and a wrong abstraction here would be worse than none. But every
consumer that renders errors to users will build it, so it's worth a documented
pattern even if not an API.

### 7. `~pos:__POS__` at every site

Explicit, PPX-free positions are a deliberate and well-argued choice — they're
why this works under Melange, which is why this project could adopt it at all.
The cost is real all the same: `~pos:__POS__` appears at every failure site, and
it is the kind of boilerplate that gets omitted under deadline, silently
degrading provenance rather than failing.

Not a defect, and I wouldn't trade it for a PPX. But an optional PPX for
consumers who can afford it (native-only) would serve both audiences, and the
README could say plainly that omitting `~pos` under `backtrace:Never` yields
*no origin at all* — which is the failure mode, and is easy to miss.

---

## Superfluous

Weight for *this* consumer. Some of it clearly earns its place elsewhere, and
I've said so where I think that.

### Genuinely unused, and I'd question it in the library

**External stack import.** `Stack.of_external ~runtime ~stack`,
`Stack.is_available`, `Config.max_external_bytes`, the truncation flag, and a
whole constructor in `Stack.t` exist to import a foreign runtime's stack string
and bound it. This project set the bound to `0` and never called any of it.

That is a lot of surface — it widens the core `Stack.t` type that every consumer
sees — for one narrow scenario (a JS host handing you its stack). I'd expect it
to pay for itself in a browser-facing app; in a library or a CLI it is pure
weight, and it complicates `Stack.t` for everyone.

**Three of seven actions.** `Detect`, `Map`, `Catch` and `Raise` all fired.
`Filter`, `Import` and `Export` never did. `Import`/`Export` pair with the
external-stack and exception-boundary features above. `Filter` I could not find
a use for and the docs don't motivate it.

Seven actions is also enough that `Action.Set.boundaries` ("all except
`Detect`") is doing real work as a shorthand — but the name suggests "the
boundary actions", which reads as though it *includes* detection. `all_but_detect`
would be unambiguous.

### Fine to keep; simply not my shape

**`Err.List.map` / `iter` / `fold_left`.** Zero uses, because this codebase
accumulates rather than short-circuits (§3). Stack-safety is a real property and
these are cheap; the gap isn't that they exist, it's that the accumulating
counterpart doesn't.

**Most of the exception boundary.** I used `or_raise` (3×) and matched `Exn.E`
once. `to_exn`, `export_exn`, `raise_error`, `Exn.pp`, `Exn.pp_kind` and the
`packed` existential went untouched — six exports for a boundary that, in
practice, needed one function. Justified for interop with code that must raise,
but it is the largest cluster of API per unit of use that I saw.

**`Error.make_at`**, **`Config.debug`**, **`Error.dropped_events`**,
**`Source.pp_pos`**, **`Origin.make`**: unused. All small, all plausibly needed
by someone. `dropped_events` in particular is the right design — a saturating
counter beats silently losing events — it just never triggered at
`max_events:32`.

**`Err.of_option` / `map_none` / `guard` / `map` / `bind` / `return`.** Unused
here because every conversion went through a domain wrapper (§1), so the
plain-result combinators were never the shortest path. With §1 fixed I'd expect
to use them.

---

## What worked, unqualified

Worth stating explicitly, because a review that only lists complaints
misrepresents the experience.

- **Payload ownership.** Domain errors stayed ordinary polymorphic variants.
  That is what let 160 failure sites be retyped without changing a rendered
  character, and it is the single decision the whole migration rested on.
- **Portability.** Native, js_of_ocaml and Melange, byte-identical, first try.
  No `external`, no C, no `Unix` — it passed a purity audit whose external
  allowlist is empty by design. For a project that bans C-backed dependencies
  outright, this was the difference between adopting and not.
- **`Err.protect`.** Replacing a bare `try … with Grammar.Error` gave a named
  absorbable exception, re-raise of everything else, and a recorded `Catch` — a
  strict improvement at the one place a foreign failure entered the domain.
- **`Observation.pp`.** The `detected at:` / `trace:` layout was usable
  verbatim for a CLI tracing switch. No formatting work needed.
- **`Err.Error.map_kind` / `map_error` semantics.** Not retaining the previous
  payload or printer across a `Map` is the right call, and the docs explain it
  well enough that I designed the wrapping rules around it rather than
  discovering them.
- **Config as process state, not environment.** `of_strings` taking explicit
  strings instead of reading `getenv` is what made the CLI switch a property of
  the command line. A library that read the environment would have been rejected
  by this project's determinism rules.

---

## Summary

**Fix first:** the printer-per-call boilerplate (§1), the missing `payload`
unwrap (§2), and the `pp_backtrace`/`of_strings` round-trip bug (§4). The first
two are the difference between "works" and "pleasant at scale"; the third is a
plain defect.

**Consider:** an accumulating traversal (§3) and a `deterministic` preset (§5).
Both are small additions that a large class of consumers will otherwise
hand-roll identically.

**Consider trimming:** external stack import and its three attendant actions
(§Superfluous) — or documenting them as a browser-host feature so other
consumers know to ignore them. The exception-boundary cluster could shrink to
`or_raise` plus `Exn.E` without much loss.

**Don't change:** the payload-ownership model, PPX-free positions, config as
explicit process state, and the `Map`-drops-payload rule. Those are the reasons
this integration was possible.
