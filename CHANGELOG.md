# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.7] - 2025-06-09

### Added

- `Cycle#considered_dates` to get the subset of `#covered_dates` that are
  considered for the cycle's calculations.

### Fixed

- `Cycles::Lookback.volume_to_delay_expiration` now computes correctly when the
  `#considered_dates` is smaller than the `#covered_dates` of the cycle.

## [0.1.6] - 2024-09-04

### Added

- `Cycle.extend_period(count)` to get a new cycle with the modified period count
