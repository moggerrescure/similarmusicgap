#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MAESTRO_DIR="$ROOT/maestro"
APP="${APP_PATH:-/tmp/SoundShiftDerivedData/Build/Products/Debug-iphonesimulator/music.app}"
UDID="${SIM_UDID:-1780CCC3-3973-4A1C-A6F7-10EA666DACC7}"
BUNDLE_ID="qere.music"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export PATH="$DEVELOPER_DIR/usr/bin:$JAVA_HOME/bin:${PATH}:$HOME/.maestro/bin"
# XCTest driver on recent iOS sims often needs >60s after boot/reinstall
export MAESTRO_DRIVER_STARTUP_TIMEOUT="${MAESTRO_DRIVER_STARTUP_TIMEOUT:-180000}"

echo "== Java =="
java -version
echo "== Maestro =="
maestro --version

echo "== Boot simulator $UDID =="
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator || true

if [[ ! -d "$APP" ]]; then
  echo "App not found at $APP — building…"
  xcodebuild \
    -project "$ROOT/music/music.xcodeproj" \
    -scheme music \
    -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath /tmp/SoundShiftDerivedData \
    build
fi

echo "== Install $BUNDLE_ID =="
xcrun simctl install "$UDID" "$APP"

echo "== Run Maestro suite =="
cd "$MAESTRO_DIR"
mkdir -p "$MAESTRO_DIR/reports"
maestro test \
  --device "$UDID" \
  --format junit \
  --output "$MAESTRO_DIR/reports/junit-report.xml" \
  --debug-output "$MAESTRO_DIR/reports/debug" \
  flows/
