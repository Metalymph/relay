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