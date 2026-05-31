///|
/// collect combines worker, queue, and backend health telemetry into a single snapshot.
pub fn collect(
  worker : WorkerMetrics?,
  queue : QueueMetrics?,
  health : BackendHealth?,
) -> RelayMetrics {
  {
    worker,
    queue,
    health,
  }
}

///|
/// collect_worker creates a telemetry snapshot containing only worker metrics.
pub fn collect_worker(
  worker : WorkerMetrics,
  health : BackendHealth,
) -> RelayMetrics {
  {
    worker: Some(worker),
    queue: None,
    health: Some(health),
  }
}

///|
/// collect_queue creates a telemetry snapshot containing only queue metrics.
pub fn collect_queue(
  queue : QueueMetrics,
  health : BackendHealth,
) -> RelayMetrics {
  {
    worker: None,
    queue: Some(queue),
    health: Some(health),
  }
}

///|
/// collect_snapshot combines telemetry and wraps it in a timestamped snapshot.
pub fn collect_snapshot(
  worker : WorkerMetrics?,
  queue : QueueMetrics?,
  health : BackendHealth?,
) -> RelaySnapshot {
  RelaySnapshot::new({
    worker,
    queue,
    health,
  })
}

test "telemetry_snapshot_inspection_helpers" {
  let worker : WorkerMetrics = {
    processed: 10,
    succeeded: 8,
    failed: 2,

    retries: 1,
    dlq_routed: 1,

    ack_failed: 0,
    nack_failed: 0,

    uptime_ms: 1000,

    last_success_at_ms: None,
    last_failure_at_ms: Some(100L),
  }

  let queue : QueueMetrics = {
    size: Some(3),
    dlq_size: Some(1),
    pending_count: Some(2L),
  }

  let health : BackendHealth = {
    healthy: true,
    message: None,
  }

  let snapshot = RelaySnapshot::new({
    worker: Some(worker),
    queue: Some(queue),
    health: Some(health),
  })

  assert_true(snapshot.is_healthy())
  assert_true(snapshot.has_failures())
  assert_eq(snapshot.queue_size(), Some(3))
  assert_eq(snapshot.dlq_size(), Some(1))
  assert_eq(snapshot.pending_count(), Some(2L))
}