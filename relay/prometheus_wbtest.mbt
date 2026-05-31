test "prometheus_metrics_from_healthy_event" {
  let event : TelemetryEvent = {
    timestamp_ms: 100L,

    status: Healthy,

    severity: None,

    incident_count: 0,

    summary: "Healthy",
  }

  let metrics = event.to_prometheus_metrics()

  assert_eq(metrics.length(), 2)
}

test "prometheus_metrics_from_critical_event" {
  let event : TelemetryEvent = {
    timestamp_ms: 100L,

    status: Unhealthy,

    severity: Some(Critical),

    incident_count: 2,

    summary: "Unhealthy",
  }

  let metrics = event.to_prometheus_metrics()

  assert_eq(metrics.length(), 3)
}