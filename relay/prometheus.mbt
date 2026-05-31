///|
/// PrometheusMetric represents a Prometheus-compatible metric sample.
pub struct PrometheusMetric {
  name : String
  value : Float
}

///|
/// to_prometheus_metrics converts a telemetry event into Prometheus-compatible metrics.
pub fn TelemetryEvent::to_prometheus_metrics(
  self : TelemetryEvent,
) -> Array[PrometheusMetric] {
  let metrics : Array[PrometheusMetric] = []

  metrics.push({
    name: "relay_incident_count",
    value: self.incident_count.to_float(),
  })

  metrics.push({
    name: "relay_status",
    value:
      match self.status {
        Healthy => 0.0
        Degraded => 1.0
        Unhealthy => 2.0
      },
  })

  match self.severity {
    Some(severity) =>
      metrics.push({
        name: "relay_severity",
        value:
          match severity {
            Info => 0.0
            Warning => 1.0
            Critical => 2.0
          },
      })
    None => ()
  }

  metrics
}