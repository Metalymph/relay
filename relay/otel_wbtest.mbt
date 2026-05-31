test "telemetry_event_from_healthy_report" {
  let report : AdminReport = {
    status: Healthy,

    requires_attention: false,

    queue_size: Some(0),
    dlq_size: Some(0),

    pending_count: Some(0L),

    summary: "Healthy | queue=0 | dlq=0 | pending=0",
  }

  let event = from_report(report, [])

  assert_true(event.timestamp_ms > 0L)
  assert_eq(event.status, Healthy)
  assert_eq(event.incident_count, 0)

  match event.severity {
    None => ()
    Some(_) => fail("Expected no severity")
  }

  assert_eq(event.summary, report.summary)
}

test "telemetry_event_from_incident_report" {
  let report : AdminReport = {
    status: Unhealthy,

    requires_attention: true,

    queue_size: None,
    dlq_size: None,

    pending_count: None,

    summary: "Unhealthy | queue=unknown | dlq=unknown | pending=unknown",
  }

  let incidents = [BackendUnavailable]
  let event = from_report(report, incidents)

  assert_true(event.timestamp_ms > 0L)
  assert_eq(event.status, Unhealthy)
  assert_eq(event.incident_count, 1)

  match event.severity {
    Some(Critical) => ()
    _ => fail("Expected critical severity")
  }

  assert_eq(event.summary, report.summary)
}