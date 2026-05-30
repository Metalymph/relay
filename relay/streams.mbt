#cfg(target="native")
pub struct RedisStreamBackend[T] {
  client : @valkey.Client
  stream : String
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
    group,
    consumer,
    serialize,
    deserialize,
  }
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
/// nack currently leaves the message pending in the stream consumer group.
///
/// The message can later be recovered using pending-entry handling.
#cfg(target="native")
pub async fn[T] RedisStreamBackend::nack(
  _self : RedisStreamBackend[T],
  _id : String,
) -> Unit raise Error {
  ()
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