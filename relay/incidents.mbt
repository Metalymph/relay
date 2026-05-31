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

///|
/// IncidentSeverity describes the operational severity of an incident.
pub enum IncidentSeverity {
  Info
  Warning
  Critical
} derive(Eq, ToJson, Debug)

///|
pub fn IncidentSeverity::to_string(
  self : IncidentSeverity,
) -> String {
  match self {
    Info => "Info"
    Warning => "Warning"
    Critical => "Critical"
  }
}

///|
/// severity returns the operational severity of an incident.
pub fn Incident::severity(self : Incident) -> IncidentSeverity {
  match self {
    BackendUnavailable => Critical
    DeadLetterMessages => Critical
    WorkerFailures => Warning
    PendingMessages => Warning
  }
}

///|
/// highest_severity returns the highest severity among incidents.
pub fn highest_severity(incidents : Array[Incident]) -> IncidentSeverity? {
  let mut highest : IncidentSeverity? = None

  for incident in incidents {
    let severity = incident.severity()

    match highest {
      None => highest = Some(severity)
      Some(current) =>
        if severity_rank(severity) > severity_rank(current) {
          highest = Some(severity)
        }
    }
  }

  highest
}

///|
fn severity_rank(severity : IncidentSeverity) -> Int {
  match severity {
    Info => 0
    Warning => 1
    Critical => 2
  }
}

pub fn detect_incidents_with_capabilities(
  report : AdminReport,
  capabilities : BackendCapabilities,
) -> Array[Incident] {
  let incidents : Array[Incident] = []

  match report.status {
    Unhealthy => incidents.push(BackendUnavailable)
    Degraded => incidents.push(WorkerFailures)
    Healthy => ()
  }

  if capabilities.supports_dlq {
    match report.dlq_size {
      Some(size) if size > 0 => incidents.push(DeadLetterMessages)
      _ => ()
    }
  }

  if capabilities.supports_pending {
    match report.pending_count {
      Some(count) if count > 0L => incidents.push(PendingMessages)
      _ => ()
    }
  }

  incidents
}