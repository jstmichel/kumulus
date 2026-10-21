#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT
#
# Checks that the Kumulus build and runtime dependencies are installed, and names each one
# that is missing or too old. The single source of truth for dependencies: the CI and the
# PKGBUILDs take their package list from it.
#
# Usage: scripts/check-deps.sh [--with-checks] [--list] [--help]
#
# --with-checks also requires the tools the CI checks with (clang-format, validators).
# --list prints the package names, one per line, and checks nothing.
# Exit codes: 0 all present, 1 a dependency is missing or too old, 2 not an Arch-based system.

set -euo pipefail

# Format: package|minimum version|kind. Kinds: build, runtime, check (only with --with-checks).
# A new dependency is added here in the same change that uses it.
DEPENDENCIES=(
    "base-devel||build"
    "cmake|3.25|build"
    "extra-cmake-modules|6.0|build"
    "ninja||build"
    "gettext||build"
    "qt6-base|6.6|runtime"
    "qt6-declarative|6.6|runtime"
    "kcoreaddons|6.0|runtime"
    "ki18n|6.0|runtime"
    "kcrash|6.0|runtime"
    "kiconthemes|6.0|runtime"
    "kirigami|6.0|runtime"
    "kirigami-addons|1.0|runtime"
    # The version Kumulus is tested with, not the first with the iclouddrive backend (1.69):
    # Apple's API changes and older versions may no longer work. Raised deliberately (#2).
    "rclone|1.75|runtime"
    "fuse3||runtime"
    "clang||check"
    "desktop-file-utils||check"
    "appstream||check"
)

with_checks=0
list=0

usage() {
    sed -n '5,13s/^# \{0,1\}//p' "$0"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-checks)
            with_checks=1
            shift
            ;;
        --list)
            list=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "check-deps: unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# The dependencies selected by the options, one entry per line.
selected() {
    local entry kind
    for entry in "${DEPENDENCIES[@]}"; do
        kind=${entry##*|}
        if [[ "$kind" == "check" && $with_checks -eq 0 ]]; then
            continue
        fi
        printf '%s\n' "$entry"
    done
}

if [[ $list -eq 1 ]]; then
    selected | cut -d'|' -f1
    exit 0
fi

if ! command -v pacman >/dev/null 2>&1 || ! command -v vercmp >/dev/null 2>&1; then
    echo "check-deps: pacman not found; this script supports Arch-based systems only." >&2
    exit 2
fi

missing=()

printf '%-22s %-8s %-16s %s\n' "PACKAGE" "STATUS" "INSTALLED" "REQUIRED"
while IFS='|' read -r pkg minimum _; do
    version=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}') || true
    if [[ -z "$version" ]]; then
        status="missing"
    elif [[ -n "$minimum" ]] && (($(vercmp "$version" "$minimum") < 0)); then
        status="too old"
    else
        status="ok"
    fi
    printf '%-22s %-8s %-16s %s\n' "$pkg" "$status" "${version:--}" "${minimum:+>= $minimum}"
    if [[ "$status" != "ok" ]]; then
        missing+=("$pkg")
    fi
done < <(selected)

echo
if [[ ${#missing[@]} -eq 0 ]]; then
    echo "check-deps: all dependencies are installed."
    exit 0
fi

echo "check-deps: missing or too old: ${missing[*]}" >&2
echo "Install them with: sudo pacman -S --needed ${missing[*]}" >&2
exit 1
