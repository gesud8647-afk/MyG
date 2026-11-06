#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo 'Usa GitHub Actions: serve macOS con Xcode.' >&2; exit 1; }
python3 scripts/configure_project.py
xcodebuild -version
mkdir -p dist
rm -f dist/MyG-unsigned.ipa
check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT
swiftc MyG/SignalMath.swift tests/SignalChecks/main.swift -o "$check_dir/myg-signal-checks"
"$check_dir/myg-signal-checks"
rm -rf "$check_dir"
trap - EXIT
xcodebuild \
  -project MyG.xcodeproj -scheme MyG -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' \
  build
app="$PWD/build/Build/Products/Release-iphoneos/MyG.app"
test -d "$app"
platform=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleSupportedPlatforms:0' "$app/Info.plist")
[[ "$platform" == iPhoneOS ]]
lipo "$app/MyG" -verify_arch arm64
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/Payload"
ditto "$app" "$staging/Payload/MyG.app"
out="$PWD/dist/MyG-unsigned.ipa"
(cd "$staging" && /usr/bin/zip -qry "$out" Payload)
python3 scripts/check_ipa.py "$out"
echo 'IPA NON FIRMATO creato: firma con Sideloadly prima di installare.'
