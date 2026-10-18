#!/bin/bash
# Build the unit-test variant and run it inside the Connect IQ simulator.
#   ./run-tests.sh [device]
# Output lands in evidence/unit-tests-<device>.txt. Read the PASSED/FAILED summary line;
# the simulator sometimes exits non-zero while shutting down after a green run.
set -uo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk}"
export PATH="$JAVA_HOME/bin:$PATH"
CFG="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
if [ -z "${CIQ_SDK:-}" ] && [ -f "$CFG" ]; then
    CIQ_SDK="$(cat "$CFG")"
fi
SDK="${CIQ_SDK:?set CIQ_SDK to your Connect IQ SDK directory}"
DEVICE="${1:-fenix9pro43mm}"
cd "$(dirname "$0")"
./build.sh "$DEVICE" test || exit 1
"$SDK/bin/connectiq"          # opens the simulator if it is not already open
sleep 8
mkdir -p evidence
"$SDK/bin/monkeydo" "bin/patekfenix-$DEVICE-test.prg" "$DEVICE" -t 2>&1 | tee "evidence/unit-tests-$DEVICE.txt"
