# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-08-28

First release. A native macOS timer for practicing system design
interviews solo.

### Added

- Six-block practice session — Requirements, Core Entities,
  API/System Interface, Data Flow, High-Level Design, Deep Dives —
  45 minutes total, with Skip and Cancel.
- Native SwiftUI macOS app: floats in a corner of the screen during
  an active session, adapts to light/dark mode, full keyboard
  shortcuts, VoiceOver support.
- Session History: every session, completed or cancelled, is saved
  locally with a per-block breakdown, reviewable afterward.
- Recovery from an abandoned in-progress session (e.g. the app or
  machine was closed mid-session).
- `TimerCore`: a pure, platform-independent engine (state machine +
  Codable models + JSON persistence), covered by 29 tests — laid out
  to be reused by a planned iPhone companion app.
- Packaging: `scripts/package-app.sh` builds and ad-hoc signs a
  distributable `.app`.
- `docs/application-blueprint.md` (behavior spec) and
  `docs/technical-plan.md` (architecture, build history, and a
  Blueprint Conformance Review) — the project's source-of-truth
  documentation, not duplicated in the README.
- CI via GitHub Actions, running the test suite on every push and PR.

[Unreleased]: https://github.com/eebaez/timer-app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/eebaez/timer-app/releases/tag/v1.0.0
