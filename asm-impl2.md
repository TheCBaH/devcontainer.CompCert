# Review of Milestone 2 Implementation Plan, Revision 9

Reviewed: `~/.claude/plans/create-implementation-plan-for-abundant-hopper.md`

## Verdict

**Approved for implementation.** Revision 9 resolves the final canonical round-trip blocker, and no implementation-blocking contradiction remains in the plan.

The plan is now sufficiently explicit about fixture discovery, codec semantics, symbolic fixups, relaxation, target-specific relocation behavior, multiple sections, address binding, execution, differential evidence, and the architecture-erased API to begin M2.A.

## Resolution verification

### Canonical branch round trips are now closed

B10 now pins every decoded x86 branch backed by `Codec.Relax`, including the short rung. This preserves the exact form across the text boundary:

- decoded rel8 → condition-specific `.d8` spelling → symbolic pinned rel8 → fixed rel8 form with a fixup;
- decoded rel32 → condition-specific `.d32` spelling → symbolic pinned rel32 → fixed rel32 form with a fixup.

This is the correct solution for the two-stage image model: the absolute target printed by disassembly no longer needs plan-time section identity or a known segment base to reproduce the encoding. The required nonzero-base whole-text tests cover the failure mode directly.

### The codec contract is implementable from one source of encoding truth

`Codec.Relax`, `encode_ladder`, and `encode_rung` now have distinct responsibilities. The target dispatches among unpinned symbolic, pinned symbolic, and resolved operands without requiring the generic codec to infer target operand state. Rung ordering, nesting, pattern ambiguity, structural inspection, form IDs, and unknown/inapplicable rung diagnostics are specified and tested.

### Fixup and relocation data survive the required boundaries

Fixup kinds use explicit equality; diagnostic names are no longer identity. The finite AArch64 access-size type closes the earlier unbounded-domain issue. `Symbolic_ref` and `Non_normalizable` observations represent their respective cases honestly, while O1 receives only the classifiable payload and uses a checked-in, keyed-multiset oracle.

### Layout and execution gates are coherent

The relaxation loop terminates, verifies its final choices, and no longer claims unproved minimality. Per-profile addresses come from `Abi`, multi-segment manifests exercise writable data, entry selection crosses `DRIVER` and both JavaScript adapters, and every execution fixture has a zero-argument deterministic result of 42.

## Non-blocking implementation notes

1. B6 still uses the shorthand `T.encode (Symbolic e)` once after defining the record-shaped symbolic constructor. Change it to `Symbolic { value; rung }` while editing the contract so the prose and type remain mechanically aligned.
2. The plan says an unsupported `.d*` suffix produces `codec.unknown-rung` “at parse time.” Either reject the suffix in the target parser with a parse/target diagnostic, or carry it to `Codec.encode_rung` and emit `codec.unknown-rung` there. Freeze one phase in the negative test so diagnostics do not drift during implementation.

Neither note changes the design or blocks M2.A.

## Acceptance recommendation

Proceed with M2.A exactly as staged: generate and review the 20 target fixtures, commit the measured inventories and relocation-class artifacts, then rewrite the provisional M2.E–M2.I form lists from those artifacts before implementing the codec and image changes. Preserve each slice's stated regression, differential, portability, and execution gates as it lands.
