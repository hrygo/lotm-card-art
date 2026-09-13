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
if [[ -f "$APP_ROOT/Resources/AppIcon.icns" ]]; then
    cp "$APP_ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
if [[ -d "$APP_ROOT/Resources/CardArt" ]]; then
    mkdir -p "$APP_BUNDLE/Contents/Resources/CardArt"
    cp -R "$APP_ROOT/Resources/CardArt/." "$APP_BUNDLE/Contents/Resources/CardArt/"
fi
if [[ -d "$APP_ROOT/Resources/Audio" ]]; then
    mkdir -p "$APP_BUNDLE/Contents/Resources/Audio"
    cp -R "$APP_ROOT/Resources/Audio/." "$APP_BUNDLE/Contents/Resources/Audio/"
fi

if [[ -d "$APP_ROOT/Resources/Assets.xcassets" ]] && command -v actool >/dev/null 2>&1; then
    actool "$APP_ROOT/Resources/Assets.xcassets" \
        --compile "$APP_BUNDLE/Contents/Resources" \
        --platform macosx \
        --minimum-deployment-target 26.0 \
        --app-icon AppIcon \
        --output-partial-info-plist /tmp/lotm_actool_partial.plist >/dev/null 2>&1 || true
fi

if [[ "$CONFIGURATION" == "release" ]]; then
    codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

echo "$APP_BUNDLE"
