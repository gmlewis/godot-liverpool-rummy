#!/bin/bash
# build-android-aab.sh - Build the signed release AAB for Google Play from the CLI.
#
# Usage:
#   ./build-android-aab.sh                # build with /Applications/Godot.app
#   ./build-android-aab.sh /path/Godot    # build with a specific Godot binary
#   GODOT=/path/Godot ./build-android-aab.sh
#
# Output:
#   android/liverpool-rummy-english.aab
#
# Logs:
#   build-android-aab.log  (Godot + Gradle stdout/stderr, overwritten each run)
#
# This script does NOT bump the version. Run ./bump-version.sh first if you
# are shipping a new release — Google Play rejects any AAB whose
# version/code is not strictly greater than the last uploaded one.

set -euo pipefail

# --- locate Godot -----------------------------------------------------------

GODOT="${GODOT:-${1:-}}"
if [[ -z "$GODOT" ]]; then
    if [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
        GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
    else
        echo "Error: Godot binary not found." >&2
        echo "Pass it as the first argument or set \$GODOT, e.g.:" >&2
        echo "  $0 /Applications/Godot.app/Contents/MacOS/Godot" >&2
        exit 1
    fi
fi

if [[ ! -x "$GODOT" ]]; then
    echo "Error: Godot binary not executable: $GODOT" >&2
    exit 1
fi

# This project uses pure GDScript — the standard (non-mono) Godot 4.5
# binary is correct. If you see "no C# support" errors, you accidentally
# pointed this at Godot_mono; that's harmless but unnecessary here.
echo "Using Godot: $GODOT"
"$GODOT" --version

# --- sanity checks ----------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

AAB="android/liverpool-rummy-english.aab"
PRESET="liverpool-rummy"
LOG="build-android-aab.log"

# Confirm the preset exists in export_presets.cfg — if it doesn't, the
# export will fail silently and produce nothing.
if ! grep -q "^name=\"$PRESET\"$" export_presets.cfg; then
    echo "Error: Android preset \"$PRESET\" not found in export_presets.cfg" >&2
    echo "Available presets:" >&2
    grep "^name=" export_presets.cfg >&2 || true
    exit 1
fi

# Confirm the keystore is present — the release build is signed with it.
if [[ ! -f liverpool-rummy.keystore ]]; then
    echo "Warning: liverpool-rummy.keystore not found at repo root." >&2
    echo "The build may fail or produce an unsigned AAB." >&2
fi

# --- build -----------------------------------------------------------------

echo "Building $AAB (preset: $PRESET)..."
echo "Logging to $LOG"

# --headless avoids initializing the renderer / opening any GUI window
# during export (Godot still needs OpenGL for some export steps, but
# --headless keeps it from creating a visible window).
# --export-release <preset> <output-path>
# If a third argument is omitted, Godot uses the export_path from the preset.
# We pass it explicitly so the output location is unambiguous in the log.
"$GODOT" --headless --path "$REPO_ROOT" --export-release "$PRESET" "$AAB" 2>&1 | tee "$LOG"

# --- verify ----------------------------------------------------------------

if [[ ! -f "$AAB" ]]; then
    echo "Error: AAB was not produced at $AAB" >&2
    echo "Check $LOG for Gradle errors." >&2
    exit 1
fi

echo
echo "=== Build OK ==="
echo "AAB: $AAB"
ls -lh "$AAB"

# Quick sanity: report targetSdkVersion from the built manifest inside the AAB.
# aapt lives under $ANDROID_HOME/build-tools/<version>/aapt (or aapt2).
AAPT=""
if command -v aapt2 >/dev/null 2>&1; then
    AAPT="aapt2"
elif command -v aapt >/dev/null 2>&1; then
    AAPT="aapt"
elif [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/build-tools" ]]; then
    AAPT="$(ls -1 "$ANDROID_HOME/build-tools"/*/aapt2 2>/dev/null | tail -1)"
    [[ -z "$AAPT" ]] && AAPT="$(ls -1 "$ANDROID_HOME/build-tools"/*/aapt 2>/dev/null | tail -1)"
fi

if [[ -n "$AAPT" ]]; then
    echo
    echo "=== AAB manifest summary ==="
    # AAB is a zip; the merged manifest is at AndroidManifest.xml inside it.
    # aapt/aapt2 can read it directly.
    "$AAPT" dump badging "$AAB" 2>/dev/null | grep -E "^(package|sdkVersion|targetSdkVersion|application-label:)" || true
else
    echo "(aapt not on PATH; skipping manifest sanity check)"
fi

echo
echo "Next: upload $AAB to the Play Console → Production → Create new release"