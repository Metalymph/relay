///|
/// BackendCapabilities describes the features supported by a queue backend.
pub struct BackendCapabilities {
  supports_ack : Bool

  supports_dlq : Bool

  supports_pending : Bool

  supports_consumer_groups : Bool

  supports_health_checks : Bool

  supports_telemetry : Bool
}

///|
pub fn BackendCapabilities::in_memory() -> BackendCapabilities {
  {
    supports_ack: true,

    supports_dlq: true,

    supports_pending: false,

    supports_consumer_groups: false,

    supports_health_checks: true,

    supports_telemetry: true,
  }
}

///|
pub fn BackendCapabilities::redis_lists() -> BackendCapabilities {
  {
    supports_ack: true,

    supports_dlq: false,

    supports_pending: false,

    supports_consumer_groups: false,

    supports_health_checks: true,

    supports_telemetry: true,
  }
}

///|
pub fn BackendCapabilities::redis_streams() -> BackendCapabilities {
  {
    supports_ack: true,

    supports_dlq: true,

    supports_pending: true,

    supports_consumer_groups: true,

    supports_health_checks: true,

    supports_telemetry: true,
  }
}