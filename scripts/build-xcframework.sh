#!/usr/bin/env bash

set -euo pipefail

readonly SLICES=(iphoneos iphonesimulator)

version=""
plist_version=""
out=""
identity=""
work=""
minimum=""
xcframework_args=()

fail() {
  echo "✗ $1" >&2
  exit 1
}

parse_args() {
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "usage: build-xcframework.sh <version> [output-dir]" >&2
    exit 2
  fi
  version=$1
  out=${2:-build/xcframework}
  identity=${APPLE_DIST_IDENTITY:-}
  plist_version=${version%%-*}
}

prepare_package() {
  mkdir -p "$work/package/Example"
  cp -R Package.swift BlazeSDK "$work/package/"
  cp -R Example/Tests "$work/package/Example/"
  sed -i '' 's/\.library(name: "BlazeSDK", targets: \["BlazeSDK"\])/.library(name: "BlazeSDK", type: .dynamic, targets: ["BlazeSDK"])/' \
    "$work/package/Package.swift"
  grep -q 'type: .dynamic' "$work/package/Package.swift" ||
    fail "Could not make the BlazeSDK product dynamic: has its declaration in Package.swift changed?"
  echo 'import BlazeSDK' > "$work/import.swift"
}

destination_for() {
  if [[ $1 == iphoneos ]]; then
    echo "generic/platform=iOS"
  else
    echo "generic/platform=iOS Simulator"
  fi
}

archive_slice() {
  local slice=$1 destination
  destination=$(destination_for "$slice")
  echo "Archiving for $destination"
  if ! (cd "$work/package" && xcodebuild archive -scheme BlazeSDK -destination "$destination" \
    -archivePath "$work/$slice.xcarchive" -derivedDataPath "$work/derived-$slice" \
    SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES CODE_SIGNING_ALLOWED=NO) > "$work/$slice.log" 2>&1; then
    tail -40 "$work/$slice.log" >&2
    fail "xcodebuild archive failed for $destination"
  fi
}

framework_of() {
  find "$work/$1.xcarchive/Products" -name BlazeSDK.framework -type d | head -1
}

swiftmodule_of() {
  find "$work/derived-$1/Build/Intermediates.noindex/ArchiveIntermediates" \
    -path '*/BuildProductsPath/*/BlazeSDK.swiftmodule' -type d | head -1
}

complete_framework() {
  local slice=$1 framework=$2 module
  module=$(swiftmodule_of "$slice")
  [[ -n $module ]] || fail "The $slice build produced no BlazeSDK.swiftmodule"

  mkdir -p "$framework/Modules"
  cp -R "$module" "$framework/Modules/"
  cp BlazeSDK/Resources/PrivacyInfo.xcprivacy "$framework/"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier in.breeze.BlazeSDK" \
    -c "Set :CFBundleShortVersionString $plist_version" -c "Set :CFBundleVersion $plist_version" \
    "$framework/Info.plist"

  ls "$framework/Modules/BlazeSDK.swiftmodule/"*.swiftinterface > /dev/null 2>&1 ||
    fail "The $slice slice has no .swiftinterface"
}

check_import() {
  local slice=$1 framework=$2 target
  minimum=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$framework/Info.plist")
  if [[ $slice == iphoneos ]]; then
    target="arm64-apple-ios$minimum"
  else
    target="arm64-apple-ios$minimum-simulator"
  fi
  xcrun --sdk "$slice" swiftc -typecheck -target "$target" -F "$(dirname "$framework")" "$work/import.swift" ||
    fail "An app could not import BlazeSDK from the $slice slice"
}

build_slice() {
  local slice=$1 framework dsym
  archive_slice "$slice"
  framework=$(framework_of "$slice")
  [[ -n $framework ]] || fail "The $slice archive has no BlazeSDK.framework"

  complete_framework "$slice" "$framework"
  check_import "$slice" "$framework"

  xcframework_args+=(-framework "$framework")
  dsym="$work/$slice.xcarchive/dSYMs/BlazeSDK.framework.dSYM"
  if [[ -d $dsym ]]; then
    xcframework_args+=(-debug-symbols "$dsym")
  fi
}

create_xcframework() {
  rm -rf "$out"
  mkdir -p "$out"
  xcodebuild -create-xcframework "${xcframework_args[@]}" -output "$out/BlazeSDK.xcframework" > /dev/null
}

sign_xcframework() {
  local timestamp=--timestamp
  if [[ -z $identity ]]; then
    echo "Not signed: set APPLE_DIST_IDENTITY to sign the XCFramework."
    return
  fi
  if [[ $identity == "-" ]]; then
    timestamp=--timestamp=none
  fi
  codesign "$timestamp" --sign "$identity" "$out/BlazeSDK.xcframework"
  codesign --verify --strict --verbose=2 "$out/BlazeSDK.xcframework"
}

zip_with_checksum() {
  (cd "$out" &&
    ditto -c -k --keepParent BlazeSDK.xcframework BlazeSDK.xcframework.zip &&
    shasum -a 256 BlazeSDK.xcframework.zip > BlazeSDK.xcframework.zip.sha256)
}

main() {
  parse_args "$@"
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  prepare_package
  local slice
  for slice in "${SLICES[@]}"; do
    build_slice "$slice"
  done
  create_xcframework
  sign_xcframework
  zip_with_checksum

  echo "Wrote $out/BlazeSDK.xcframework.zip ($version, minimum iOS $minimum) and its .sha256"
}

main "$@"
