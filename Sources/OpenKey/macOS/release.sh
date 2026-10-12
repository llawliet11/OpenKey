#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
OUT="${OUT:-$PWD/build}"
APP_NAME="OpenKey CE"
: "${NOTARY_PROFILE:?set NOTARY_PROFILE to a notarytool keychain profile}"
IDENTITY="${DEVELOPER_ID_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -1)}"
[[ -n "$IDENTITY" ]] || { echo "no Developer ID Application identity found" >&2; exit 1; }

rm -rf "$OUT"
xcodebuild -project OpenKey.xcodeproj -scheme OpenKey -configuration Release \
  -derivedDataPath "$OUT/dd" ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build -quiet
APP="$OUT/$APP_NAME.app"
cp -R "$OUT/dd/Build/Products/Release/$APP_NAME.app" "$APP"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"

codesign --force --options runtime --timestamp --entitlements OpenKey.entitlements --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
ditto -c -k --keepParent "$APP" "$OUT/notarize.zip"
xcrun notarytool submit "$OUT/notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
spctl -a -vvv -t exec "$APP"

ZIP="$OUT/OpenKey-CE-$VERSION.zip"
DMG="$OUT/OpenKey-CE-$VERSION.dmg"
ditto -c -k --keepParent "$APP" "$ZIP"
STAGE="$OUT/dmg"; mkdir -p "$STAGE"; cp -R "$APP" "$STAGE/"; ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
codesign --force --timestamp --sign "$IDENTITY" "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
shasum -a 256 "$ZIP" "$DMG"
