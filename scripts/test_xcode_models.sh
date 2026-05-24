#!/bin/sh
set -eu

xcodebuild test \
  -project CleanArchiver.xcodeproj \
  -scheme CleanArchiver \
  -destination 'platform=macOS' \
  -derivedDataPath build/TestDerivedData
