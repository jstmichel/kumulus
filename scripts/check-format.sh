#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT
#
# Checks that the C++ sources tracked by git match the repository's .clang-format, without
# changing any file. Run locally and in CI.
#
# Usage: scripts/check-format.sh [--help]
#
# CLANG_FORMAT selects the clang-format binary (default: clang-format).
# Exit codes: 0 all files formatted, 1 a file differs, 2 clang-format not found.

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    sed -n '5,11s/^# \{0,1\}//p' "$0"
    exit 0
fi

clang_format="${CLANG_FORMAT:-clang-format}"
if ! command -v "$clang_format" >/dev/null 2>&1; then
    echo "check-format: '$clang_format' not found; install clang or set CLANG_FORMAT." >&2
    exit 2
fi

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

mapfile -d '' files < <(git ls-files -z -- 'src/*.cpp' 'src/*.h' 'tests/*.cpp' 'tests/*.h')
if ((${#files[@]} == 0)); then
    echo "check-format: no C++ files to check."
    exit 0
fi

if ! "$clang_format" --dry-run --Werror "${files[@]}"; then
    echo "check-format: run '$clang_format -i' on the files above." >&2
    exit 1
fi

echo "check-format: ${#files[@]} files formatted."
