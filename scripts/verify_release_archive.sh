#!/bin/sh
set -eu

ARCHIVE="${1:?usage: verify_release_archive.sh <zip> <version> <max-size-kib>}"
EXPECTED_VERSION="${2:?usage: verify_release_archive.sh <zip> <version> <max-size-kib>}"
MAX_SIZE_KIB="${3:?usage: verify_release_archive.sh <zip> <version> <max-size-kib>}"

test -f "$ARCHIVE"
case "$ARCHIVE" in
  *-macOS-arm64.zip) ;;
  *)
    echo "archive name must end with -macOS-arm64.zip: $ARCHIVE" >&2
    exit 1
    ;;
esac

ROOT="${TMPDIR:-/tmp}/cleanarchiver-release-archive-$$"
trap 'rm -rf "$ROOT"' EXIT HUP INT TERM
mkdir -p "$ROOT"

ditto -x -k "$ARCHIVE" "$ROOT"
APP="$ROOT/CleanArchiver.app"
sh scripts/verify_release_metadata.sh "$APP" "$EXPECTED_VERSION" "$MAX_SIZE_KIB"

test ! -e "$APP/Contents/Resources/carc"
test ! -e "$APP/Contents/Resources/mkdmg"
test ! -d "$APP/Contents/Frameworks"
file "$APP/Contents/MacOS/CleanArchiver" | grep -q 'arm64'
if file "$APP/Contents/MacOS/CleanArchiver" | grep -q 'x86_64'; then
  echo "app executable must not contain x86_64" >&2
  exit 1
fi

codesign --verify --deep --strict "$APP"
echo "Release archive verified: $ARCHIVE"
