#!/usr/bin/env bash
# Runs the AutoHotkey regression tests under Wine (Linux/macOS CI).
# On Windows just run:  AutoHotkeyU64.exe /ErrorStdOut tests\RunTests.ahk
set -euo pipefail
cd "$(dirname "$0")/.."
AHK="${AHK_EXE:-$HOME/ahk/AutoHotkeyU64.exe}"
export WINEDEBUG=-all
SCRIPT="$(winepath -w tests/RunTests.ahk 2>/dev/null)"
xvfb-run -a wine "$AHK" /ErrorStdOut "$SCRIPT" "$@"
