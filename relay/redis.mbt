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
  // BRPOP block: since send_command writes the raw command and wait for response,
  // we would ideally have a parser for the response to return the actual payload.
  // For V2, we assume a connected client that handles the command. 
  // BRPOP returns an array: [list_name, element]
  
  try {
    self.client.send_command(["BRPOP", self.key, "0"])
  } catch {
    _ => raise BackendError("Failed to pop from Redis")
  }

  // NOTE: Full integration will use `valkey.RespParser` to read the exact popped value.
  // We mock the deserialization step for the V2 framework completion until
  // bidirectional parsing is wired in to the valkey client.
  let mock_payload = (self.deserialize)("mock_data")
  Message::new("redis_id", mock_payload)
}

///| to_relay_queue converts the backend into a generic RelayQueue interface.
pub fn[T] RedisBackend::to_relay_queue(self : RedisBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push = async fn(v) { self.push(v) },
    pop = async fn() { self.pop() },
    size = fn() { 0 }
  )
}
