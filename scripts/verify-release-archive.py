#!/usr/bin/env python3
from __future__ import annotations

import argparse
import io
import subprocess
import sys
import tarfile
from pathlib import PurePosixPath


class ArchiveArguments(argparse.Namespace):
    def __init__(self) -> None:
        super().__init__()
        self.archive: str = ""
        self.commit: str = ""
        self.repository: str = "."


def archive_entries(archive: tarfile.TarFile, *, strip_root: bool) -> dict[str, tuple[str, int, bytes | str]]:
    entries: dict[str, tuple[str, int, bytes | str]] = {}
    root: str | None = None
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"unsafe archive path: {member.name}")
        if not path.parts:
            continue
        if strip_root:
            if root is None:
                root = path.parts[0]
            if path.parts[0] != root:
                raise ValueError("downloaded archive contains more than one root directory")
            path = PurePosixPath(*path.parts[1:])
        if not path.parts or member.isdir():
            continue
        name = path.as_posix()
        if name in entries:
            raise ValueError(f"duplicate archive path: {name}")
        mode = member.mode & 0o777
        if member.isfile():
            stream = archive.extractfile(member)
            if stream is None:
                raise ValueError(f"unable to read archive file: {name}")
            entries[name] = ("file", mode, stream.read())
        elif member.issym():
            entries[name] = ("symlink", mode, member.linkname)
        else:
            raise ValueError(f"unsupported archive entry type: {name}")
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    _ = parser.add_argument("--archive", required=True, help="Downloaded GitHub .tar.gz archive")
    _ = parser.add_argument("--commit", required=True, help="Resolved commit SHA")
    _ = parser.add_argument("--repository", default=".", help="Git repository containing the commit")
    args = parser.parse_args(namespace=ArchiveArguments())

    try:
        downloaded = tarfile.open(args.archive, mode="r:gz")
        with downloaded:
            downloaded_entries = archive_entries(downloaded, strip_root=True)
        expected_bytes = subprocess.run(
            ["git", "-C", args.repository, "archive", "--format=tar", args.commit],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout
        with tarfile.open(fileobj=io.BytesIO(expected_bytes), mode="r:") as expected:
            expected_entries = archive_entries(expected, strip_root=False)
    except (OSError, tarfile.TarError, ValueError, subprocess.CalledProcessError) as error:
        print(f"archive verification failed: {error}", file=sys.stderr)
        return 1

    if downloaded_entries != expected_entries:
        missing = sorted(expected_entries.keys() - downloaded_entries.keys())
        extra = sorted(downloaded_entries.keys() - expected_entries.keys())
        changed = sorted(
            name
            for name in expected_entries.keys() & downloaded_entries.keys()
            if expected_entries[name] != downloaded_entries[name]
        )
        print(
            f"archive does not match commit {args.commit}: missing={missing}, extra={extra}, changed={changed}",
            file=sys.stderr,
        )
        return 1

    print(f"Verified downloaded archive contents match commit {args.commit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
