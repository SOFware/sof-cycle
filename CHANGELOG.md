# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.13] - Unreleased

### Added

- RepeatingWithin cycle kind (`I` notation) — a Within that repeats, re-anchoring from the completion date after satisfaction (e.g., `V1I24MF2026-03-31`)
- `reactivated_notation(date)` alias for `activated_notation` — self-documenting call site when re-anchoring a satisfied cycle

## [0.1.12] - 2025-09-05

### Added

- Missing code coverage and updated EndOf to properly handle dormant cycles.
