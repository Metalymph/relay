///|
/// AdminReport represents a high-level operational report.
pub struct AdminReport {
  status : SystemStatus

  requires_attention : Bool

  queue_size : Int?
  dlq_size : Int?

  pending_count : Int64?

  summary : String
}

///|
/// report builds an administrative report from a queue inspection.
pub fn report(
  inspection : QueueInspection,
) -> AdminReport {
  {
    status: inspection.status,

    requires_attention:
      inspection.status != Healthy,

    queue_size: inspection.queue_size,
    dlq_size: inspection.dlq_size,

    pending_count: inspection.pending_count,

    summary: inspection.summary(),
  }
}

///|
/// has_incidents returns true when operator attention is required.
pub fn AdminReport::has_incidents(
  self : AdminReport,
) -> Bool {
  self.requires_attention
}

///|
/// is_healthy returns true when the report status is healthy.
pub fn AdminReport::is_healthy(
  self : AdminReport,
) -> Bool {
  self.status == Healthy
}