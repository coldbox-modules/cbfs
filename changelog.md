# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

## Fixed

* Issue #49 - Fix windows pathing issues when the disk path is relative or mapped

## [1.1.2] - 2023-05-18

### Fixed

* Fixes an issue where temporary URLs would generate incorrect URLs for AWS

## [1.1.1] - 2023-05-12

### Fixed

* Fixes an issue where `createFromFile` would not clear the existence check cache
* Fixes an incorrect source assigment and method signature for the File object `createFromFile` method

### Added

* Adds the force argument to the File exists method for correct disk pass-through
* Adds the `name` method to the File object

## [1.1.0] - 2023-05-01

### Added

* New Github actions
* ColdBox 7 Auto-Testing
* Added url(), temporaryURL(), and download() methods to the File object.

## [1.0.3] => 2023-03-15

### Fixed

* Fix for Adobe S3 request returning ByteArrayOutputStream
* Fix ROOT folder issues with S3
* Fix when referencing root folder
* Fix calling temporaryURL() on s3 provider
* Throw error if the source does not exist in S3 Provider

## [1.1.0] => 2023-03-31

### Added

* Ability to pass response headers to temporaryURL() when using S3 provider.

## [1.0.2] => 2023-01-03

### Fixed

* Fixes an issue where Lucee would not retrieve the correct binary contents of a file
* Ensures explicity content types are sent with the S3 put headers

## [1.0.1] => 2022-DEC-29

### Fixed

* Issue #35 - JSON/JS/XML files being returned as binary

## [1.0.0] => 2022-NOV-24

* First iteration of this module

[Unreleased]: https://github.com/coldbox-modules/cbfs/compare/v1.1.2...HEAD

[1.1.2]: https://github.com/coldbox-modules/cbfs/compare/v1.1.1...v1.1.2

[1.1.1]: https://github.com/coldbox-modules/cbfs/compare/v1.1.0...v1.1.1

[1.1.0]: https://github.com/coldbox-modules/cbfs/compare/f76a3372a803a53759c6f707e740b26aab71dcc3...v1.1.0
