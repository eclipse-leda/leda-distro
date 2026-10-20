import importlib.util
import os
import subprocess
import sys
from pathlib import Path

import pytest


SCRIPT = Path(__file__).with_name("update-copyright-header.py")
SPEC = importlib.util.spec_from_file_location("update_copyright_header", SCRIPT)
updater = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(updater)


@pytest.mark.parametrize(
    ("header", "expected"),
    [
        (
            "# Copyright (c) 2023 Contributors to the Eclipse Foundation\n",
            "# Copyright (c) 2022-2026 Contributors to the Eclipse Foundation\n",
        ),
        (
            "// Copyright 2022 The contributors to the Eclipse project\n",
            "// Copyright 2022-2026 The contributors to the Eclipse project\n",
        ),
        (
            "# Copyright (c) 2020 Contributors to Eclipse Foundation\n",
            "# Copyright (c) 2022-2026 Contributors to Eclipse Foundation\n",
        ),
        (
            " * Copyright (c) 2021–2024 Contributors to the Eclipse Foundation\n",
            " * Copyright (c) 2022-2026 Contributors to the Eclipse Foundation\n",
        ),
    ],
)
def test_updates_eclipse_contributor_year_ranges(header, expected):
    updated, changes = updater.copyright_updates(
        header.encode(), first_year=2022, current_year=2026
    )

    assert updated.decode() == expected
    assert len(changes) == 1


@pytest.mark.parametrize(
    "header",
    [
        "# Copyright (c) 2026 Contributors to the Eclipse Foundation\n",
        "# Copyright (c) 2023-2027 Contributors to the Eclipse Foundation\n",
        "# Copyright (c) 2020 Other Contributors\n",
        "# Copyright (c) 2020 Example Corporation\n",
    ],
)
def test_leaves_current_or_non_eclipse_headers_unchanged(header):
    updated, changes = updater.copyright_updates(
        header.encode(), first_year=2020, current_year=2026
    )

    assert updated is None
    assert changes == []


def git(root, *args, date=None):
    environment = os.environ.copy()
    if date:
        environment.update(
            GIT_AUTHOR_DATE=date,
            GIT_COMMITTER_DATE=date,
        )
    subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        capture_output=True,
        env=environment,
    )


def create_history_file(root, relative_path, contents):
    git(root, "init", "-q")
    git(root, "config", "user.name", "Pytest")
    git(root, "config", "user.email", "pytest@example.com")
    path = root / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents)
    git(root, "add", str(relative_path))
    git(root, "commit", "-qm", "initial file", date="2022-01-01T12:00:00+0000")

    path.write_text(contents.replace("initial", "touched"))
    git(root, "add", str(relative_path))
    current_year = updater.datetime.date.today().year
    git(
        root,
        "commit",
        "-qm",
        "touch file",
        date=f"{current_year}-01-01T12:00:00+0000",
    )
    return path


@pytest.mark.parametrize("apply", [False, True])
def test_main_dry_run_and_apply(tmp_path, monkeypatch, capsys, apply):
    path = create_history_file(
        tmp_path,
        Path("sample.py"),
        "# Copyright (c) 2022 Contributors to the Eclipse Foundation\n"
        "# Copyright (c) 2020 Example Corporation\n"
        "print('initial')\n",
    )
    original = path.read_bytes()
    monkeypatch.setattr(updater, "repository_root", lambda: tmp_path)
    monkeypatch.setattr(sys, "argv", [str(SCRIPT)] + (["--apply"] if apply else []))

    assert updater.main() == 0

    output = capsys.readouterr().out
    current_year = updater.datetime.date.today().year
    if apply:
        assert path.read_text().startswith(
            f"# Copyright (c) 2022-{current_year} Contributors"
        )
        assert "Files updated: 1" in output
    else:
        assert path.read_bytes() == original
        assert "Would update: sample.py" in output
        assert "Files that would be updated: 1" in output
    assert "# Copyright (c) 2020 Example Corporation" in path.read_text()


def test_help_option(capsys, monkeypatch):
    monkeypatch.setattr(sys, "argv", [str(SCRIPT), "--help"])

    with pytest.raises(SystemExit) as error:
        updater.parse_arguments()

    assert error.value.code == 0
    assert "--apply" in capsys.readouterr().out
