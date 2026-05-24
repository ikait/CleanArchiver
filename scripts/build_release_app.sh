#!/bin/sh
set -eu

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build/DerivedData}"
CONFIGURATION="${CONFIGURATION:-Release}"

xcodebuild \
  -project CleanArchiver.xcodeproj \
  -scheme CleanArchiver \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  clean build
