#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo 'Compila con GitHub Actions: richiede macOS e Xcode.' >&2; exit 1; }
python3 scripts/generate_project.py
xcodebuild -version
scratch_checks=$(mktemp -d)
trap 'rm -rf "$scratch_checks"' EXIT
swiftc ECO/EcoModel.swift ECO/EcoStore.swift tests/RulesChecks/main.swift -o "$scratch_checks/eco-checks"
"$scratch_checks/eco-checks"
mkdir -p dist
rm -f dist/ECO-unsigned.ipa
xcodebuild -project ECO.xcodeproj -scheme ECO -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
app="$PWD/build/Build/Products/Release-iphoneos/ECO.app"
test -d "$app"
lipo "$app/ECO" -verify_arch arm64
platform=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleSupportedPlatforms:0' "$app/Info.plist")
[[ "$platform" == iPhoneOS ]]
mkdir -p "$scratch_checks/Payload"
ditto "$app" "$scratch_checks/Payload/ECO.app"
out="$PWD/dist/ECO-unsigned.ipa"
(cd "$scratch_checks" && /usr/bin/zip -qry "$out" Payload)
python3 scripts/check_ipa.py "$out"
echo 'ECO-unsigned.ipa creato: firma e installa con Sideloadly.'
