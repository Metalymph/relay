# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog,
and this project adheres to Semantic Versioning.

## [0.2.1] - 2026-05-30

### Added

#### Valkey

- Typed client helpers:
  - ping()
  - get()
  - set()
  - del()
  - exists()
- Native integration tests against a real Valkey server.
- RESP parser coverage for:
  - Errors
  - Null bulk strings
  - Empty bulk strings
  - Null arrays
  - Empty arrays
  - Nested arrays
  - Invalid protocol inputs

#### Relay

- Functional Valkey-backed queue implementation.
- Queue operations:
  - push()
  - blocking pop()
  - non-blocking pop_nowait()
  - size()
- Integration tests for Valkey queue round-trips.

### Changed

#### Valkey

- RESP command encoding now correctly uses UTF-8 byte lengths for bulk string payloads.
- Improved RESP parser validation and protocol compliance.

#### Relay

- RedisBackend now performs real queue operations using Valkey instead of placeholder mock implementations.

### Fixed

#### Valkey

- Bulk string parsing now validates trailing CRLF terminators.
- Improved handling of malformed RESP messages and unexpected end-of-stream conditions.

## [0.1.0] - 2026-04-14

### Added

- Initial release of Metalymph/relay and Metalymph/valkey.
- Native async Valkey/Redis client for MoonBit.
- Distributed message queue (Relay) with pluggable backends.
- InMemoryBackend for high-performance local queuing.
- RedisBackend for distributed queuing using RESP client.
- WorkerPool with concurrency management and automatic Ack/Nack logic.
- GitHub Actions CI for automated build and test verification.
