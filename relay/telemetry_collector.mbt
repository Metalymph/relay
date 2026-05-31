pub fn collect(
  worker : WorkerMetrics?,
  queue : QueueMetrics?,
) -> RelayMetrics {
  {
    worker,
    queue,
  }
}