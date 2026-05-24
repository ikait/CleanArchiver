#!/bin/sh
set -eu

APP="${1:-build/DerivedData/Build/Products/Release/CleanArchiver.app}"

test -d "$APP"
test ! -e "$APP/Contents/Resources/carc"
test ! -e "$APP/Contents/Resources/mkdmg"
file "$APP/Contents/MacOS/CleanArchiver" | grep -q 'arm64'
file "$APP/Contents/Resources/zip" | grep -q 'arm64'
codesign --verify --deep --strict "$APP"

ROOT="${TMPDIR:-/tmp}/cleanarchiver-test-$$"
HARNESS="$ROOT/CarcArchiveTest"
mkdir -p "$ROOT"
trap 'hdiutil detach "$ROOT/Volume" >/dev/null 2>&1 || true; rm -rf "$ROOT"' EXIT HUP INT TERM

/usr/bin/xcrun clang \
  -fobjc-arc \
  -fconstant-string-class=NSConstantString \
  -framework Foundation \
  -I CleanArchiver \
  Tests/CarcArchiveTest.m \
  CleanArchiver/Carc.m \
  -o "$HARNESS"

OUTPUT_DIR="$(CLEANARCHIVER_RESOURCE_PATH="$APP/Contents/Resources" "$HARNESS" "$ROOT/run")"

unzip -Z1 "$OUTPUT_DIR/sample.zip" | grep -q 'Sample Folder/hello.txt'
! unzip -Z1 "$OUTPUT_DIR/sample.zip" | grep -q '.DS_Store'
! unzip -Z1 "$OUTPUT_DIR/sample.zip" | grep -q 'skip.txt'

test "$(gzip -cd "$OUTPUT_DIR/hello.txt.gz")" = "Hello from CleanArchiver"
tar -tjf "$OUTPUT_DIR/sample.tar.bz2" | grep -q 'Sample Folder/nested/inside.txt'
! tar -tjf "$OUTPUT_DIR/sample.tar.bz2" | grep -q '.DS_Store'
! tar -tjf "$OUTPUT_DIR/sample.tar.bz2" | grep -q 'skip.txt'

hdiutil imageinfo "$OUTPUT_DIR/sample.dmg" | grep -q 'Format: UDZO'

echo "Archive smoke tests passed"
