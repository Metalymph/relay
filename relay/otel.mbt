///|
/// TelemetryEvent is a normalized event that can later be exported to
/// OpenTelemetry, Prometheus, JSON, logs, or other observability sinks.
pub struct TelemetryEvent {
  timestamp_ms : Int64

  status : SystemStatus

  severity : IncidentSeverity?

  incident_count : Int

  summary : String
}

///|
/// from_report converts an administrative report and detected incidents into
/// a normalized telemetry event.
pub fn from_report(
  report : AdminReport,
  incidents : Array[Incident],
) -> TelemetryEvent {
  {
    timestamp_ms: @env.now().reinterpret_as_int64(),

    status: report.status,

    severity: highest_severity(incidents),

    incident_count: incidents.length(),

    summary: report.summary,
  }
}