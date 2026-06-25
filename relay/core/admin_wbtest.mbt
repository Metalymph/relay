///|
test "admin_report_healthy" {
  let inspection : QueueInspection = {
    status: Healthy,
    queue_size: Some(0),
    dlq_size: Some(0),
    pending_count: Some(0L),
    backend_healthy: true,
  }

  let admin = report(inspection)

  assert_false(admin.has_incidents())
  assert_true(admin.is_healthy())
}

///|
test "admin_report_degraded" {
  let inspection : QueueInspection = {
    status: Degraded,
    queue_size: Some(10),
    dlq_size: Some(1),
    pending_count: Some(2L),
    backend_healthy: true,
  }

  let admin = report(inspection)

  assert_true(admin.has_incidents())
  assert_false(admin.is_healthy())
}
