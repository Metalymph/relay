# Relay Architecture

Relay is an asynchronous message queue library for MoonBit built around pluggable backends, reliability primitives, and observability tooling.

The project is composed of two major components:

- Relay — asynchronous queue abstraction and operational tooling
- Valkey — native RESP client used by Redis-based backends

---

## Design Goals

Relay is designed around the following principles:

- Backend-agnostic queue APIs
- At-least-once delivery
- Explicit reliability primitives
- Operational visibility
- Future observability integrations
- Minimal runtime dependencies

Relay consumers should interact with queue abstractions rather than backend-specific implementations.

---

## Core Queue Model

```text
Producer
    │
    ▼
RelayQueue[T]
    │
    ▼
Backend
    │
    ▼
Consumer
```

RelayQueue provides a unified interface regardless of storage implementation.

Current backends:

- InMemoryBackend
- RedisBackend
- RedisStreamBackend

Future backends:

- RabbitMQ
- NATS JetStream
- Kafka
- Amazon SQS

---

## Message Lifecycle

```text
Push
 │
 ▼
Queue
 │
 ▼
Pop
 │
 ▼
Worker
 │
 ├── Success
 │     │
 │     ▼
 │    Ack
 │
 └── Failure
       │
       ▼
      Nack
       │
       ├── Retry
       │
       └── Dead Letter Queue
```

Relay implements at-least-once delivery semantics.

Messages may be retried according to RetryPolicy before being routed to a dead letter queue.

---

## Reliability Layer

Relay reliability is built on:

- RetryPolicy
- NackResult
- Dead Letter Queue support
- Worker statistics
- Pending message recovery

Important types:

```text
RetryPolicy
NackResult
WorkerStats
WorkerMetrics
```

---

## Telemetry Architecture

Relay exposes telemetry as structured data.

```text
WorkerMetrics
QueueMetrics
BackendHealth
        │
        ▼
   RelayMetrics
        │
        ▼
  RelaySnapshot
```

Telemetry is backend-agnostic.

---

## Observability Architecture

Relay snapshots are transformed into operational state.

```text
RelaySnapshot
      │
      ▼
SystemStatus
```

Possible statuses:

- Healthy
- Degraded
- Unhealthy

These statuses provide a simplified operational view of the system.

---

## Operations Layer

Operational inspection APIs are built on top of telemetry.

```text
RelaySnapshot
      │
      ▼
QueueInspection
```

QueueInspection provides:

- Queue size
- DLQ size
- Pending count
- Backend health
- Human-readable summaries

---

## Administrative Reporting

Administrative tooling consumes QueueInspection.

```text
QueueInspection
       │
       ▼
AdminReport
```

AdminReport provides:

- Operational summaries
- Incident awareness
- Health evaluation
- Attention requirements

---

## Backend Capability Model

Relay does not assume all backends support the same features.

```text
BackendCapabilities
```

Examples:

```text
supports_ack
supports_dlq
supports_pending
supports_consumer_groups
supports_health_checks
supports_telemetry
```

This enables future backends without introducing backend-specific logic.

---

## Incident Detection

Administrative reports can be analyzed to generate incidents.

```text
AdminReport
      │
      ▼
Incident[]
```

Current incident types:

- BackendUnavailable
- WorkerFailures
- DeadLetterMessages
- PendingMessages

Incident detection can optionally use backend capabilities to avoid false positives.

---

## Incident Severity

Incidents are classified by severity.

```text
Info
Warning
Critical
```

Severity aggregation enables prioritization for monitoring and alerting systems.

---

## Export Pipeline

Relay provides normalized export models.

```text
AdminReport
     +
 Incident[]
        │
        ▼
TelemetryEvent
```

TelemetryEvent can be transformed into:

```text
OtelRecord
PrometheusMetric
```

This design keeps observability integrations independent from the Relay core.

---

## Future Direction

Planned areas of development include:

- Additional queue backends
- Native OpenTelemetry exporters
- Prometheus endpoints
- Monitoring integrations
- Administrative tooling
- Dashboard applications

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

A future release may split Valkey into a dedicated repository while preserving Relay's backend-agnostic architecture.
