///|
test "inspect_snapshot" {
  let queue : QueueMetrics = {
    size: Some(10),
    dlq_size: Some(2),
    pending_count: Some(4L),
  }

  let health : BackendHealth = { healthy: true, message: None }

  let snapshot = RelaySnapshot::new({
    worker: None,
    queue: Some(queue),
    health: Some(health),
  })

  let inspection = inspect(snapshot)

  assert_eq(inspection.status, Healthy)

  match inspection.queue_size {
    Some(n) => assert_eq(n, 10)
    None => fail("expected queue size")
  }

  match inspection.dlq_size {
    Some(n) => assert_eq(n, 2)
    None => fail("expected dlq size")
  }

  match inspection.pending_count {
    Some(n) => assert_eq(n, 4L)
    None => fail("expected pending count")
  }

  assert_true(inspection.backend_healthy)
}

///|
test "queue_inspection_helpers" {
  let inspection : QueueInspection = {
    status: Healthy,
    queue_size: Some(0),
    dlq_size: Some(1),
    pending_count: Some(2L),
    backend_healthy: true,
  }

  assert_true(inspection.is_empty())
  assert_true(inspection.has_pending())
  assert_true(inspection.has_dlq())

  assert_eq(inspection.summary(), "Healthy | queue=0 | dlq=1 | pending=2")
}

///|
test "queue_inspection_unknown_values" {
  let inspection : QueueInspection = {
    status: Healthy,
    queue_size: None,
    dlq_size: None,
    pending_count: None,
    backend_healthy: true,
  }

  assert_false(inspection.is_empty())
  assert_false(inspection.has_pending())
  assert_false(inspection.has_dlq())

  assert_eq(
    inspection.summary(),
    "Healthy | queue=unknown | dlq=unknown | pending=unknown",
  )
}
