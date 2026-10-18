#!/bin/bash
# Build the Connect IQ Store package (.iq) for every product in manifest.xml.
#   ./package.sh            -> bin/patekfenix-<VERSION>.iq (signed, release)
set -euo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk}"
export PATH="$JAVA_HOME/bin:$PATH"
CFG="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
if [ -z "${CIQ_SDK:-}" ] && [ -f "$CFG" ]; then
    CIQ_SDK="$(cat "$CFG")"
fi
SDK="${CIQ_SDK:?set CIQ_SDK to your Connect IQ SDK directory}"
KEY="${CIQ_KEY:-$HOME/.connectiq/developer_key.der}"
cd "$(dirname "$0")"
VERSION="$(tr -d '\r\n' < VERSION)"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid VERSION: expected major.minor.patch" >&2
    exit 1
fi
OUT="bin/patekfenix-$VERSION.iq"
mkdir -p bin
"$SDK/bin/monkeyc" -f monkey.jungle -o "$OUT" -y "$KEY" -e -r -w -l 3
echo "built $OUT (enter version $VERSION in the Connect IQ Store upload form)"
