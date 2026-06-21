#!/usr/bin/env python3
"""Extract a catalog of public functions from a Python codebase, for semantic
duplicate-intent analysis.

Uses the `ast` module (robust — no regex guessing). Captures public functions and
their signatures/docstrings; excludes tests and private helpers by default.

Usage:
    python extract_functions.py src/ -o catalog.json
    python extract_functions.py src/ --include-private --include-tests

Ported from obra/superpowers-lab (MIT) to Python for agentkit.
"""
from __future__ import annotations

import argparse
import ast
import json
import sys
from pathlib import Path


def _is_test_file(path: Path) -> bool:
    return path.name.startswith("test_") or path.name.endswith("_test.py") or path.name == "conftest.py"


def extract_file(path: Path, *, include_private: bool) -> list[dict]:
    """Return one record per top-level/public function in `path`."""
    try:
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    except (SyntaxError, UnicodeDecodeError) as exc:  # skip unparseable files, don't crash the run
        print(f"warning: skipping {path}: {exc}", file=sys.stderr)
        return []

    records: list[dict] = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if not include_private and node.name.startswith("_"):
            continue
        records.append(
            {
                "name": node.name,
                "file": str(path),
                "line": node.lineno,
                "is_async": isinstance(node, ast.AsyncFunctionDef),
                "args": [a.arg for a in node.args.args],
                "returns": ast.unparse(node.returns) if node.returns is not None else None,
                "doc": (ast.get_docstring(node) or "").strip(),
            }
        )
    return records


def extract_tree(root: Path, *, include_private: bool, include_tests: bool) -> list[dict]:
    catalog: list[dict] = []
    for path in sorted(root.rglob("*.py")):
        if not include_tests and _is_test_file(path):
            continue
        catalog.extend(extract_file(path, include_private=include_private))
    return catalog


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("root", type=Path, help="directory to scan")
    parser.add_argument("-o", "--output", type=Path, default=None, help="output file (default: stdout)")
    parser.add_argument("--include-private", action="store_true", help="include _-prefixed functions")
    parser.add_argument("--include-tests", action="store_true", help="include test files")
    args = parser.parse_args(argv)

    if not args.root.is_dir():
        parser.error(f"not a directory: {args.root}")

    catalog = extract_tree(
        args.root, include_private=args.include_private, include_tests=args.include_tests
    )
    payload = json.dumps(catalog, indent=2, ensure_ascii=False)

    if args.output is not None:
        args.output.write_text(payload + "\n", encoding="utf-8")
        print(f"wrote {len(catalog)} functions to {args.output}", file=sys.stderr)
    else:
        print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
