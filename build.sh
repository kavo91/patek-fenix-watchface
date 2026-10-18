#!/bin/bash
# Build Patek FENIX for one device.
#   ./build.sh [device] [release|test|probe]
# release -> bin/patekfenix-<device>.prg (signed, sideloadable)
# test    -> bin/patekfenix-<device>-test.prg (unit-test variant for the simulator)
# probe   -> bin/patekfenix-<device>-aodprobe.prg (forces the always-on renderer, for screenshots)
# dark    -> bin/patekfenix-<device>-dark.prg (forces the dark palette, for screenshots)
# light   -> bin/patekfenix-<device>-light.prg (forces the light palette, for screenshots)
# alt     -> bin/patekfenix-<device>-alt.prg (light palette, alternate data slots, for screenshots)
set -euo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk}"
export PATH="$JAVA_HOME/bin:$PATH"
CFG="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
if [ -z "${CIQ_SDK:-}" ] && [ -f "$CFG" ]; then
    CIQ_SDK="$(cat "$CFG")"
fi
SDK="${CIQ_SDK:?set CIQ_SDK to your Connect IQ SDK directory}"
KEY="${CIQ_KEY:-$HOME/.connectiq/developer_key.der}"
DEVICE="${1:-fenix9pro43mm}"
MODE="${2:-release}"
cd "$(dirname "$0")"
mkdir -p bin
case "$MODE" in
    release) OUT="bin/patekfenix-$DEVICE.prg";          JUNGLE=monkey.jungle; EXTRA=(-r) ;;
    test)    OUT="bin/patekfenix-$DEVICE-test.prg";     JUNGLE=monkey.jungle; EXTRA=(-t) ;;
    probe)   OUT="bin/patekfenix-$DEVICE-aodprobe.prg"; JUNGLE=probe.jungle;  EXTRA=() ;;
    dark)    OUT="bin/patekfenix-$DEVICE-dark.prg";     JUNGLE=dark.jungle;   EXTRA=() ;;
    light)   OUT="bin/patekfenix-$DEVICE-light.prg";    JUNGLE=light.jungle;  EXTRA=() ;;
    alt)     OUT="bin/patekfenix-$DEVICE-alt.prg";      JUNGLE=alt.jungle;    EXTRA=() ;;
    store-*) OUT="bin/patekfenix-$DEVICE-$MODE.prg";    JUNGLE="$MODE.jungle"; EXTRA=() ;;
    *) echo "mode must be release, test, probe, dark, light, alt or store-{light,dark,alt,aod}" >&2; exit 2 ;;
esac
"$SDK/bin/monkeyc" -f "$JUNGLE" -d "$DEVICE" -o "$OUT" -y "$KEY" -w -l 3 ${EXTRA[@]+"${EXTRA[@]}"}
echo "built $OUT"
