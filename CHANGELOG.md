# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.8] - 2025-09-04

### Changed

- Simplified `handles?` logic to do string comparison instead of symbol comparison.

## [0.1.7] - 2025-06-09

### Added

- `Cycle#considered_dates` to get the subset of `#covered_dates` that are
  considered for the cycle's calculations.

### Fixed

- `Cycles::Lookback.volume_to_delay_expiration` now computes correctly when the
  `#considered_dates` is smaller than the `#covered_dates` of the cycle.
