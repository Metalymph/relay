# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-14

### Added

- Initial release of **Metalymph/relay** and **Metalymph/valkey**.
- Native async Valkey/Redis client for MoonBit.
- Distributed message queue (Relay) with pluggable backends.
- `InMemoryBackend` for high-performance local queuing.
- `RedisBackend` for distributed queuing using RESP client.
- `WorkerPool` with concurrency management and automatic Ack/Nack logic.
- GitHub Actions CI for automated build and test verification.
