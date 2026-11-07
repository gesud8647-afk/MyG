#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo 'Usa il workflow macOS su GitHub.' >&2; exit 1; }
xcodebuild -version
scratch_checks=$(mktemp -d)
trap 'rm -rf "$scratch_checks"' EXIT
swiftc PocketAI/PromptBuilder.swift PocketAI/SecurityRules.swift tests/PromptChecks/main.swift -o "$scratch_checks/prompt-checks"
"$scratch_checks/prompt-checks"
bash scripts/build-engine.sh
python3 scripts/generate_project.py
mkdir -p dist
rm -f dist/PocketAI-unsigned.ipa
xcodebuild -project PocketAI.xcodeproj -scheme PocketAI -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
app="$PWD/build/Build/Products/Release-iphoneos/PocketAI.app"
test -d "$app"
lipo "$app/PocketAI" -verify_arch arm64
mkdir -p "$scratch_checks/Payload"
ditto "$app" "$scratch_checks/Payload/PocketAI.app"
out="$PWD/dist/PocketAI-unsigned.ipa"
(cd "$scratch_checks" && /usr/bin/zip -qry "$out" Payload)
python3 scripts/check_ipa.py "$out"
echo 'IPA creato senza modello e senza firma. Firma con Sideloadly, poi importa Qwen GGUF.'
