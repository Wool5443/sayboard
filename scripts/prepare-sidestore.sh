#!/usr/bin/env bash
# Add discoverable App Group metadata; SideStore replaces the ad-hoc signature.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin || $# != 2 ]]; then
  echo "Usage (on macOS): bash scripts/prepare-sidestore.sh INPUT.ipa OUTPUT.ipa" >&2
  exit 1
fi
source_ipa=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve())' "$1")
output_ipa=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve())' "$2")
if [[ "$source_ipa" == "$output_ipa" ]]; then
  echo "Keep the original iloader IPA: input and output must differ." >&2
  exit 1
fi
python3 scripts/verify-sideload-ipa.py "$source_ipa"
staging=$(mktemp -d /tmp/sayboard-sidestore.XXXXXX)
trap 'rm -rf "$staging"' EXIT
ditto -x -k "$source_ipa" "$staging"
app="$staging/Payload/Sayboard.app"
keyboard="$app/PlugIns/SayboardKeyboard.appex"

# Both signers append the same team ID. group.app.sayboard therefore becomes
# group.app.sayboard.<team>, preserving the group used by the iloader install.
python3 - "$staging/entitlements.plist" <<'PY'
import plistlib
import sys
with open(sys.argv[1], 'wb') as output:
    plistlib.dump({'com.apple.security.application-groups': ['group.app.sayboard']}, output)
PY

app_code=$(otool -s __TEXT __text "$app/Sayboard" | shasum -a 256)
keyboard_code=$(otool -s __TEXT __text "$keyboard/SayboardKeyboard" | shasum -a 256)
# Sign nested code first so the outer resource seals cover the final files.
while IFS= read -r -d '' nested; do
  codesign --force --sign - --timestamp=none "$nested"
done < <(find "$app" -depth \( -name '*.framework' -o -name '*.dylib' \) -print0)
codesign --force --sign - --timestamp=none --entitlements "$staging/entitlements.plist" "$keyboard"
codesign --force --sign - --timestamp=none --entitlements "$staging/entitlements.plist" "$app"
codesign --verify --deep --strict "$app"
test "$app_code" = "$(otool -s __TEXT __text "$app/Sayboard" | shasum -a 256)"
test "$keyboard_code" = "$(otool -s __TEXT __text "$keyboard/SayboardKeyboard" | shasum -a 256)"
mkdir -p "$(dirname "$output_ipa")"
ditto -c -k --sequesterRsrc --keepParent "$staging/Payload" "$output_ipa"
python3 scripts/verify-sideload-ipa.py "$output_ipa" --sidestore
(cd "$(dirname "$output_ipa")" && shasum -a 256 "$(basename "$output_ipa")" > "$(basename "$output_ipa").sha256")
echo "SideStore IPA ready: $output_ipa (ad-hoc signed; SideStore must re-sign it)"
