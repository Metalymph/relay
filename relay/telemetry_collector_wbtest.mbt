test "collect_worker_only" {
  let metrics : WorkerMetrics = {
    processed: 1,
    succeeded: 1,
    failed: 0,

    retries: 0,
    dlq_routed: 0,

    ack_failed: 0,
    nack_failed: 0,

    uptime_ms: 100,

    last_success_at_ms: None,
    last_failure_at_ms: None,
  }

  let health : BackendHealth = {
    healthy: true,
    message: None,
  }

  let snapshot = collect_worker(metrics, health)

  assert_true(snapshot.worker is Some(_))
  assert_true(snapshot.queue is None)
  assert_true(snapshot.health is Some(_))
}

test "collect_queue_only" {
  let metrics : QueueMetrics = {
    size: Some(5),
    dlq_size: Some(1),
    pending_count: None,
  }

  let health : BackendHealth = {
    healthy: true,
    message: None,
  }

  let snapshot = collect_queue(metrics, health)

  assert_true(snapshot.worker is None)
  assert_true(snapshot.queue is Some(_))
  assert_true(snapshot.health is Some(_))
}