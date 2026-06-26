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

# Unregister ALL DerivedData MacDown builds from LaunchServices to prevent
# duplicate "Open with MacDown" entries in Finder's right-click menu.
# Xcode registers the app on every build via RegisterWithLaunchServices;
# we clean up both Debug and Release (and any other config) afterward.
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
DERIVED_BASE="$(xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -destination 'platform=macOS,arch=x86_64' -showBuildSettings 2>/dev/null | awk '/BUILT_PRODUCTS_DIR/{print $3}' | head -1)"
DERIVED_ROOT="$(dirname "$DERIVED_BASE")"  # .../Build/Products
for config_app in "$DERIVED_ROOT"/Debug/MacDown.app "$DERIVED_ROOT"/Release/MacDown.app; do
  if [ -d "$config_app" ]; then
    "$LSREG" -u "$config_app" 2>/dev/null || true
    echo "Unregistered $config_app from LaunchServices"
  fi
done
# Also unregister any MacDown.app found under DerivedData via Spotlight/mdfind
for stale in $(mdfind -onlyin "$HOME/Library/Developer/Xcode/DerivedData" "kMDItemDisplayName == 'MacDown.app'" 2>/dev/null); do
  if [ "$stale" != "/Applications/MacDown.app" ]; then
    "$LSREG" -u "$stale" 2>/dev/null || true
    echo "Unregistered stale $stale from LaunchServices"
  fi
done
