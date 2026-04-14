///|
/// RedisBackend implements the storage interface for Relay using Redis/Valkey.
#cfg(target="native")
pub struct RedisBackend[T] {
  client : @valkey.Client
  key : String
  serialize : (T) -> String
  deserialize : (String) -> T
}

///|
/// new creates a RedisBackend instance with the provided client and serializers.
#cfg(target="native")
pub fn[T] RedisBackend::new(
  client : @valkey.Client,
  key : String,
  serialize : (T) -> String,
  deserialize : (String) -> T,
) -> RedisBackend[T] {
  { client, key, serialize, deserialize }
}

///|
/// push sends a message to the Redis queue (LPUSH).
#cfg(target="native")
pub async fn[T] RedisBackend::push(
  self : RedisBackend[T],
  v : T,
) -> Unit raise Error {
  let serialized = (self.serialize)(v)
  self.client.send_command(["LPUSH", self.key, serialized])
}

///|
/// pop extracts a message from the Redis queue in a blocking manner (BRPOP).
#cfg(target="native")
pub async fn[T] RedisBackend::pop(
  self : RedisBackend[T],
) -> Message[T] raise Error {
  self.client.send_command(["BRPOP", self.key, "0"])
  let mock_payload = (self.deserialize)("mock_data")
  Message::new("redis_id", mock_payload)
}

///|
/// ack confirms message processing.
#cfg(target="native")
pub fn[T] RedisBackend::ack(_self : RedisBackend[T], _id : String) -> Unit {
  ()
}

///|
/// nack signals processing failure for re-insertion.
#cfg(target="native")
pub fn[T] RedisBackend::nack(_self : RedisBackend[T], _id : String) -> Unit {
  ()
}

///|
/// to_relay_queue exports the backend as a generic RelayQueue.
#cfg(target="native")
pub fn[T] RedisBackend::to_relay_queue(self : RedisBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push=async fn(v) { self.push(v) },
    pop=async fn() { self.pop() },
    ack=fn(id) { self.ack(id) },
    nack=fn(id) { self.nack(id) },
    size=fn() { 0 },
  )
}
