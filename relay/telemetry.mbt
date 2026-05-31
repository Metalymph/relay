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