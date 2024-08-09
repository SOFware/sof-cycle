# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] - Unreleased

## [0.1.1] - 2024-08-09

### Added

- Basic example in README.md
- Add `Cycles::EndOf` to handle cycles that cover through the end of the nth
  subsequent period
- Add predicate methods for each `Cycle` subclass. E.g. `#dormant?`, `#within?`, etc
- Refactor into namespaces
