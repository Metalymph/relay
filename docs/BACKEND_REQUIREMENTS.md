# Backend Requirements

## Overview

Relay provides a backend-agnostic queue abstraction.

Backend implementations may use different messaging technologies while preserving Relay semantics.

This document defines the conceptual requirements that every Relay backend must satisfy.

---

## Core Operations

### Push

A backend must support message submission.

moonbit queue.push(payload) 

Semantics:

- Message becomes available for consumption.
- Delivery may occur immediately or later.
- Ordering behavior is backend-specific.

---

### Pop

A backend must support message retrieval.

moonbit queue.pop() 

Semantics:

- Retrieves a message for processing.
- Delivery behavior is backend-specific.
- Retrieval may be blocking or non-blocking.

---

## Reliability Operations

### Ack

If supported, a backend acknowledges successful processing.

moonbit queue.ack(message) 

Semantics:

- Message is considered successfully processed.
- Message should not be redelivered.

Capability:

text supports_ack 

---

### Nack

If supported, a backend signals processing failure.

moonbit queue.nack(message) 

Semantics:

- Message processing failed.
- Backend may redeliver or dead-letter the message.

Capability:

text supports_nack 

---

### Dead Letter Handling

If supported, failed messages may be routed to a dead-letter queue.

Capability:

text supports_dlq 

Semantics:

- Message exceeded retry limits.
- Message is isolated from normal processing.

---

## Consumer Coordination

### Consumer Groups

Backends may coordinate work across multiple consumers.

Capability:

text supports_consumer_groups 

Semantics:

- Prevent duplicate work.
- Enable horizontal scaling.

---

### Durable Consumers

Backends may preserve consumer state.

Capability:

text supports_durable_consumers 

Semantics:

- Consumer progress survives restarts.
- Consumption can resume from previous state.

---

## Inspection Requirements

Backends should expose operational visibility when supported.

Examples:

- Queue size
- Pending messages
- Dead-letter count
- Consumer state

Capabilities:

text supports_pending supports_dlq supports_telemetry 

---

## Health Requirements

Backends should expose health information.

Capability:

text supports_health_checks 

Examples:

- Connection status
- Cluster status
- Stream status

---

## Telemetry Requirements

Backends should expose operational metrics when available.

Capability:

text supports_telemetry 

Examples:

- Queue depth
- Consumer lag
- Pending messages
- Delivery failures

---

## Compatibility Principle

Relay defines semantic behavior.

Backends are responsible for mapping their native functionality to Relay concepts while preserving expected behavior.

Backend implementations may provide additional functionality beyond Relay requirements.

Relay only relies on documented backend capabilities.