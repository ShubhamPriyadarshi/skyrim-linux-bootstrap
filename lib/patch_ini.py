#!/usr/bin/env python3
"""Small, formatting-preserving INI patcher used by the bootstrapper."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def patch_ini(path: Path, section: str, updates: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8-sig")
    newline = "\r\n" if "\r\n" in text else "\n"
    lines = text.splitlines()
    section_re = re.compile(r"^\s*\[([^]]+)]\s*$")
    current: str | None = None
    section_start: int | None = None
    section_end = len(lines)

    for index, line in enumerate(lines):
        match = section_re.match(line)
        if not match:
            continue
        name = match.group(1)
        if current == section and section_end == len(lines):
            section_end = index
            break
        current = name
        if name == section:
            section_start = index

    if section_start is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines.extend([f"[{section}]", *[f"{key}={value}" for key, value in updates.items()]])
    else:
        found: set[str] = set()
        key_patterns = {
            key: re.compile(rf"^\s*#?\s*{re.escape(key)}\s*=", re.IGNORECASE)
            for key in updates
        }
        for index in range(section_start + 1, section_end):
            for key, pattern in key_patterns.items():
                if pattern.match(lines[index]):
                    lines[index] = f"{key}={updates[key]}"
                    found.add(key)
                    break
        insert_at = section_end
        for key, value in updates.items():
            if key not in found:
                lines.insert(insert_at, f"{key}={value}")
                insert_at += 1

    path.write_text(newline.join(lines) + newline, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path)
    parser.add_argument("section")
    parser.add_argument("updates", nargs="+")
    args = parser.parse_args()
    parsed: dict[str, str] = {}
    for update in args.updates:
        if "=" not in update:
            parser.error(f"expected KEY=VALUE, got {update!r}")
        key, value = update.split("=", 1)
        parsed[key] = value
    patch_ini(args.path, args.section, parsed)


if __name__ == "__main__":
    main()

