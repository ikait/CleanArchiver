# CleanArchiver

CleanArchiver is a simple and nifty archiving utility.

It creates **clean** gzip, bzip2, zip and compressed Disk Image archives
that don't include annoying files such as .DS_Store, Icon\r and .\_\*.

CleanArchiver is currently maintained as a compact Apple silicon macOS app.
The application UI is Objective-C/AppKit, archive creation is handled by small
native Objective-C classes, and the bundled command-line dependency is the
modified Info-ZIP `zip` executable.

## Supported Formats

* gzip
* bzip2
* zip
* compressed Disk Image (`.dmg`)

## Requirements

* Apple silicon Mac
* macOS 11 or later
* Xcode

## Build and Test

```sh
sh scripts/build_release_app.sh
sh scripts/test_xcode_models.sh
sh scripts/test_archive_outputs.sh
```

## Release

Push a tag that matches `MARKETING_VERSION`. GitHub Actions builds the app,
archives it as `CleanArchiver-<version>-macOS-arm64.zip`, and attaches the zip
to a GitHub Release.

Release artifacts are ad-hoc signed and are not notarized.
