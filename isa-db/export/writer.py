"""JSON Lines export: one file per (source, profile), e.g.
`isa-db/export/riscv_opcodes/riscv64.jsonl`, `isa-db/export/xed/x86_64.jsonl`.

Per .ai/isa.md Phase C: checked into git (by explicit user decision,
2026-09-05), mirroring today's asm/fixtures/isa-inventory/*
manifest.txt/summary.txt convention - works fully offline and is diffable,
at the cost of a diff on every upstream bump. Regenerate with
`python3 -m export.regen` from the isa-db/ directory (or `-t isa-db` from
the repo root; see isa-db/README.md).

Each line is one `SourceRecord.to_dict()` (from normalize/model.py),
serialized with `json.dumps(..., sort_keys=True)` for byte-stable diffs,
one line per record, sorted by `record_id` so the file's own line order is
also stable across re-runs regardless of the adapter's internal iteration
order.

Also writes one auxiliary reference file per source that has one -
`export/riscv_opcodes/arg-lut.jsonl` (.ai/isa.md Phase A step 5) - which
isn't a per-instruction source record at all (no `record_id`), so it is
sorted by its own `name` field instead.
"""

from __future__ import annotations

import json
from pathlib import Path

from adapters.riscv_opcodes import reader as riscv_opcodes_reader
from adapters.riscv_opcodes import reference as riscv_opcodes_reference
from adapters.xed import reader as xed_reader

REPO_ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = REPO_ROOT / "isa-db" / "sources.lock.json"
EXPORT_DIR = Path(__file__).resolve().parent

PROFILES: dict[str, list[str]] = {
    "xed": ["x86_32", "x86_64"],
    "riscv_opcodes": ["riscv32", "riscv64"],
}


def load_lock() -> dict:
    return json.loads(LOCK_PATH.read_text(encoding="utf-8"))


def snapshot_for(source: str, lock: dict) -> str:
    return f"{source}@{lock['sources'][source]['commit']}"


_ADAPTER_SUBDIR = {
    "xed": "datafiles",
    "riscv_opcodes": "extensions",
}


def _source_dir(source: str, lock: dict) -> Path:
    return REPO_ROOT / lock["sources"][source]["path"] / _ADAPTER_SUBDIR[source]


def records_for(source: str, profile: str, lock: dict) -> list[dict]:
    snapshot = snapshot_for(source, lock)
    source_dir = _source_dir(source, lock)
    if source == "xed":
        return xed_reader.source_records_for_profile(source_dir, profile, snapshot)
    if source == "riscv_opcodes":
        return riscv_opcodes_reader.source_records_for_profile(source_dir, profile, snapshot)
    raise ValueError(f"unknown source: {source!r}")


# Sources with an auxiliary reference export beyond their per-profile source
# records - see reference_records_for.
REFERENCE_SOURCES: list[str] = ["riscv_opcodes"]


def reference_records_for(source: str, lock: dict) -> list[dict]:
    if source == "riscv_opcodes":
        snapshot = snapshot_for(source, lock)
        extensions_dir = _source_dir(source, lock)
        return [
            {"source": source, "snapshot": snapshot, **entry}
            for entry in riscv_opcodes_reference.operand_vocab(extensions_dir)
        ]
    raise ValueError(f"no reference export defined for source: {source!r}")


def write_jsonl(records: list[dict], path: Path, *, key=lambda r: r["record_id"]) -> None:
    ordered = sorted(records, key=key)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for rec in ordered:
            f.write(json.dumps(rec, sort_keys=True))
            f.write("\n")


def regenerate(out_dir: Path = EXPORT_DIR) -> list[Path]:
    lock = load_lock()
    written = []
    for source, profiles in PROFILES.items():
        for profile in profiles:
            path = out_dir / source / f"{profile}.jsonl"
            write_jsonl(records_for(source, profile, lock), path)
            written.append(path)
    for source in REFERENCE_SOURCES:
        path = out_dir / source / "arg-lut.jsonl"
        write_jsonl(reference_records_for(source, lock), path, key=lambda r: r["name"])
        written.append(path)
    return written
