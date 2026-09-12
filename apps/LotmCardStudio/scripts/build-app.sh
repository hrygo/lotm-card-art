#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-debug}"

case "$CONFIGURATION" in
    debug|release) ;;
    *)
        echo "usage: $0 [debug|release]" >&2
        exit 2
        ;;
esac

swift build --package-path "$APP_ROOT" --product LotmCardStudio --configuration "$CONFIGURATION"
BIN_PATH="$(swift build --package-path "$APP_ROOT" --product LotmCardStudio --configuration "$CONFIGURATION" --show-bin-path)"
APP_BUNDLE="$APP_ROOT/.build/LotmCardStudio.app"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BIN_PATH/LotmCardStudio" "$APP_BUNDLE/Contents/MacOS/LotmCardStudio"
cp "$APP_ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [[ "$CONFIGURATION" == "release" ]]; then
    codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

echo "$APP_BUNDLE"
