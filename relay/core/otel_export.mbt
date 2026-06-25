///|
/// OtelAttribute represents a simple OpenTelemetry-compatible attribute.
pub struct OtelAttribute {
  key : String
  value : String
}

///|
/// OtelRecord represents a normalized OpenTelemetry-compatible event record.
pub struct OtelRecord {
  name : String
  timestamp_ms : Int64
  attributes : Array[OtelAttribute]
}

///|
/// to_otel_record converts a Relay telemetry event into an OpenTelemetry-compatible record.
pub fn TelemetryEvent::to_otel_record(self : TelemetryEvent) -> OtelRecord {
  let attributes : Array[OtelAttribute] = []

  attributes.push({ key: "relay.status", value: self.status.to_string() })

  attributes.push({
    key: "relay.incident_count",
    value: self.incident_count.to_string(),
  })

  attributes.push({ key: "relay.summary", value: self.summary })

  match self.severity {
    Some(severity) =>
      attributes.push({ key: "relay.severity", value: severity.to_string() })
    None => ()
  }

  { name: "relay.telemetry", timestamp_ms: self.timestamp_ms, attributes }
}
