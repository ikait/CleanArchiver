#!/bin/sh
set -eu

APP="${1:?usage: verify_release_metadata.sh <app> <version> <max-size-kib>}"
EXPECTED_VERSION="${2:?usage: verify_release_metadata.sh <app> <version> <max-size-kib>}"
MAX_SIZE_KIB="${3:?usage: verify_release_metadata.sh <app> <version> <max-size-kib>}"

INFO_PLIST="$APP/Contents/Info.plist"
EXECUTABLE="$APP/Contents/MacOS/CleanArchiver"
ZIP="$APP/Contents/Resources/zip"

test -d "$APP"
test -f "$INFO_PLIST"
test -x "$EXECUTABLE"
test -x "$ZIP"
test ! -e "$APP/Contents/Resources/carc"
test ! -e "$APP/Contents/Resources/mkdmg"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
if [ "$VERSION" != "$EXPECTED_VERSION" ]; then
  echo "version mismatch: app has $VERSION, expected $EXPECTED_VERSION" >&2
  exit 1
fi

file "$EXECUTABLE" | grep -q 'arm64'
file "$ZIP" | grep -q 'arm64'

SIZE_KIB="$(du -sk "$APP" | awk '{print $1}')"
if [ "$SIZE_KIB" -gt "$MAX_SIZE_KIB" ]; then
  echo "app too large: ${SIZE_KIB} KiB > ${MAX_SIZE_KIB} KiB" >&2
  exit 1
fi

echo "Release metadata verified: version ${VERSION}, ${SIZE_KIB} KiB"
