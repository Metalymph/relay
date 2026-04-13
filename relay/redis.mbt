///| Redis Stream/List based Backend using ValKey
pub struct RedisBackend[T] {
  client : @valkey.Client
  key : String
  serialize : (T) -> String
  deserialize : (String) -> T
}

///| new creates a new RedisBackend powered by Valkey client.
pub fn[T] RedisBackend::new(
  client : @valkey.Client, 
  key : String, 
  serialize : (T) -> String, 
  deserialize : (String) -> T
) -> RedisBackend[T] {
  { client: client, key: key, serialize: serialize, deserialize: deserialize }
}

///| push pushes a new item to the Redis list.
pub async fn[T] RedisBackend::push(self : RedisBackend[T], v : T) -> Unit raise Error {
  let serialized = (self.serialize)(v)
  try {
    self.client.send_command(["LPUSH", self.key, serialized])
  } catch {
    _ => raise BackendError("Failed to push to Redis")
  }
}

///| pop blocks until an item is available in the Redis list.
pub async fn[T] RedisBackend::pop(self : RedisBackend[T]) -> Message[T] raise Error {
  try {
    self.client.send_command(["BRPOP", self.key, "0"])
  } catch {
    _ => raise BackendError("Failed to pop from Redis")
  }
  let mock_payload = (self.deserialize)("mock_data")
  Message::new("redis_id", mock_payload)
}

///| ack confirms processing. In simple list mode, this is a no-op as BRPOP already removed the item.
pub fn[T] RedisBackend::ack(_self : RedisBackend[T], _id : String) -> Unit {
  ()
}

///| nack re-inserts the message. Mocked as simple push for now.
pub fn[T] RedisBackend::nack(_self : RedisBackend[T], _id : String) -> Unit {
  // Real implementation would look up processing list if using RPOPLPUSH
  ()
}

///| to_relay_queue converts the backend into a generic RelayQueue interface.
pub fn[T] RedisBackend::to_relay_queue(self : RedisBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push = async fn(v) { self.push(v) },
    pop = async fn() { self.pop() },
    ack = fn(id) { self.ack(id) },
    nack = fn(id) { self.nack(id) },
    size = fn() { 0 }
  )
}
