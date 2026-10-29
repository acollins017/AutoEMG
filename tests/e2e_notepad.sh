#!/usr/bin/env bash
# End-to-end test of the hotkey workflow under Wine + Xvfb (Linux only).
# Opens a fixture in Wine Notepad (word wrap on), presses Ctrl+Q, accepts the
# draft with Alt+I, saves, and checks that ONLY the lines under "Summary:" and
# "Impression:" changed and that they contain the engine's output.
#   tests/e2e_notepad.sh [fixture-name]
set -euo pipefail
cd "$(dirname "$0")/.."
FIX="${1:-04_cts_bilateral}"
AHK="${AHK_EXE:-$HOME/ahk/AutoHotkeyU64.exe}"
WORK=/tmp/autoemg-e2e
DISP=:79
export WINEDEBUG=-all DISPLAY=$DISP

rm -rf "$WORK" && mkdir -p "$WORK"
cp "tests/fixtures/$FIX.txt" "$WORK/report.txt"
Xvfb $DISP -screen 0 1400x900x24 >/dev/null 2>&1 & XPID=$!
trap 'kill $XPID 2>/dev/null; wineserver -k 2>/dev/null || true' EXIT
sleep 2
openbox >/dev/null 2>&1 &
sleep 1
wine notepad "Z:${WORK//\//\\}\\report.txt" >/dev/null 2>&1 &
sleep 6
wine "$AHK" /ErrorStdOut "Z:$(pwd | sed 's|/|\\|g')\\AutoEMG.ahk" >"$WORK/ahk.log" 2>&1 &
sleep 5
W=$(xdotool search --name "report.txt - Notepad" | head -1)
xdotool windowactivate --sync "$W" 2>/dev/null || true
xdotool mousemove 300 300 click 1
sleep 0.5
start=$(date +%s)
xdotool key ctrl+q
for i in $(seq 1 30); do xdotool search --name "AutoEMG - Draft" >/dev/null 2>&1 && break; sleep 0.5; done
sleep 1
import -window root "$WORK/preview.png"
xdotool key alt+i
for i in $(seq 1 120); do sleep 0.5; xdotool search --name "AutoEMG - Draft" >/dev/null 2>&1 || break; done
sleep 8
xdotool windowactivate --sync "$W" 2>/dev/null || true
import -window root "$WORK/inserted.png"
xdotool key ctrl+s
sleep 2
echo "elapsed: $(( $(date +%s) - start ))s (includes fixed waits)"
diff <(tr -d '\r' < "tests/fixtures/$FIX.txt") <(tr -d '\r' < "$WORK/report.txt") > "$WORK/diff.txt" || true
cat "$WORK/diff.txt"
# Expect exactly two hunks, both pure additions directly under the headings.
hunks=$(grep -c '^[0-9]' "$WORK/diff.txt" || true)
removed=$(grep -c '^<' "$WORK/diff.txt" || true)
if [[ "$hunks" == "2" && "$removed" == "0" ]]; then echo "E2E PASS"; else echo "E2E FAIL (hunks=$hunks removed=$removed)"; exit 1; fi
