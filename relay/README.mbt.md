# Relay

![Relay Rabbit Banner](assets/banner.png)

A backend-agnostic asynchronous message queue for MoonBit.

Relay provides pluggable queue backends, reliability primitives, operational inspection, incident detection, and observability foundations for distributed systems.

Built on top of the `moonbitlang/async` runtime.

---

## Features

- Generic `RelayQueue[T]`
- Backend-agnostic APIs
- Async-first architecture
- In-memory and Redis-based backends
- At-least-once delivery
- Retry policies and Dead Letter Queues
- Worker reliability tracking
- Telemetry and observability
- Administrative reporting
- Incident detection and severity classification
- OpenTelemetry-compatible export models
- Prometheus-compatible export models

---

## Backends

### Available

- InMemoryBackend

### External Adapters

- Valkey/Redis (available in the [`Metalymph/valkey`](https://github.com/Metalymph/valkey) repository)

### Planned

- NATS JetStream

---

## Installation

Add Relay to your MoonBit project:

```json
{
  "deps": {
    "Metalymph/relay": "0.5.0"
  }
}
```

Since Relay is modular, you must explicitly import the packages you need in your `moon.pkg`:

```json
{
  "import": [
    "Metalymph/relay/core",
    "Metalymph/relay/memory",
    "Metalymph/relay/worker"
  ]
}
```

---

## Quick Start

### In-Memory Queue

```moonbit
let backend = @memory.InMemoryBackend::new(
  100,
  policy=@core.RetryPolicy::default(),
)

let queue = backend.to_relay_queue()

queue.push("hello")
let msg = queue.pop()

println(msg.payload)
```

---

### Worker Pool

```moonbit
let pool = @worker.WorkerPool::new(
  queue,
  concurrency=4,
)

pool.run(async fn(payload) {
  println(payload)
})
```

Relay automatically performs:

- Ack on success
- Nack on failure
- Retry handling
- Dead-letter routing

---

## Reliability

### Retry Policy

```moonbit
let policy = relay.RetryPolicy::new(3)
```

Messages exceeding retry limits are routed to the dead letter queue.

### Nack Results

```moonbit
Requeued
SentToDlq
```

---

## Telemetry

Relay exposes structured telemetry.

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

Example:

```moonbit
let snapshot = relay.collect_snapshot(
  Some(worker_metrics),
  Some(queue_metrics),
  Some(health),
)
```

---

## Observability

Snapshots can be evaluated into operational status.

```moonbit
snapshot.status()
```

Possible results:

```text
Healthy
Degraded
Unhealthy
```

---

## Operations

Queue state can be inspected through operational APIs.

```moonbit
let inspection = relay.inspect(snapshot)
```

Available helpers:

```moonbit
inspection.is_empty()
inspection.has_pending()
inspection.has_dlq()
inspection.summary()
```

---

## Administrative Reporting

```moonbit
let report = relay.report(inspection)
```

Administrative reports provide:

- Health evaluation
- Incident awareness
- Human-readable summaries

---

## Incident Detection

Relay can derive incidents from operational reports.

```moonbit
let incidents =
  relay.detect_incidents(report)
```

Incident types:

```text
BackendUnavailable
WorkerFailures
DeadLetterMessages
PendingMessages
```

Capability-aware detection is also available.

---

## Incident Severity

```moonbit
incident.severity()
```

Possible values:

```text
Info
Warning
Critical
```

Severity aggregation:

```moonbit
highest_severity(incidents)
```

---

## OpenTelemetry-Compatible Export

```moonbit
let event =
  relay.from_report(
    report,
    incidents,
  )

let record =
  event.to_otel_record()
```

---

## Prometheus-Compatible Export

```moonbit
let metrics =
  event.to_prometheus_metrics()
```

Exports:

```text
relay_incident_count
relay_status
relay_severity
```

---

## Backend Capabilities

Relay does not assume identical backend behavior.

```moonbit
backend.capabilities()
```

Capability examples:

supports_ack
supports_nack
supports_dlq
supports_pending
supports_consumer_groups
supports_health_checks
supports_telemetry

Stream and backend-specific capability areas:

supports_streams
supports_subjects
supports_pull_consumers
supports_push_consumers
supports_durable_consumers
supports_redelivery
supports_ordering
supports_message_delay

Capabilities are used by Relay to adapt operational inspection, incident detection, and backend-specific reporting without hard-coding backend behavior.

---

## Additional Documentation

- ARCHITECTURE.md
- CONTRIBUTING.md
- CHANGELOG.md

---

## Roadmap

### v0.5.0 (Current)

- Modular repository architecture (core, memory, worker)
- Valkey repository separation
- MoonBit 0.10 upgrade and stabilization

### v0.6.x

- NATS JetStream backend integration (as a separate package/repository)
- NATS capability design and stream-oriented capability extensions
- JetStream operational mapping and incident integration

### Future Possibilities

- RabbitMQ backend
- Backend requirement specifications
- Native OpenTelemetry/Prometheus integrations
- Monitoring dashboards

---

## License

MIT
