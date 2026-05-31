#cfg(target="native")
pub struct RedisStreamBackend[T] {
  client : @valkey.Client
  stream : String
  dlq_stream : String
  group : String
  consumer : String
  serialize : (T) -> String
  deserialize : (String) -> T
}

#cfg(target="native")
pub fn[T] RedisStreamBackend::new(
  client : @valkey.Client,
  stream : String,
  group : String,
  consumer : String,
  serialize~ : (T) -> String,
  deserialize~ : (String) -> T,
) -> RedisStreamBackend[T] {
  {
    client,
    stream,
    dlq_stream: stream + ":dlq",
    group,
    consumer,
    serialize,
    deserialize,
  }
}

#cfg(target="native")
pub fn[T] RedisStreamBackend::new_with_dlq(
  client : @valkey.Client,
  stream : String,
  dlq_stream : String,
  group : String,
  consumer : String,
  serialize~ : (T) -> String,
  deserialize~ : (String) -> T,
) -> RedisStreamBackend[T] {
  { client, stream, dlq_stream, group, consumer, serialize, deserialize }
}

#cfg(target="native")
pub async fn[T] RedisStreamBackend::push(
  self : RedisStreamBackend[T],
  value : T,
) -> Unit raise Error {
  let payload = (self.serialize)(value)
  let _ = self.client.xadd(self.stream, payload)
}

#cfg(target="native")
pub async fn[T] RedisStreamBackend::init(
  self : RedisStreamBackend[T],
) -> Unit raise Error {
  self.client.xgroup_create(self.stream, self.group)
}

///|
/// pop reads one message from the stream consumer group.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::pop(
  self : RedisStreamBackend[T],
) -> Message[T] raise Error {
  match self.client.xreadgroup(self.stream, self.group, self.consumer, 1) {
    Some((id, payload)) => Message::new(id, (self.deserialize)(payload))
    None => raise QueueError::OperationFailed("Stream is empty")
  }
}

///|
/// pop_block waits for a message for up to `block_ms` milliseconds.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::pop_block(
  self : RedisStreamBackend[T],
  block_ms : Int,
) -> Message[T] raise Error {
  match self.client.xreadgroup_block(
    self.stream,
    self.group,
    self.consumer,
    1,
    block_ms,
  ) {
    Some((id, payload)) => Message::new(id, (self.deserialize)(payload))
    None => raise QueueError::OperationFailed("No stream message available")
  }
}

///|
/// recover_pending claims one pending message idle for at least `min_idle_ms`.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::recover_pending(
  self : RedisStreamBackend[T],
  min_idle_ms : Int,
) -> Message[T]? raise Error {
  match self.client.xautoclaim(
    self.stream,
    self.group,
    self.consumer,
    min_idle_ms,
  ) {
    Some((id, payload)) => Some(Message::new(id, (self.deserialize)(payload)))
    None => None
  }
}

///|
/// recover_or_pop first tries to recover a pending message, then falls back to
/// blocking reads for new stream entries.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::recover_or_pop(
  self : RedisStreamBackend[T],
  min_idle_ms : Int,
  block_ms : Int,
) -> Message[T] raise Error {
  match self.recover_pending(min_idle_ms) {
    Some(msg) => msg
    None => self.pop_block(block_ms)
  }
}

///|
/// pending_count returns the number of unacknowledged messages.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::pending_count(
  self : RedisStreamBackend[T],
) -> Int64 raise Error {
  self.client.xpending_count(self.stream, self.group)
}

///|
/// ack acknowledges a stream message by id.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::ack(
  self : RedisStreamBackend[T],
  id : String,
) -> Unit raise Error {
  let acked = self.client.xack(self.stream, self.group, id)
  if acked != 1L {
    raise QueueError::OperationFailed("XACK did not acknowledge message")
  }
}

///|
/// dead_letter writes a payload to the configured DLQ stream.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::dead_letter(
  self : RedisStreamBackend[T],
  value : T,
) -> Unit raise Error {
  let payload = (self.serialize)(value)
  let _ = self.client.xadd(self.dlq_stream, payload)
}

///|
/// nack_message moves the message payload to the DLQ and acknowledges the
/// original stream entry.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::nack_message(
  self : RedisStreamBackend[T],
  msg : Message[T],
) -> Unit raise Error {
  self.dead_letter(msg.payload)
  self.ack(msg.id)
}

///|
/// nack currently leaves the message pending when only an id is available.
///
/// Use `nack_message` when the payload is available and should be moved to DLQ.
///|
/// nack leaves the stream message pending when only an id is available.
///
/// Use `nack_message` when the payload is available and should be moved to DLQ.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::nack(
  _self : RedisStreamBackend[T],
  _id : String,
) -> NackResult raise Error {
  Requeued
}

///|
/// to_relay_queue exports the stream backend as a generic RelayQueue.
#cfg(target="native")
pub fn[T] RedisStreamBackend::to_relay_queue(
  self : RedisStreamBackend[T],
) -> RelayQueue[T] {
  RelayQueue::new(
    push=async fn(v) { self.push(v) },
    pop=async fn() { self.pop() },
    ack=async fn(id) { self.ack(id) },
    nack=async fn(id) { self.nack(id) },
    size=fn() { 0 },
  )
}

///|
/// to_relay_queue_with_recovery exports the stream backend as a RelayQueue
/// whose pop path first recovers pending entries before blocking for new ones.
#cfg(target="native")
pub fn[T] RedisStreamBackend::to_relay_queue_with_recovery(
  self : RedisStreamBackend[T],
  min_idle_ms : Int,
  block_ms : Int,
) -> RelayQueue[T] {
  RelayQueue::new(
    push=async fn(v) { self.push(v) },
    pop=async fn() { self.recover_or_pop(min_idle_ms, block_ms) },
    ack=async fn(id) { self.ack(id) },
    nack=async fn(id) { self.nack(id) },
    size=fn() { 0 },
  )
}

#cfg(target="native")
pub fn[T] RedisStreamBackend::queue_metrics(
  self : RedisStreamBackend[T],
) -> QueueMetrics {
  {
    size: None,
    dlq_size: None,
    pending_count: None,
  }
}