///|
/// QueueInspection represents an operational view of a queue.
pub struct QueueInspection {
  status : SystemStatus

  queue_size : Int?
  dlq_size : Int?

  pending_count : Int64?

  backend_healthy : Bool
}

///|
/// inspect builds an operational queue inspection from a telemetry snapshot.
pub fn inspect(
  snapshot : RelaySnapshot,
) -> QueueInspection {
  {
    status: snapshot.status(),

    queue_size: snapshot.queue_size(),
    dlq_size: snapshot.dlq_size(),

    pending_count: snapshot.pending_count(),

    backend_healthy: snapshot.is_healthy(),
  }
}

///|
/// is_empty returns true when the queue size is known and equal to zero.
pub fn QueueInspection::is_empty(self : QueueInspection) -> Bool {
  match self.queue_size {
    Some(size) => size == 0
    None => false
  }
}

///|
/// has_pending returns true when pending messages are present.
pub fn QueueInspection::has_pending(self : QueueInspection) -> Bool {
  match self.pending_count {
    Some(count) => count > 0L
    None => false
  }
}

///|
/// has_dlq returns true when DLQ messages are present.
pub fn QueueInspection::has_dlq(self : QueueInspection) -> Bool {
  match self.dlq_size {
    Some(size) => size > 0
    None => false
  }
}

///|
/// summary returns a compact operational summary.
pub fn QueueInspection::summary(self : QueueInspection) -> String {
  let status = self.status.to_string()

  let queue =
    match self.queue_size {
      Some(v) => v.to_string()
      None => "unknown"
    }

  let dlq =
    match self.dlq_size {
      Some(v) => v.to_string()
      None => "unknown"
    }

  let pending =
    match self.pending_count {
      Some(v) => v.to_string()
      None => "unknown"
    }

  status +
  " | queue=" +
  queue +
  " | dlq=" +
  dlq +
  " | pending=" +
  pending
}