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

# Unregister DerivedData build from LaunchServices to prevent duplicate
# "Open with MacDown" entries in Finder's right-click menu.
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
DERIVED_APP="$(xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -destination 'platform=macOS,arch=x86_64' -showBuildSettings 2>/dev/null | awk '/BUILT_PRODUCTS_DIR/{print $3}' | head -1)/MacDown.app"
if [ -n "$DERIVED_APP" ] && [ -d "$DERIVED_APP" ]; then
  "$LSREG" -u "$DERIVED_APP" 2>/dev/null || true
  echo "Unregistered $DERIVED_APP from LaunchServices"
fi
