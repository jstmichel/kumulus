#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT
#
# Tests scripts/check-deps.sh against a fake pacman, so the installed packages never matter.
#
# Usage: tests/checkdepstest.sh <path to check-deps.sh>

set -euo pipefail

script=$(realpath "$1")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# A PATH with only what the script needs, so the real pacman is never reached.
tools="$work/tools"
mkdir -p "$tools"
for tool in env bash awk cut sed vercmp; do
    ln -s "$(command -v "$tool")" "$tools/$tool"
done

# The fake pacman answers `pacman -Q <package>` from $work/packages ("name version" lines).
with_pacman="$work/with-pacman"
mkdir -p "$with_pacman"
cat > "$with_pacman/pacman" <<'FAKE'
#!/usr/bin/env bash
line=$(grep -E "^$2 " "$FAKE_PACKAGES") || { echo "error: package '$2' was not found" >&2; exit 1; }
echo "$line"
FAKE
chmod +x "$with_pacman/pacman"
ln -s "$(command -v grep)" "$with_pacman/grep"

export FAKE_PACKAGES="$work/packages"
"$script" --with-checks --list | sed 's/$/ 99.0-1/' > "$FAKE_PACKAGES"

failures=0

# Runs the script with the fake tools; sets $status and $output.
run() {
    status=0
    output=$(PATH="$with_pacman:$tools" "$script" "$@" 2>&1) || status=$?
}

check() {
    local name=$1 expected_status=$2 expected_text=$3
    if [[ $status -ne $expected_status || "$output" != *"$expected_text"* ]]; then
        echo "FAIL: $name (exit $status, expected $expected_status and \"$expected_text\")"
        echo "$output" | sed 's/^/    /'
        failures=$((failures + 1))
    else
        echo "PASS: $name"
    fi
}

# #2 R3: with everything installed, the script exits 0.
run --with-checks
check "all present" 0 "all dependencies are installed"

# #2 R3: a missing dependency makes the script fail and is named.
sed -i '/^kirigami /d' "$FAKE_PACKAGES"
run
check "one missing" 1 "missing or too old: kirigami"
echo "kirigami 99.0-1" >> "$FAKE_PACKAGES"

# #2 R3: a dependency older than its minimum is named too.
sed -i 's/^rclone .*/rclone 1.74.0-1/' "$FAKE_PACKAGES"
run
check "too old" 1 "missing or too old: rclone"
sed -i 's/^rclone .*/rclone 99.0-1/' "$FAKE_PACKAGES"

# The CI tools are required only with --with-checks.
sed -i '/^clang /d' "$FAKE_PACKAGES"
run
check "check tools optional" 0 "all dependencies are installed"
run --with-checks
check "check tools with --with-checks" 1 "missing or too old: clang"

# Without pacman, the script refuses to guess.
status=0
output=$(PATH="$tools" "$script" 2>&1) || status=$?
check "not Arch" 2 "Arch-based systems only"

[[ $failures -eq 0 ]]
