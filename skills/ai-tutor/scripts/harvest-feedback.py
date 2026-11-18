#!/usr/bin/env python3
"""harvest-feedback.py — deterministic harvester for the ai-tutor feedback ledger.

Sweeps the feedback inbox (one JSON record per file in
``state/feedback-inbox/``) into the ledger (``state/feedback.jsonl``):

- exhaustively — every inbox file is read; there is no cap;
- idempotently — a stable source re-harvested adds zero records;
- as union state — a later empty or shrunk inbox never deletes history;
- loudly — an invalid record is rejected by name, with the reason, and
  is never written; a missing inbox is reported MISSING, never as zero.

Record format: see ``references/feedback-record-schema.json`` beside
this skill. Required: ``id``, ``ts``, ``kind``, ``title``, ``tool``,
``impact`` (blocked | worked_around | friction), ``error``, and a
non-empty ``evidence`` list — a record with no evidence pointer is
rejected, per the skill's standing rule.

Usage:
    harvest-feedback.py [--skill-dir DIR] [--inbox DIR] [--ledger FILE]
    harvest-feedback.py --self-test

Defaults resolve relative to the skill directory (the parent of this
script's ``scripts/`` folder); state directories are scaffolded on
first run. Exit codes: 0 = clean harvest; 2 = one or more records
rejected (valid records are still written); 3 = self-test failure.
"""

import argparse
import json
import sys
import tempfile
from pathlib import Path

IMPACTS = ("blocked", "worked_around", "friction")
REQUIRED_STR = ("id", "ts", "kind", "title", "tool", "error")


def validate(record):
    """Return a list of rejection reasons; empty list means valid."""
    reasons = []
    if not isinstance(record, dict):
        return ["record is not a JSON object"]
    for field in REQUIRED_STR:
        if not isinstance(record.get(field), str) or not record[field].strip():
            reasons.append(f"missing or empty required string field: {field}")
    if record.get("impact") not in IMPACTS:
        reasons.append(
            f"impact must be one of {list(IMPACTS)}, got {record.get('impact')!r}"
        )
    evidence = record.get("evidence")
    if not isinstance(evidence, list) or not evidence:
        reasons.append("evidence must be a non-empty list (no evidence pointer = rejected)")
    return reasons


def load_ledger_ids(ledger_path):
    ids = set()
    if ledger_path.exists():
        for line in ledger_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                ids.add(json.loads(line)["id"])
            except (json.JSONDecodeError, KeyError):
                print(f"WARN: unreadable ledger line skipped: {line[:80]}", file=sys.stderr)
    return ids


def harvest(inbox_dir, ledger_path):
    """Harvest inbox -> ledger. Returns (summary_dict, rejected_list)."""
    summary = {"source": "ok", "added": 0, "duplicates": 0, "rejected": 0, "total": 0}
    rejected = []
    if not inbox_dir.is_dir():
        inbox_dir.mkdir(parents=True, exist_ok=True)
        summary["source"] = "MISSING (scaffolded empty inbox; reported, never read as zero)"
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    known_ids = load_ledger_ids(ledger_path)
    new_records = []
    for path in sorted(inbox_dir.glob("*.json")):
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            rejected.append((path.name, f"invalid JSON: {exc}"))
            continue
        reasons = validate(record)
        if reasons:
            rejected.append((path.name, "; ".join(reasons)))
            continue
        if record["id"] in known_ids:
            summary["duplicates"] += 1
            continue
        known_ids.add(record["id"])
        new_records.append(record)
    new_records.sort(key=lambda r: (r["ts"], r["id"]))
    if new_records:
        with ledger_path.open("a", encoding="utf-8") as fh:
            for record in new_records:
                fh.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
    summary["added"] = len(new_records)
    summary["rejected"] = len(rejected)
    summary["total"] = len(known_ids)
    return summary, rejected


def run_harvest(inbox_dir, ledger_path):
    summary, rejected = harvest(inbox_dir, ledger_path)
    for name, reason in rejected:
        print(f"REJECTED {name}: {reason}", file=sys.stderr)
    print(json.dumps(summary, ensure_ascii=False))
    return 2 if rejected else 0


def self_test():
    """Sabotage validation: planted valid/invalid/duplicate records,
    idempotency, and union state must all behave as the skill claims."""
    failures = []

    def check(label, cond):
        print(f"{'PASS' if cond else 'FAIL'}: {label}")
        if not cond:
            failures.append(label)

    valid_a = {
        "id": "fb-test-a", "ts": "2026-01-01T00:00:00Z", "kind": "tool_failure",
        "title": "Planted valid record A", "tool": "self-test",
        "impact": "blocked", "error": "planted",
        "evidence": [{"pointer": "self-test", "label": "observed"}],
    }
    valid_b = dict(valid_a, id="fb-test-b", title="Planted valid record B")
    no_evidence = dict(valid_a, id="fb-test-c", evidence=[])
    bad_impact = dict(valid_a, id="fb-test-d", impact="catastrophic")

    with tempfile.TemporaryDirectory() as tmp:
        inbox = Path(tmp) / "feedback-inbox"
        ledger = Path(tmp) / "feedback.jsonl"
        inbox.mkdir()
        for name, rec in [("a.json", valid_a), ("b.json", valid_b),
                          ("c.json", no_evidence), ("d.json", bad_impact)]:
            (inbox / name).write_text(json.dumps(rec), encoding="utf-8")

        summary, rejected = harvest(inbox, ledger)
        check("valid records harvested (added == 2)", summary["added"] == 2)
        check("invalid records rejected (rejected == 2)", summary["rejected"] == 2)
        rejected_ids = " ".join(r for _, r in rejected)
        check("no-evidence record rejected for missing evidence", "evidence" in rejected_ids)
        lines = ledger.read_text(encoding="utf-8").strip().splitlines()
        check("ledger holds exactly the 2 valid records", len(lines) == 2)

        summary2, _ = harvest(inbox, ledger)
        check("idempotent: re-harvest adds 0", summary2["added"] == 0 and summary2["duplicates"] == 2)

        (inbox / "b.json").unlink()
        summary3, _ = harvest(inbox, ledger)
        check("union: shrunk inbox never deletes history (total still 2)",
              summary3["total"] == 2 and len(ledger.read_text(encoding="utf-8").strip().splitlines()) == 2)

    print("SELF-TEST:", "ALL PASS" if not failures else f"{len(failures)} FAILURE(S)")
    return 0 if not failures else 3


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    skill_dir = Path(__file__).resolve().parent.parent
    parser.add_argument("--skill-dir", type=Path, default=skill_dir)
    parser.add_argument("--inbox", type=Path, default=None)
    parser.add_argument("--ledger", type=Path, default=None)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    inbox = args.inbox or (args.skill_dir / "state" / "feedback-inbox")
    ledger = args.ledger or (args.skill_dir / "state" / "feedback.jsonl")
    return run_harvest(inbox, ledger)


if __name__ == "__main__":
    sys.exit(main())
