#!/usr/bin/env bash
# Build an unsigned, unlimited personal IPA for signing with iloader 2.3.10.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This build requires macOS and Xcode. Run the Personal iPhone build GitHub workflow." >&2
  exit 1
fi

mkdir -p build/sideload
./scripts/bootstrap-llama.sh
xcodegen generate

common=(
  -project Sayboard.xcodeproj -scheme Sayboard
  -derivedDataPath build/DerivedData
  -clonedSourcePackagesDirPath build/SourcePackages
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM=
)

xcodebuild "${common[@]}" -resolvePackageDependencies 2>&1 | tee build/sideload/packages.log
xcodebuild "${common[@]}" \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  ARCHS=arm64 'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) SAYBOARD_SIDELOAD' \
  build 2>&1 | tee build/sideload/build.log

app=build/DerivedData/Build/Products/Release-iphoneos/Sayboard.app
test -d "$app/PlugIns/SayboardKeyboard.appex"
lipo "$app/Sayboard" -verify_arch arm64
lipo "$app/PlugIns/SayboardKeyboard.appex/SayboardKeyboard" -verify_arch arm64
# Capture the effective conditions, rather than assuming the command-line flag won.
xcodebuild "${common[@]}" \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  ARCHS=arm64 'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) SAYBOARD_SIDELOAD' \
  -showBuildSettings > build/sideload/build-settings.txt
python3 - <<'PY'
from pathlib import Path

settings = Path('build/sideload/build-settings.txt').read_text()
conditions = [line.split(' = ', 1)[1].split() for line in settings.splitlines()
              if line.strip().startswith('SWIFT_ACTIVE_COMPILATION_CONDITIONS = ')]
assert conditions and all('SAYBOARD_SIDELOAD' in flags and 'APPSTORE' not in flags
                          for flags in conditions), conditions
PY

# ditto preserves framework symlinks and bundle permissions needed by the signer.
# A fresh staging directory also prevents stale files appearing in a rebuild.
staging=$(mktemp -d build/sideload/staging.XXXXXX)
trap 'rm -rf "$staging"' EXIT
mkdir "$staging/Payload"
ditto "$app" "$staging/Payload/Sayboard.app"
ditto -c -k --sequesterRsrc --keepParent "$staging/Payload" build/sideload/Sayboard.ipa
python3 scripts/verify-sideload-ipa.py build/sideload/Sayboard.ipa
git rev-parse HEAD > build/sideload/source-revision.txt
xcodebuild -version > build/sideload/xcode-version.txt
(cd build/sideload && shasum -a 256 Sayboard.ipa > Sayboard.ipa.sha256)
bash scripts/prepare-sidestore.sh build/sideload/Sayboard.ipa build/sideload/Sayboard-SideStore.ipa
echo 'IPA ready: build/sideload/Sayboard.ipa (unsigned; install using iloader)'
