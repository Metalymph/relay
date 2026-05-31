test "telemetry_event_to_otel_record_without_severity" {
  let event : TelemetryEvent = {
    timestamp_ms: 100L,

    status: Healthy,

    severity: None,

    incident_count: 0,

    summary: "Healthy | queue=0 | dlq=0 | pending=0",
  }

  let record = event.to_otel_record()

  assert_eq(record.name, "relay.telemetry")
  assert_eq(record.timestamp_ms, 100L)
  assert_eq(record.attributes.length(), 3)
}

test "telemetry_event_to_otel_record_with_severity" {
  let event : TelemetryEvent = {
    timestamp_ms: 100L,

    status: Unhealthy,

    severity: Some(Critical),

    incident_count: 1,

    summary: "Unhealthy | queue=unknown | dlq=unknown | pending=unknown",
  }

  let record = event.to_otel_record()

  assert_eq(record.name, "relay.telemetry")
  assert_eq(record.timestamp_ms, 100L)
  assert_eq(record.attributes.length(), 4)
}