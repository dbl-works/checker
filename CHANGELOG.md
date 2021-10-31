# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.3] - 2021-10-31
### Added
- basic tests
### Fixed
- fixed missing usage of inflections path
- fixed checking for file path
- ensure to store NULL instead of empty string if there are no errors

## [0.3.0] - 2021-10-31
### Fixed
- allow passing the file path to custom Rails inflections for infering class names from file names correctly

## [0.2.0] - 2021-10-30
### Changed
- backend is now configurable to publish check results to either: Local DB (Rails), Slack, DBL-Checker-Platform (remote server)
- brushed up the Readme
- added Rails generators for persisting check results locally within the app

## [0.1.0] - 2021-10-23
### Added
- initial release
