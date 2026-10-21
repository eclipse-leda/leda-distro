#!/usr/bin/env python3
"""Update stale Eclipse contributor copyright years in recently changed files."""

import argparse
import datetime
import re
import subprocess
import sys
from pathlib import Path


COPYRIGHT_LINE = re.compile(
    r"\bcopyright\b\s*(?:\(\s*c\s*\)\s*)?"
    r"(?P<years>[0-9]{4}(?:\s*[-\u2013]\s*[0-9]{4})?)",
    re.IGNORECASE,
)
ECLIPSE_CONTRIBUTORS = re.compile(
    r"\b(?:the\s+)?contributors?\s+to\s+(?:the\s+)?eclipse"
    r"(?:\s+(?:foundation|project))?\b",
    re.IGNORECASE,
)
HEADER_LINE_LIMIT = 40


def git_output(root, *args):
    return subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout


def repository_root():
    script_directory = Path(__file__).resolve().parent
    return Path(
        git_output(script_directory, "rev-parse", "--show-toplevel")
        .decode("utf-8")
        .strip()
    )


def repository_files(root):
    paths = git_output(
        root, "ls-files", "--cached", "--others", "--exclude-standard", "-z"
    )
    return [
        Path(path.decode("utf-8", errors="surrogateescape"))
        for path in paths.split(b"\0")
        if path
    ]


def file_years(root, relative_path):
    history = git_output(
        root,
        "log",
        "--follow",
        "--format=%ad",
        "--date=format:%Y",
        "--",
        str(relative_path),
    )
    years = [int(year) for year in history.decode("ascii").splitlines() if year]
    if not years:
        return None
    return years[0], years[-1]


def copyright_updates(contents, first_year, current_year):
    text = contents.decode("utf-8", errors="surrogateescape")
    lines = text.splitlines(keepends=True)
    updates = []

    for line_number, line in enumerate(lines[:HEADER_LINE_LIMIT]):
        if not ECLIPSE_CONTRIBUTORS.search(line):
            continue
        match = COPYRIGHT_LINE.search(line)
        if not match:
            continue

        years = [int(year) for year in re.findall(r"[0-9]{4}", match.group("years"))]
        if len(years) == 1:
            contains_current_year = years[0] == current_year
        else:
            contains_current_year = years[0] <= current_year <= years[1]
        if contains_current_year:
            continue

        new_years = (
            str(first_year)
            if first_year == current_year
            else f"{first_year}-{current_year}"
        )
        updated_line = (
            line[: match.start("years")]
            + new_years
            + line[match.end("years") :]
        )
        lines[line_number] = updated_line
        updates.append((line_number + 1, match.group("years"), new_years))

    if not updates:
        return None, updates
    return "".join(lines).encode("utf-8", errors="surrogateescape"), updates


def parse_arguments():
    parser = argparse.ArgumentParser(
        description=(
            "Update stale Eclipse contributor copyright years for files touched "
            "in the current year."
        ),
        epilog="By default, changes are only previewed. Use --apply to write them.",
    )
    action = parser.add_mutually_exclusive_group()
    action.add_argument(
        "--apply",
        action="store_true",
        help="write the copyright year updates (default is a dry-run)",
    )
    action.add_argument(
        "--dry-run",
        action="store_true",
        help="preview updates without writing files (the default)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="show why each file was or was not selected",
    )
    return parser.parse_args()


def main():
    args = parse_arguments()
    current_year = datetime.date.today().year
    root = repository_root()
    checked = 0
    updated_count = 0
    first_years = []

    for relative_path in repository_files(root):
        path = root / relative_path
        if path.is_symlink() or not path.is_file():
            if args.verbose:
                print(f"Skipping non-regular file: {relative_path}")
            continue

        checked += 1
        history = file_years(root, relative_path)
        if history is None:
            if args.verbose:
                print(f"Skipping (no Git history): {relative_path}")
            continue

        last_touched_year, first_year = history
        if last_touched_year != current_year:
            if args.verbose:
                print(
                    f"Skipping (last touched {last_touched_year}): "
                    f"{relative_path}"
                )
            continue

        contents = path.read_bytes()
        updated_contents, changes = copyright_updates(
            contents, first_year, current_year
        )
        if not changes:
            if args.verbose:
                print(f"No stale Eclipse copyright header: {relative_path}")
            continue

        for line_number, old_years, new_years in changes:
            action = "Update" if args.apply else "Would update"
            print(
                f"{action}: {relative_path}:{line_number} "
                f"({old_years} -> {new_years})"
            )
        first_years.append(first_year)

        if args.apply:
            path.write_bytes(updated_contents)
        updated_count += 1

    mode = "apply" if args.apply else "dry-run"
    print(f"\nSummary ({mode}):")
    print(f"  Files checked: {checked}")
    label = "Files updated" if args.apply else "Files that would be updated"
    print(f"  {label}: {updated_count}")
    print(f"  First year: {min(first_years) if first_years else 'n/a'}")
    print(f"  Last year: {current_year if first_years else 'n/a'}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        message = error.stderr.decode("utf-8", errors="replace").strip()
        print(f"Error running Git: {message}", file=sys.stderr)
        sys.exit(1)
