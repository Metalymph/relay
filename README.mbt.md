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
- RedisBackend (Lists)
- RedisStreamBackend (Streams + Consumer Groups)

### Planned

- NATS JetStream
- RabbitMQ
- Kafka
- Amazon SQS

---

## Installation

Add Relay to your MoonBit project:

```json
{
  "deps": {
    "Metalymph/relay": "latest"
  }
}
```

Import:

```moonbit
import "Metalymph/relay"
```

---

## Quick Start

### In-Memory Queue

```moonbit
import "Metalymph/relay"

let backend = relay.InMemoryBackend::new(
  100,
  policy=relay.RetryPolicy::default(),
)

let queue = backend.to_relay_queue()

queue.push("hello")
let msg = queue.pop()

println(msg.payload)
```

---

### Worker Pool

```moonbit
let pool = relay.WorkerPool::new(
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

### v0.4.1

- Valkey repository separation
- MIT licensing alignment
- Additional examples
- Documentation refinements

### v0.5.x

- NATS JetStream backend
- NATS capability design
- Stream-oriented capability extensions
- JetStream operational mapping
- JetStream incident and pending-message integration

### v0.6.x

- Backend capability expansion
- Backend abstraction refinement
- Cross-backend delivery semantics documentation
- Backend requirements documentation
- Operational model hardening after NATS integration

### v0.7.x

- RabbitMQ backend
- AMQP capability extensions
- Queue topology support
- Exchange/routing-key mapping

### v0.8.x

- Kafka backend
- Partition-aware capabilities
- Consumer group integrations
- Offset-oriented operational mapping

### Future

- Amazon SQS backend
- Native OpenTelemetry integrations
- Native Prometheus integrations
- Additional backend ecosystem
- Monitoring dashboards

---

## License

MIT
