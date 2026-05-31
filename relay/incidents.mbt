///|
/// Incident represents a specific operational problem in Relay.
pub enum Incident {
  BackendUnavailable

  WorkerFailures

  DeadLetterMessages

  PendingMessages
} derive(Eq, ToJson, Debug)

///|
/// detect_incidents analyzes an administrative report.
pub fn detect_incidents(
  report : AdminReport,
) -> Array[Incident] {
  let incidents : Array[Incident] = []

  match report.status {
    Unhealthy => incidents.push(BackendUnavailable)
    Degraded => incidents.push(WorkerFailures)
    Healthy => ()
  }

  match report.dlq_size {
    Some(size) if size > 0 => incidents.push(DeadLetterMessages)
    _ => ()
  }

  match report.pending_count {
    Some(count) if count > 0L => incidents.push(PendingMessages)
    _ => ()
  }

  incidents
}

///|
/// has_incidents returns true when incidents are detected.
pub fn has_incidents(
  report : AdminReport,
) -> Bool {
  !detect_incidents(report).is_empty()
}

///|
/// incident_count returns the number of detected incidents.
pub fn incident_count(
  report : AdminReport,
) -> Int {
  detect_incidents(report).length()
}