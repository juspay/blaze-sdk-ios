# Verify a release

Every [GitHub release](https://github.com/juspay/blaze-sdk-ios/releases) of BlazeSDK attaches three files:

| File | What it is |
| --- | --- |
| `BlazeSDK.xcframework.zip` | The SDK compiled for iPhone and the simulator, signed with Juspay's Apple Distribution certificate |
| `BlazeSDK.xcframework.zip.sha256` | The zip's SHA-256 checksum |
| `BlazeSDK.cdx.json` | A [CycloneDX](https://cyclonedx.org) 1.5 SBOM: the packages BlazeSDK depends on |

Swift Package Manager and CocoaPods build the SDK from source and do not use these files.

## Check the download

```bash
shasum -a 256 -c BlazeSDK.xcframework.zip.sha256
```

It prints `BlazeSDK.xcframework.zip: OK`.

## Check the signature

```bash
ditto -x -k BlazeSDK.xcframework.zip .
codesign --verify --strict --verbose=2 BlazeSDK.xcframework
codesign -dv --verbose=4 BlazeSDK.xcframework 2>&1 | grep -E 'Authority=Apple Distribution|TeamIdentifier'
```

The first `codesign` prints `valid on disk` and `satisfies its Designated Requirement`, and the second shows who signed it. `code object is not signed at all` means the file is not the one Juspay published.

## Check the SBOM

```bash
jq '.components' BlazeSDK.cdx.json
```

BlazeSDK uses only Apple's frameworks, so the list is empty: `[]`.

## Add the XCFramework to your app

In Xcode, select your app target, open **General > Frameworks, Libraries, and Embedded Content**, click **+**, choose **Add Other… > Add Files…** and pick `BlazeSDK.xcframework`. Set it to **Embed & Sign**.

The XCFramework includes the SDK's privacy manifest (`PrivacyInfo.xcprivacy`). Xcode 15 and later show who signed it in the File inspector, and warn when a later version is signed by someone else.
