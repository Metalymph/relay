# Backend Capabilities

## Overview

Relay is designed to operate across multiple messaging systems without assuming identical backend behavior.

Each backend exposes a set of capabilities that describe the features it supports.

Capabilities allow Relay to:

- Adapt operational reporting
- Adapt incident detection
- Adapt telemetry collection
- Adapt observability evaluation
- Avoid backend-specific assumptions

Capabilities describe behavior, not implementation details.

---

## Reliability Capabilities

### supports_ack

Backend supports explicit message acknowledgment.

Examples:

- NATS JetStream
- RabbitMQ
- Kafka (offset commits)

---

### supports_nack

Backend supports explicit negative acknowledgment.

Examples:

- NATS JetStream
- RabbitMQ

---

### supports_dlq

Backend supports dead-letter queue routing.

Examples:

- NATS JetStream
- RabbitMQ
- Amazon SQS

---

### supports_redelivery

Backend supports automatic message redelivery after failure.

Examples:

- NATS JetStream
- RabbitMQ

---

### supports_pending

Backend exposes pending or unacknowledged message information.

Examples:

- NATS JetStream
- RabbitMQ
- Kafka Consumer Groups

---

## Consumer Capabilities

### supports_consumer_groups

Backend supports consumer coordination.

Examples:

- Redis Streams
- NATS JetStream
- Kafka

---

### supports_pull_consumers

Backend supports pull-based consumption.

Examples:

- NATS JetStream
- Kafka

---

### supports_push_consumers

Backend supports push-based consumption.

Examples:

- NATS JetStream
- RabbitMQ

---

### supports_durable_consumers

Backend supports persistent consumer state.

Examples:

- NATS JetStream
- Kafka Consumer Groups

---

## Messaging Model Capabilities

### supports_streams

Backend supports append-only stream semantics.

Examples:

- Redis Streams
- NATS JetStream
- Kafka

---

### supports_subjects

Backend supports subject or topic routing.

Examples:

- NATS
- Kafka Topics

---

### supports_ordering

Backend provides ordering guarantees.

Ordering guarantees are backend-specific.

Examples:

- Redis Streams
- Kafka Partitions
- NATS Streams

---

### supports_message_delay

Backend supports delayed delivery.

Examples:

- RabbitMQ (plugins)
- Amazon SQS

---

## Operational Capabilities

### supports_health_checks

Backend exposes health information.

Examples:

- Connection health
- Cluster health
- Stream health

---

### supports_telemetry

Backend exposes operational metrics.

Examples:

- Queue depth
- Consumer lag
- Pending messages
- Delivery statistics

---

## Capability Usage

Relay uses capabilities to:

- Enable backend-aware incident detection
- Enable backend-aware observability
- Enable backend-aware reporting
- Prevent unsupported operations
- Adapt telemetry generation

Backends may support additional features beyond those defined here.

Relay only relies on documented capabilities.