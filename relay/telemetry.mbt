///|
/// WorkerMetrics is a backend-agnostic snapshot of worker activity.
pub struct WorkerMetrics {
  processed : Int
  succeeded : Int
  failed : Int

  retries : Int
  dlq_routed : Int

  ack_failed : Int
  nack_failed : Int

  uptime_ms : Int64

  last_success_at_ms : Int64?
  last_failure_at_ms : Int64?
}

///|
/// QueueMetrics is a backend-agnostic snapshot of queue state.
pub struct QueueMetrics {
  size : Int?
  dlq_size : Int?

  pending_count : Int64?
}

///|
/// RelayMetrics combines queue and worker telemetry.
pub struct RelayMetrics {
  worker : WorkerMetrics?
  queue : QueueMetrics?
  health : BackendHealth?
}

///|
pub struct BackendHealth {
  healthy : Bool
  message : String?
}

///|
/// RelaySnapshot represents a metrics snapshot collected at a specific time.
pub struct RelaySnapshot {
  collected_at_ms : Int64
  metrics : RelayMetrics
}

///|
/// new creates a timestamped RelaySnapshot.
pub fn RelaySnapshot::new(metrics : RelayMetrics) -> RelaySnapshot {
  {
    collected_at_ms: @env.now().reinterpret_as_int64(),
    metrics,
  }
}

///|
/// is_healthy returns true when health is present and healthy.
pub fn RelaySnapshot::is_healthy(self : RelaySnapshot) -> Bool {
  match self.metrics.health {
    Some(health) => health.healthy
    None => false
  }
}

///|
/// has_failures returns true when worker failures or ack/nack failures are present.
pub fn RelaySnapshot::has_failures(self : RelaySnapshot) -> Bool {
  match self.metrics.worker {
    Some(worker) =>
      worker.failed > 0 ||
      worker.ack_failed > 0 ||
      worker.nack_failed > 0
    None => false
  }
}

///|
/// queue_size returns the known queue size, if available.
pub fn RelaySnapshot::queue_size(self : RelaySnapshot) -> Int? {
  match self.metrics.queue {
    Some(queue) => queue.size
    None => None
  }
}

///|
/// dlq_size returns the known DLQ size, if available.
pub fn RelaySnapshot::dlq_size(self : RelaySnapshot) -> Int? {
  match self.metrics.queue {
    Some(queue) => queue.dlq_size
    None => None
  }
}

///|
/// pending_count returns the known pending message count, if available.
pub fn RelaySnapshot::pending_count(self : RelaySnapshot) -> Int64? {
  match self.metrics.queue {
    Some(queue) => queue.pending_count
    None => None
  }
}