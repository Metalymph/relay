///|
fn healthy_report() -> AdminReport {
  {
    status: Healthy,
    requires_attention: false,
    queue_size: Some(0),
    dlq_size: Some(0),
    pending_count: Some(0L),
    summary: "Healthy | queue=0 | dlq=0 | pending=0",
  }
}

///|
test "healthy_report_has_no_incidents" {
  let report = healthy_report()
  let incidents = detect_incidents(report)

  assert_eq(incidents.length(), 0)
  assert_false(has_incidents(report))
  assert_eq(incident_count(report), 0)
}

///|
test "dlq_generates_incident" {
  let report : AdminReport = {
    status: Healthy,
    requires_attention: false,
    queue_size: Some(0),
    dlq_size: Some(2),
    pending_count: Some(0L),
    summary: "Healthy | queue=0 | dlq=2 | pending=0",
  }

  let incidents = detect_incidents(report)

  assert_eq(incidents.length(), 1)

  match incidents[0] {
    DeadLetterMessages => ()
    _ => fail("Expected DeadLetterMessages")
  }

  assert_true(has_incidents(report))
  assert_eq(incident_count(report), 1)
}

///|
test "pending_generates_incident" {
  let report : AdminReport = {
    status: Healthy,
    requires_attention: false,
    queue_size: Some(0),
    dlq_size: Some(0),
    pending_count: Some(3L),
    summary: "Healthy | queue=0 | dlq=0 | pending=3",
  }

  let incidents = detect_incidents(report)

  assert_eq(incidents.length(), 1)

  match incidents[0] {
    PendingMessages => ()
    _ => fail("Expected PendingMessages")
  }

  assert_true(has_incidents(report))
  assert_eq(incident_count(report), 1)
}

///|
test "backend_failure_generates_incident" {
  let report : AdminReport = {
    status: Unhealthy,
    requires_attention: true,
    queue_size: None,
    dlq_size: None,
    pending_count: None,
    summary: "Unhealthy | queue=unknown | dlq=unknown | pending=unknown",
  }

  let incidents = detect_incidents(report)

  assert_eq(incidents.length(), 1)

  match incidents[0] {
    BackendUnavailable => ()
    _ => fail("Expected BackendUnavailable")
  }

  assert_true(has_incidents(report))
  assert_eq(incident_count(report), 1)
}

///|
test "degraded_report_generates_worker_failure_incident" {
  let report : AdminReport = {
    status: Degraded,
    requires_attention: true,
    queue_size: Some(0),
    dlq_size: Some(0),
    pending_count: Some(0L),
    summary: "Degraded | queue=0 | dlq=0 | pending=0",
  }

  let incidents = detect_incidents(report)

  assert_eq(incidents.length(), 1)

  match incidents[0] {
    WorkerFailures => ()
    _ => fail("Expected WorkerFailures")
  }

  assert_true(has_incidents(report))
  assert_eq(incident_count(report), 1)
}

///|
test "report_can_generate_multiple_incidents" {
  let report : AdminReport = {
    status: Degraded,
    requires_attention: true,
    queue_size: Some(10),
    dlq_size: Some(2),
    pending_count: Some(5L),
    summary: "Degraded | queue=10 | dlq=2 | pending=5",
  }

  let incidents = detect_incidents(report)

  assert_eq(incidents.length(), 3)
  assert_true(has_incidents(report))
  assert_eq(incident_count(report), 3)
}

///|
test "incident_severity" {
  match BackendUnavailable.severity() {
    Critical => ()
    _ => fail("Expected Critical")
  }
  match DeadLetterMessages.severity() {
    Critical => ()
    _ => fail("Expected Critical")
  }
  match WorkerFailures.severity() {
    Warning => ()
    _ => fail("Expected Warning")
  }
  match PendingMessages.severity() {
    Warning => ()
    _ => fail("Expected Warning")
  }
}

///|
test "highest_severity_returns_none_for_empty_incidents" {
  match highest_severity([]) {
    None => ()
    Some(_) => fail("Expected no severity")
  }
}

///|
test "highest_severity_returns_highest_value" {
  let incidents = [WorkerFailures, PendingMessages, DeadLetterMessages]

  match highest_severity(incidents) {
    Some(Critical) => ()
    _ => fail("Expected Critical")
  }
}

test "capability_aware_detection_ignores_pending_when_unsupported" {
  let report : AdminReport = {
    status: Healthy,
    requires_attention: false,
    queue_size: Some(0),
    dlq_size: Some(0),
    pending_count: Some(5L),
    summary: "Healthy | queue=0 | dlq=0 | pending=5",
  }

  let unsupported_caps = BackendCapabilities::{
    supports_ack: true,
    supports_nack: true,
    supports_dlq: true,
    supports_pending: false,
    supports_consumer_groups: false,
    supports_streams: false,
    supports_subjects: false,
    supports_pull_consumers: false,
    supports_push_consumers: false,
    supports_durable_consumers: false,
    supports_redelivery: false,
    supports_ordering: false,
    supports_message_delay: false,
    supports_health_checks: true,
    supports_telemetry: true,
  }

  let incidents = detect_incidents_with_capabilities(
    report,
    unsupported_caps,
  )

  assert_eq(incidents.length(), 0)
}

test "capability_aware_detection_detects_pending_when_supported" {
  let report : AdminReport = {
    status: Healthy,
    requires_attention: false,
    queue_size: Some(0),
    dlq_size: Some(0),
    pending_count: Some(5L),
    summary: "Healthy | queue=0 | dlq=0 | pending=5",
  }

  let incidents = detect_incidents_with_capabilities(
    report,
    BackendCapabilities::redis_streams(),
  )

  assert_eq(incidents.length(), 1)

  match incidents[0] {
    PendingMessages => ()
    _ => fail("Expected PendingMessages")
  }
}