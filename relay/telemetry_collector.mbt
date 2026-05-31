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