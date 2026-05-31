///|
/// collect combines worker and queue telemetry into a single snapshot.
pub fn collect(
  worker : WorkerMetrics?,
  queue : QueueMetrics?,
) -> RelayMetrics {
  {
    worker,
    queue,
  }
}

///|
/// collect_worker creates a telemetry snapshot containing only worker metrics.
pub fn collect_worker(worker : WorkerMetrics) -> RelayMetrics {
  {
    worker: Some(worker),
    queue: None,
  }
}

///|
/// collect_queue creates a telemetry snapshot containing only queue metrics.
pub fn collect_queue(queue : QueueMetrics) -> RelayMetrics {
  {
    worker: None,
    queue: Some(queue),
  }
}