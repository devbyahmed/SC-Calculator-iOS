#!/bin/sh
# Builds an UNSIGNED Numo.ipa for sideloading with a free Apple ID
# (SideStore / AltStore re-sign it with your account when installing).
# Run on your Mac from the project root:  sh scripts/build-ipa.sh
set -e

cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is missing. Install it with: brew install xcodegen"
  exit 1
fi

xcodegen

rm -rf build/ipa build/Numo.ipa
xcodebuild \
  -project Numo.xcodeproj \
  -scheme Numo \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build/derived \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

mkdir -p build/ipa/Payload
cp -R build/derived/Build/Products/Release-iphoneos/Numo.app build/ipa/Payload/
(cd build/ipa && zip -qry ../Numo.ipa Payload)

echo ""
echo "Done: build/Numo.ipa"
