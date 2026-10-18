#!/bin/bash
# Build and launch the face in the Connect IQ simulator.
#   ./run-sim.sh [device] [release|probe]
set -euo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk}"
export PATH="$JAVA_HOME/bin:$PATH"
CFG="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
if [ -z "${CIQ_SDK:-}" ] && [ -f "$CFG" ]; then
    CIQ_SDK="$(cat "$CFG")"
fi
SDK="${CIQ_SDK:?set CIQ_SDK to your Connect IQ SDK directory}"
DEVICE="${1:-fenix9pro43mm}"
MODE="${2:-release}"
cd "$(dirname "$0")"
./build.sh "$DEVICE" "$MODE"
case "$MODE" in probe) PRG="bin/patekfenix-$DEVICE-aodprobe.prg";; dark) PRG="bin/patekfenix-$DEVICE-dark.prg";; light) PRG="bin/patekfenix-$DEVICE-light.prg";; alt) PRG="bin/patekfenix-$DEVICE-alt.prg";; *) PRG="bin/patekfenix-$DEVICE.prg";; esac
"$SDK/bin/connectiq"
sleep 8
"$SDK/bin/monkeydo" "$PRG" "$DEVICE"
