///|
/// BackendCapabilities describes the features supported by a queue backend.
pub struct BackendCapabilities {
  supports_ack : Bool
  supports_nack : Bool
  supports_dlq : Bool
  supports_pending : Bool
  supports_consumer_groups : Bool

  supports_streams : Bool
  supports_subjects : Bool
  supports_pull_consumers : Bool
  supports_push_consumers : Bool
  supports_durable_consumers : Bool
  supports_redelivery : Bool
  supports_ordering : Bool
  supports_message_delay : Bool

  supports_health_checks : Bool
  supports_telemetry : Bool
}

///|
pub fn BackendCapabilities::in_memory() -> BackendCapabilities {
  {
    supports_ack: true,
    supports_nack: true,
    supports_dlq: true,
    supports_pending: true,
    supports_consumer_groups: false,
  
    supports_streams: false,
    supports_subjects: false,
    supports_pull_consumers: false,
    supports_push_consumers: false,
    supports_durable_consumers: false,
    supports_redelivery: true,
    supports_ordering: false,
    supports_message_delay: false,
  
    supports_health_checks: true,
    supports_telemetry: true,
  }
}

///|
pub fn BackendCapabilities::redis_lists() -> BackendCapabilities {
  {
    supports_ack: true,
    supports_nack: true,
    supports_dlq: true,
    supports_pending: false,
    supports_consumer_groups: false,
  
    supports_streams: false,
    supports_subjects: false,
    supports_pull_consumers: false,
    supports_push_consumers: false,
    supports_durable_consumers: false,
    supports_redelivery: true,
    supports_ordering: true,
    supports_message_delay: false,
  
    supports_health_checks: true,
    supports_telemetry: true,
  }
}

///|
pub fn BackendCapabilities::redis_streams() -> BackendCapabilities {
  {
    supports_ack: true,
    supports_nack: true,
    supports_dlq: true,
    supports_pending: true,
    supports_consumer_groups: true,
  
    supports_streams: true,
    supports_subjects: false,
    supports_pull_consumers: true,
    supports_push_consumers: false,
    supports_durable_consumers: true,
    supports_redelivery: true,
    supports_ordering: true,
    supports_message_delay: false,
  
    supports_health_checks: true,
    supports_telemetry: true,
  }
}