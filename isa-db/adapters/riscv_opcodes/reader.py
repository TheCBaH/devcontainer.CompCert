"""riscv-opcodes extensions/ adapter: per-line source records plus a compat view.

Mirrors asm/tools/lib/isa_inventory_riscv.ml's selection policy exactly
(ratified only, `rv_`/`rv32_`/`rv64_`-prefixed files) so that
`compat_entries_for_profile` can be regression-tested directly against the
checked-in asm/fixtures/isa-inventory/{riscv32,riscv64} manifests. Source
records go further: `$import` and `$pseudo_op` lines become explicit typed
relationships (`imports` / `specializes`) instead of being folded into a
plain mnemonic ($import) or reduced to just their own name ($pseudo_op) -
see .ai/isa-database-design.md's point that "those choices define its
actual coverage boundary; they should be explicit selection policy in a
future database rather than disappear during normalization."
"""

from __future__ import annotations

import re
from pathlib import Path

from normalize.model import SourceRecord, fixed_bits_encoding, opaque_encoding, unconditional

_FIELD_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?=(0x[0-9a-fA-F]+|\d+)$")


def tokens(line: str) -> list[str]:
    parts: list[str] = []
    for chunk in line.split(" "):
        parts.extend(chunk.split("\t"))
    return [p for p in parts if p != ""]


def parse_fields(toks: list[str]) -> tuple[list[dict], list[str], int, int]:
    """Split trailing tokens into (bit-field specs, operand names, mask, value).

    Width is assumed to be 32 bits - true for every extension this slice's
    tests exercise, but not derived from the data, so a genuinely 16-bit
    compressed encoding would silently get a 32-bit mask/value here. See
    the caller's `unresolved` note for extensions whose name suggests that.
    """
    fields = []
    operands = []
    mask = 0
    value = 0
    for tok in toks:
        m = _FIELD_RE.match(tok)
        if m is None:
            operands.append(tok)
            continue
        hi = int(m.group(1))
        lo = int(m.group(2)) if m.group(2) is not None else hi
        raw = m.group(3)
        v = int(raw, 16) if raw.startswith("0x") else int(raw)
        width = hi - lo + 1
        field_mask = ((1 << width) - 1) << lo
        field_val = (v & ((1 << width) - 1)) << lo
        fields.append({"name": f"bits[{hi}:{lo}]", "lsb": lo, "width": width})
        mask |= field_mask
        value |= field_val
    return fields, operands, mask, value


def _list_extension_files(extensions_dir: Path) -> list[Path]:
    return sorted(
        p
        for p in extensions_dir.iterdir()
        if p.is_file() and p.name != "unratified"
    )


def _applies_to(profile: str, extension: str) -> bool:
    if profile == "riscv32":
        return extension.startswith("rv_") or extension.startswith("rv32_")
    if profile == "riscv64":
        return extension.startswith("rv_") or extension.startswith("rv64_")
    raise ValueError(f"unsupported profile: {profile!r}")


def source_records_for_file(path: Path, snapshot: str) -> list[dict]:
    extension = path.name
    width_note = (
        [f"width_bits assumed 32 but {extension!r} looks like a compressed (16-bit) extension"]
        if "_c" in extension.split("_")
        else []
    )
    records = []
    for lineno, raw_line in enumerate(path.read_text(encoding="utf-8", errors="replace").split("\n"), start=1):
        trimmed = raw_line.strip()
        if trimmed == "" or trimmed.startswith("#"):
            continue
        toks = tokens(trimmed)
        if not toks:
            continue
        origin = {"path": f"extensions/{extension}", "line": lineno}

        if toks[0] == "$import":
            target_ext, _, target_name = toks[1].partition("::")
            rec = SourceRecord(
                record_id=f"riscv-opcodes:{extension}:{target_name}@L{lineno}",
                source="riscv_opcodes",
                kind="import",
                native_name=target_name,
                snapshot=snapshot,
                origin=origin,
                encoding=opaque_encoding("import - no local encoding, see relationships"),
                applicability=unconditional(),
                relationships=[{"kind": "imports", "target": f"riscv-opcodes:{target_ext}:{target_name}"}],
                provenance={"extension": extension},
                unresolved=["import target not resolved to a concrete record_id by this adapter"],
            )
            records.append(rec.to_dict())
            continue

        if toks[0] == "$pseudo_op":
            if len(toks) < 3:
                raise ValueError(f"{path}:{lineno}: malformed $pseudo_op line: {raw_line!r}")
            base_ref, mnemonic = toks[1], toks[2]
            base_ext, _, base_name = base_ref.partition("::")
            fields, operands, mask, value = parse_fields(toks[3:])
            rec = SourceRecord(
                record_id=f"riscv-opcodes:{extension}:{mnemonic}@L{lineno}",
                source="riscv_opcodes",
                kind="pseudo-op",
                native_name=mnemonic,
                snapshot=snapshot,
                origin=origin,
                encoding=fixed_bits_encoding(32, mask, value, fields),
                applicability=unconditional(),
                relationships=[{"kind": "specializes", "target": f"riscv-opcodes:{base_ext}:{base_name}"}],
                provenance={"extension": extension, "operands": operands},
                unresolved=["specializes-target not resolved to a concrete record_id by this adapter"] + width_note,
            )
            records.append(rec.to_dict())
            continue

        mnemonic = toks[0]
        fields, operands, mask, value = parse_fields(toks[1:])
        rec = SourceRecord(
            record_id=f"riscv-opcodes:{extension}:{mnemonic}@L{lineno}",
            source="riscv_opcodes",
            kind="instruction-form",
            native_name=mnemonic,
            snapshot=snapshot,
            origin=origin,
            encoding=fixed_bits_encoding(32, mask, value, fields),
            applicability=unconditional(),
            provenance={"extension": extension, "operands": operands},
            unresolved=list(width_note),
        )
        records.append(rec.to_dict())
    return records


def source_records(extensions_dir: Path, snapshot: str) -> list[dict]:
    records = []
    for f in _list_extension_files(extensions_dir):
        records.extend(source_records_for_file(f, snapshot))
    return records


def compat_entries_for_profile(extensions_dir: Path, profile: str) -> set[tuple[str, str]]:
    entries: set[tuple[str, str]] = set()
    for f in _list_extension_files(extensions_dir):
        if not _applies_to(profile, f.name):
            continue
        for raw_line in f.read_text(encoding="utf-8", errors="replace").split("\n"):
            trimmed = raw_line.strip()
            if trimmed == "" or trimmed.startswith("#"):
                continue
            toks = tokens(trimmed)
            if not toks:
                continue
            if toks[0] == "$import":
                continue
            if toks[0] == "$pseudo_op":
                if len(toks) < 3:
                    raise ValueError(f"{f}: malformed $pseudo_op line: {raw_line!r}")
                mnemonic = toks[2]
            else:
                mnemonic = toks[0]
            entries.add((mnemonic, f.name))
    return entries
