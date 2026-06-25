///|
/// WorkerMetrics is a backend-agnostic snapshot of worker activity.
pub(all) struct WorkerMetrics {
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
pub(all) struct QueueMetrics {
  size : Int?
  dlq_size : Int?
  pending_count : Int64?
}

///|
/// RelayMetrics combines queue and worker telemetry.
pub(all) struct RelayMetrics {
  worker : WorkerMetrics?
  queue : QueueMetrics?
  health : BackendHealth?
}

///|
pub(all) struct BackendHealth {
  healthy : Bool
  message : String?
}

///|
/// RelaySnapshot represents a metrics snapshot collected at a specific time.
pub(all) struct RelaySnapshot {
  collected_at_ms : Int64
  metrics : RelayMetrics
}

///|
/// new creates a timestamped RelaySnapshot.
pub fn RelaySnapshot::new(metrics : RelayMetrics) -> RelaySnapshot {
  { collected_at_ms: @env.now().reinterpret_as_int64(), metrics }
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
      worker.failed > 0 || worker.ack_failed > 0 || worker.nack_failed > 0
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

///|
/// status returns a high-level health status for the snapshot.
pub fn RelaySnapshot::status(self : RelaySnapshot) -> SystemStatus {
  match self.metrics.health {
    Some(health) if !health.healthy => Unhealthy
    _ if self.has_failures() => Degraded
    _ => Healthy
  }
}

///|
/// requires_attention returns true when the snapshot is degraded or unhealthy.
pub fn RelaySnapshot::requires_attention(self : RelaySnapshot) -> Bool {
  match self.status() {
    Healthy => false
    Degraded | Unhealthy => true
  }
}

///|
/// status_message returns a short human-readable status summary.
pub fn RelaySnapshot::status_message(self : RelaySnapshot) -> String {
  match self.status() {
    Healthy => "Relay is healthy"
    Degraded => "Relay is degraded"
    Unhealthy =>
      match self.metrics.health {
        Some(health) =>
          match health.message {
            Some(msg) => "Relay is unhealthy: " + msg
            None => "Relay is unhealthy"
          }
        None => "Relay is unhealthy"
      }
  }
}

///|
/// SystemStatus summarizes the current observable state of Relay.
pub(all) enum SystemStatus {
  Healthy
  Degraded
  Unhealthy
} derive(Debug, Eq, ToJson)

///|
impl Show for SystemStatus with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn SystemStatus::to_string(self : SystemStatus) -> String {
  match self {
    Healthy => "Healthy"
    Degraded => "Degraded"
    Unhealthy => "Unhealthy"
  }
}
