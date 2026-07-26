#!/usr/bin/env python3
"""Shared path-boundary checks for Director Mode installer writes."""

from __future__ import annotations

from pathlib import Path, PurePosixPath
import stat
from typing import Iterable


class UnsafeManagedPath(RuntimeError):
    """A managed destination could escape or alias another filesystem path."""


def safe_relative(value: str | Path) -> Path:
    """Return a normalized relative path without resolving filesystem links."""

    pure = PurePosixPath(Path(value).as_posix())
    if pure.is_absolute() or not pure.parts or ".." in pure.parts:
        raise UnsafeManagedPath(f"managed path is not safely relative: {value}")
    return Path(*pure.parts)


def assert_safe_managed_files(root: Path, values: Iterable[str | Path]) -> None:
    """Reject symlinks and non-directory ancestors for managed file paths.

    ``root`` is already the canonical installation root. Paths are inspected
    with ``lstat`` semantics so a destination symlink is rejected rather than
    followed. The check intentionally covers only components below ``root``;
    normal platform aliases such as macOS ``/tmp`` remain usable once the
    caller has canonicalized the project root.
    """

    root = root.resolve()
    if not root.is_dir():
        raise UnsafeManagedPath(f"installation root is not a directory: {root}")

    for value in values:
        relative = safe_relative(value)
        current = root
        for index, part in enumerate(relative.parts):
            current = current / part
            try:
                metadata = current.lstat()
                mode = metadata.st_mode
            except FileNotFoundError:
                continue

            label = relative.as_posix()
            if stat.S_ISLNK(mode):
                raise UnsafeManagedPath(f"managed path contains a symlink: {label}")
            final = index == len(relative.parts) - 1
            if not final and not stat.S_ISDIR(mode):
                raise UnsafeManagedPath(
                    f"managed path ancestor is not a directory: {label}"
                )
            if final and not stat.S_ISREG(mode):
                raise UnsafeManagedPath(
                    f"managed file destination is not a regular file: {label}"
                )
            if final and metadata.st_nlink > 1:
                raise UnsafeManagedPath(
                    f"managed file destination has multiple hard links: {label}"
                )
