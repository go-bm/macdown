#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found. Install full Xcode and run xcode-select if needed." >&2
  exit 1
fi

if [ ! -d "Pods" ]; then
  if ! command -v pod >/dev/null 2>&1; then
    echo "error: CocoaPods not found. Install with: brew install cocoapods" >&2
    exit 1
  fi
  pod install
fi

xcodebuild \
  -workspace MacDown.xcworkspace \
  -scheme MacDown \
  -destination 'platform=macOS,arch=x86_64' \
  MACOSX_DEPLOYMENT_TARGET=10.13 \
  build
