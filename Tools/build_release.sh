#!/usr/bin/env bash
# build_release.sh — Build MacDown in Release configuration and (optionally)
# install it to /Applications. This is the recommended way to produce the
# build that gets installed as the system MacDown — Release uses the proper
# bundle id (com.uranusjr.macdown) which is more stable for LaunchServices
# default-app bindings than the Debug bundle id (com.uranusjr.macdown-debug).
#
# Usage:
#   bash Tools/build_release.sh              # build only
#   bash Tools/build_release.sh --install    # build then overwrite /Applications/MacDown.app
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
  -configuration Release \
  -destination 'platform=macOS,arch=x86_64' \
  CODE_SIGNING_ALLOWED=NO \
  MACOSX_DEPLOYMENT_TARGET=10.13 \
  build

DERIVED_BASE="$(xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -configuration Release -destination 'platform=macOS,arch=x86_64' -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR /{print $3}' | head -1)"
RELEASE_APP="$DERIVED_BASE/MacDown.app"

if [ ! -d "$RELEASE_APP" ]; then
  echo "error: Release build not found at $RELEASE_APP" >&2
  exit 1
fi

echo "Release build: $RELEASE_APP"

# Optionally install to /Applications
if [ "${1:-}" = "--install" ]; then
  # Quit any running MacDown so we can overwrite it
  osascript -e 'tell application "MacDown" to quit' 2>/dev/null || true
  sleep 1
  rm -rf /Applications/MacDown.app
  cp -R "$RELEASE_APP" /Applications/MacDown.app
  echo "Installed to /Applications/MacDown.app"

  # Run mdclear if available to clean up LaunchServices duplicates and
  # re-bind .md/.markdown to the new install.
  if command -v mdclear >/dev/null 2>&1; then
    mdclear || true
  fi
fi

# Unregister AND DELETE any DerivedData MacDown.app — just unregistering is
# not enough; lsd / Spotlight will re-register it on next scan as long as the
# .app exists on disk, causing duplicates in Finder/Spotlight/App Store list.
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
DERIVED_ROOT="$(dirname "$DERIVED_BASE")"  # .../Build/Products
for config_app in "$DERIVED_ROOT"/Debug/MacDown.app "$DERIVED_ROOT"/Release/MacDown.app; do
  if [ -d "$config_app" ] && [ "$config_app" != "/Applications/MacDown.app" ]; then
    "$LSREG" -u "$config_app" 2>/dev/null || true
    rm -rf "$config_app" 2>/dev/null || true
    echo "Removed $config_app (unregistered + deleted)"
  fi
done
for stale in $(mdfind -onlyin "$HOME/Library/Developer/Xcode/DerivedData" "kMDItemFSName == 'MacDown.app'" 2>/dev/null); do
  if [ "$stale" != "/Applications/MacDown.app" ] && [ -d "$stale" ]; then
    "$LSREG" -u "$stale" 2>/dev/null || true
    rm -rf "$stale" 2>/dev/null || true
    echo "Removed stale $stale (unregistered + deleted)"
  fi
done
# One final lsd kick so the deleted entries actually disappear from the cache
killall lsd 2>/dev/null || true
