# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.13] - Unreleased

### Added

- Recurring cycle kind (`R` notation) — recurring windows anchored to a from_date (e.g., `V1R24MF2026-03-31`)

### Fixed

- EndOf cycle `final_date` was off by one period — `V1E12M` now correctly expires at the end of the 12th month, not the 11th

## [0.1.12] - 2025-09-05

### Added

- Missing code coverage and updated EndOf to properly handle dormant cycles.
