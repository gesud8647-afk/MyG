#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'La compilazione richiede macOS con Xcode. Esegui il workflow GitHub Actions.' >&2
  exit 1
fi
xcodebuild -version
mkdir -p dist
rm -f dist/MyG-unsigned.ipa
xcodebuild \
  -project MyG.xcodeproj \
  -scheme MyG \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  build 2>&1 | tee build.log
app="$PWD/build/Build/Products/Release-iphoneos/MyG.app"
test -d "$app"
/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Info.plist"
platform=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleSupportedPlatforms:0' "$app/Info.plist")
[[ "$platform" == iPhoneOS ]]
lipo -verify_arch arm64 "$app/MyG"
python3 - "$app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    p = plistlib.load(f)
assert p.get('NSBluetoothAlwaysUsageDescription'), 'Manca descrizione Bluetooth'
assert p['CFBundlePackageType'] == 'APPL'
PY
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/Payload"
# ditto conserva framework, permessi eseguibili e risorse del bundle.
ditto "$app" "$staging/Payload/MyG.app"
out="$PWD/dist/MyG-unsigned.ipa"
(cd "$staging" && /usr/bin/zip -qry "$out" Payload)
python3 scripts/check_ipa.py "$out"
shasum -a 256 "$out"
echo 'IPA compilato ma NON FIRMATO: firma richiesta prima di installarlo.'
