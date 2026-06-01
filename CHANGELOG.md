# [0.4.0] - 2026-06-XX

## Added

### Reliability

- Worker statistics tracking.
- Worker metrics generation.
- Worker uptime tracking.
- Success and failure timestamps.
- Ack failure tracking.
- Nack failure tracking.
- Dead-letter routing accounting.

### Telemetry

- Backend health model.
- Queue metrics.
- Worker metrics.
- RelayMetrics aggregation.
- Telemetry collectors.
- Telemetry snapshots.

### Observability

- SystemStatus model.
- Healthy state detection.
- Degraded state detection.
- Unhealthy state detection.
- Snapshot inspection helpers.
- Human-readable status messages.

### Operations

- QueueInspection model.
- Queue inspection helpers.
- Queue summary generation.
- Pending message inspection.
- Dead-letter queue inspection.

### Administrative Reporting

- AdminReport model.
- Administrative report generation.
- Operational health evaluation.
- Incident awareness helpers.

### Backend Capabilities

- BackendCapabilities model.
- In-memory backend capabilities.
- Redis backend capabilities.
- Redis Streams backend capabilities.
- Capability-aware feature detection.

### Incident Detection

- Incident model.
- BackendUnavailable detection.
- WorkerFailures detection.
- DeadLetterMessages detection.
- PendingMessages detection.
- Capability-aware incident detection.

### Incident Severity

- IncidentSeverity model.
- Severity classification.
- Severity aggregation.
- Highest severity evaluation.

### Export Models

- TelemetryEvent model.
- OpenTelemetry-compatible record generation.
- Prometheus-compatible metric generation.

## Changed

### Relay

- Improved public API consistency.
- Expanded observability surface.
- Improved operational inspection APIs.
- Improved reliability reporting.

### Documentation

- Reworked README.
- Added architecture documentation.
- Added observability documentation.
- Added operational reporting documentation.
- Added telemetry pipeline documentation.

### Testing

- Added telemetry test coverage.
- Added observability test coverage.
- Added incident detection test coverage.
- Added severity classification test coverage.
- Added exporter model test coverage.
- Expanded backend capability coverage.
