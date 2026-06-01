# Contributing

Thank you for your interest in contributing to Relay.

This document describes the development workflow, project structure, and contribution guidelines.

---

## Philosophy

Relay aims to be:

- Backend-agnostic
- Async-first
- Reliable
- Observable
- Easy to integrate

Contributions should preserve these goals.

When introducing new features, prefer generic abstractions over backend-specific behavior.

---

## Development Setup

Clone the repository:

```sh
git clone https://github.com/Metalymph/relay.git
cd relay
```

Verify the project:

```sh
moon check --target native
```

Run tests:

```sh
moon test --target native
```

---

## Repository Structure

```text
relay/
├─ relay/
│  ├─ queue primitives
│  ├─ backends
│  ├─ telemetry
│  ├─ observability
│  ├─ operations
│  ├─ incidents
│  └─ exporters
│
└─ valkey/
   └─ RESP client
```

---

## Branch Workflow

Create feature branches from master:

```sh
git checkout master
git pull origin master

git checkout -b feature-name
```

Examples:

```text
relay/worker-reliability
relay/telemetry
relay/observability
relay/incidents
```

After merge:

```sh
git checkout master
git pull origin master

git branch -d feature-name
```

Merged remote branches should be removed to keep the repository clean.

---

## Coding Guidelines

### Keep APIs Generic

Prefer:

```text
BackendCapabilities
```

instead of:

```text
if backend is RedisBackend
```

Avoid backend-specific assumptions whenever possible.

### Favor Composition

Prefer small reusable models:

```text
RelaySnapshot
QueueInspection
AdminReport
TelemetryEvent
```

instead of large monolithic structures.

### Preserve Layering

Current architecture:

```text
Telemetry
    ↓
RelaySnapshot

Observability
    ↓
SystemStatus

Operations
    ↓
QueueInspection

Administration
    ↓
AdminReport

Incidents
    ↓
Incident
    ↓
IncidentSeverity

Exports
    ↓
OtelRecord
PrometheusMetric
```

New features should fit naturally into this pipeline.

---

## Testing

All changes should include tests when applicable.

Before opening a pull request:

```sh
moon check --target native
moon test --target native
```

Expected result:

```text
0 failures
```

---

## Documentation

Public API changes should be reflected in:

- README.md
- ARCHITECTURE.md
- CHANGELOG.md

when relevant.

Major architectural changes should also update architecture documentation.

---

## Pull Requests

Pull requests should contain:

- concise title
- clear summary
- testing notes

Example:

```text
Add incident severity classification
```

Include validation steps:

```sh
moon check --target native
moon test --target native
```

---

## Roadmap

### Near-Term Priorities

- Documentation improvements
- Additional examples
- Valkey repository separation

### Future Goals

- NATS JetStream backend
- RabbitMQ backend
- Kafka backend
- Native exporter integrations

---

## Versioning

Relay follows Semantic Versioning.

```text
MAJOR.MINOR.PATCH
```

Examples:

```text
0.4.0
0.4.1
0.5.0
```

Breaking changes should be clearly documented.

---

## License

By contributing, you agree that your contributions will be licensed under the project's MIT license.
