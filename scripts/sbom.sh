#!/usr/bin/env bash
#
# Usage: bash scripts/sbom.sh <version> > BlazeSDK.cdx.json

set -euo pipefail

work=""

parse_args() {
  if [[ $# -ne 1 ]]; then
    echo "usage: sbom.sh <version>" >&2
    exit 2
  fi
}

dependency_graph() {
  mkdir -p "$work/package/Example"
  cp -R Package.swift BlazeSDK "$work/package/"
  cp -R Example/Tests "$work/package/Example/"
  swift package --package-path "$work/package" --scratch-path "$work/build" show-dependencies --format json
}

to_cyclonedx() {
  local version=$1 serial timestamp
  serial="urn:uuid:$(uuidgen | tr '[:upper:]' '[:lower:]')"
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  jq --arg version "$version" --arg serial "$serial" --arg timestamp "$timestamp" '
    def nodes: ., (.dependencies[] | nodes);
    def purl: "pkg:swift/" + (.url | sub("^[a-z]+://"; "") | sub("\\.git$"; "")) + "@" + .version;
    ([.dependencies[] | nodes] | unique_by(.identity)) as $packages
    | {
        bomFormat: "CycloneDX",
        specVersion: "1.5",
        serialNumber: $serial,
        version: 1,
        metadata: {
          timestamp: $timestamp,
          component: {
            type: "library",
            "bom-ref": "BlazeSDK",
            name: "BlazeSDK",
            version: $version,
            purl: ("pkg:swift/github.com/juspay/blaze-sdk-ios@" + $version),
            licenses: [{ license: { id: "MIT" } }]
          }
        },
        components: [$packages[] | { type: "library", "bom-ref": .identity, name: .name, version: .version, purl: purl }],
        dependencies: (
          [{ ref: "BlazeSDK", dependsOn: [.dependencies[].identity] }]
          + [$packages[] | { ref: .identity, dependsOn: [.dependencies[].identity] }]
        )
      }'
}

main() {
  parse_args "$@"
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  dependency_graph > "$work/graph.json"
  to_cyclonedx "$1" < "$work/graph.json"
}

main "$@"
