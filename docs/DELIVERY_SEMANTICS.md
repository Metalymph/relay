# Delivery Semantics

## Overview

Relay provides a unified delivery model across multiple messaging backends.

Different backends offer different reliability guarantees and operational behaviors.

Relay standardizes these behaviors into a common semantic model.

---

## Delivery Models

### At Most Once

A message is delivered zero or one time.

Characteristics:

- No redelivery
- Possible message loss
- Lowest operational overhead

Examples:

- Fire-and-forget delivery
- Non-persistent messaging systems

---

### At Least Once

A message is delivered one or more times.

Characteristics:

- Message loss is minimized
- Duplicate delivery is possible
- Consumers should be idempotent

Examples:

- NATS JetStream
- RabbitMQ
- Redis Streams
- Amazon SQS
- Kafka consumer processing

---

### Exactly Once

A message is processed exactly one time.

Characteristics:

- No duplicate processing
- No message loss
- Requires additional coordination

Exactly-once behavior is highly backend-specific and typically requires transactional guarantees outside the scope of Relay.

---

## Relay Guarantee

Relay guarantees:

text At-Least-Once Delivery 

Relay does not guarantee:

text Exactly-Once Delivery 

Applications should assume that duplicate deliveries may occur.

Consumers are expected to be idempotent whenever possible.

---

## Acknowledgment Semantics

When supported by a backend:

moonbit queue.ack(message) 

indicates successful processing.

Acknowledged messages should not be redelivered.

Capability:

text supports_ack 

---

## Negative Acknowledgment Semantics

When supported by a backend:

moonbit queue.nack(message) 

indicates processing failure.

Backend behavior may include:

- Redelivery
- Retry scheduling
- Dead-letter routing

Capability:

text supports_nack 

---

## Retry Semantics

Relay retry policies define how failed messages are handled.

Example:

moonbit RetryPolicy::new(3) 

A backend may:

- Requeue messages
- Trigger redelivery
- Route messages to a dead-letter queue

Capability:

text supports_redelivery 

---

## Dead Letter Semantics

When supported:

text supports_dlq 

messages exceeding retry limits may be isolated from normal processing.

Characteristics:

- No further automatic delivery
- Preserved for inspection
- Available for operational analysis

---

## Ordering Semantics

Message ordering is backend-specific.

Relay does not guarantee global ordering.

Examples:

- Kafka may provide partition ordering.
- Streams may provide append ordering.
- Distributed systems may reorder messages.

Capability:

text supports_ordering 

Applications should not assume ordering unless explicitly provided by the backend.

---

## Backend Responsibility

Backend implementations are responsible for mapping native delivery behavior into Relay semantics.

Relay provides a common operational model while allowing backend-specific reliability features.

The Relay guarantee remains:

text At-Least-Once Delivery 