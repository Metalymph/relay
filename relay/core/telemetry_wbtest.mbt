///|
test "telemetry_snapshot_status_healthy" {
  let snapshot = RelaySnapshot::new({
    worker: None,
    queue: None,
    health: Some({ healthy: true, message: None }),
  })

  assert_eq(snapshot.status(), Healthy)
  assert_false(snapshot.requires_attention())
  assert_eq(snapshot.status_message(), "Relay is healthy")
}

///|
test "telemetry_snapshot_status_degraded_on_worker_failures" {
  let worker : WorkerMetrics = {
    processed: 1,
    succeeded: 0,
    failed: 1,
    retries: 0,
    dlq_routed: 0,
    ack_failed: 0,
    nack_failed: 0,
    uptime_ms: 100,
    last_success_at_ms: None,
    last_failure_at_ms: Some(100L),
  }

  let snapshot = RelaySnapshot::new({
    worker: Some(worker),
    queue: None,
    health: Some({ healthy: true, message: None }),
  })

  assert_eq(snapshot.status(), Degraded)
  assert_true(snapshot.requires_attention())
  assert_eq(snapshot.status_message(), "Relay is degraded")
}

///|
test "telemetry_snapshot_status_unhealthy_on_backend_failure" {
  let snapshot = RelaySnapshot::new({
    worker: None,
    queue: None,
    health: Some({ healthy: false, message: Some("backend unavailable") }),
  })

  assert_eq(snapshot.status(), Unhealthy)
  assert_true(snapshot.requires_attention())
  assert_eq(
    snapshot.status_message(),
    "Relay is unhealthy: backend unavailable",
  )
}
