# NATS Mapping

## Overview

This document defines how Relay concepts map to NATS JetStream concepts.

Relay must preserve its backend-agnostic semantics while using native JetStream features where available.

Relay must not embed the NATS protocol client directly.

NATS protocol and JetStream client functionality should live in a separate package:

text Metalymph/nats 

Relay should depend on that package for the NATS backend.

---

## Concept Mapping

| Relay Concept | NATS JetStream Concept |
|---|---|
| Queue | Stream |
| Queue name | Stream name |
| Message payload | Message data |
| Push | Publish |
| Pop | Pull consumer fetch |
| Ack | Message ack |
| Nack | Message nak |
| Dead Letter Queue | Dead letter stream |
| Pending messages | Consumer pending state |
| Consumer group | Durable consumer |
| Retry / redelivery | Ack wait + max deliver |
| Backend health | Connection / stream / consumer health |
| Telemetry | Stream info + consumer info |

---

## Push Mapping

Relay:

moonbit queue.push(payload) 

JetStream:

text Publish subject payload 

Semantics:

- Relay push publishes a message to a configured NATS subject.
- The subject must belong to the configured JetStream stream.
- Successful publish means JetStream accepted the message.
- Publish acknowledgment should be treated as backend-level confirmation.

Required capability:

text supports_subjects supports_streams 

---

## Pop Mapping

Relay:

moonbit queue.pop() 

JetStream:

text Pull consumer fetch 

Semantics:

- Relay pop fetches a message from a JetStream pull consumer.
- The consumer should be durable for production use.
- Fetched messages are pending until ack, nak, timeout, or max delivery handling.

Required capabilities:

text supports_pull_consumers supports_durable_consumers supports_pending 

---

## Ack Mapping

Relay:

moonbit queue.ack(message) 

JetStream:

text Message ack 

Semantics:

- Ack confirms successful processing.
- Acked messages should not be redelivered.

Required capability:

text supports_ack 

---

## Nack Mapping

Relay:

moonbit queue.nack(message) 

JetStream:

text Message nak 

Semantics:

- Nak signals failed processing.
- JetStream may redeliver the message according to consumer policy.
- Relay retry policy must be mapped carefully to JetStream delivery policy.

Required capabilities:

text supports_nack supports_redelivery 

---

## Dead Letter Mapping

Relay:

text Dead Letter Queue 

JetStream:

text Dead Letter Stream 

Semantics:

- Messages exceeding retry limits should be routed to a configured dead letter stream.
- Dead-letter routing may be implemented by Relay if JetStream policy does not directly express the desired behavior.
- DLQ messages should remain inspectable.

Required capability:

text supports_dlq 

---

## Pending Mapping

Relay:

text Pending messages 

JetStream:

text Consumer pending state 

Semantics:

- Pending messages are messages fetched by a consumer but not yet acknowledged.
- Pending state should be reflected in Relay inspection and incident detection.
- Pending counts should contribute to operational reporting.

Required capability:

text supports_pending 

---

## Consumer Group Mapping

Relay:

text Consumer group 

JetStream:

text Durable consumer 

Semantics:

- Durable consumers preserve consumption state.
- Multiple workers using the same durable consumer should coordinate consumption.
- Consumer configuration must be stable across restarts.

Required capabilities:

text supports_consumer_groups supports_durable_consumers 

---

## Retry and Redelivery Mapping

Relay:

moonbit RetryPolicy::new(max_attempts) 

JetStream:

text ack_wait max_deliver redelivery 

Semantics:

- Relay retry limit should map to JetStream max delivery where possible.
- Ack wait controls when unacked messages become eligible for redelivery.
- Relay must document any mismatch between local retry policy and JetStream policy.

Required capabilities:

text supports_redelivery supports_pending 

---

## Health Mapping

Relay:

text BackendHealth 

JetStream:

text Connection health Stream info Consumer info 

Semantics:

- Backend health should reflect connection availability.
- Stream lookup failures should degrade or mark the backend unhealthy.
- Consumer lookup failures should degrade or mark the backend unhealthy.

Required capability:

text supports_health_checks 

---

## Telemetry Mapping

Relay:

text BackendHealth QueueMetrics RelayMetrics RelaySnapshot 

JetStream:

text Stream info Consumer info Delivery statistics Pending state 

Semantics:

- JetStream stream and consumer information should feed Relay telemetry models.
- Pending messages should contribute to queue metrics.
- Redelivery and failure indicators should contribute to incident detection when available.

Required capability:

text supports_telemetry 

---

## Initial Relay NATS Backend Scope

The first Relay NATS backend should support:

text Push Pop Ack Nack Pending inspection Durable pull consumers Basic health checks Basic telemetry Dead letter stream mapping 

Out of scope for the first version:

text Push consumers Advanced stream management Advanced subject routing Exactly-once semantics Transactional publishing Native exporter integrations 

---

## Package Boundary

Relay must not contain low-level NATS protocol code.

The NATS client should live in:

text Metalymph/nats 

Relay should only provide the backend adapter that maps Relay semantics to the NATS client API.

This keeps Relay backend-agnostic and prevents protocol-specific logic from leaking into the core framework.