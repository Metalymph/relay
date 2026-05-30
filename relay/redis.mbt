///|
/// RedisBackend implements the storage interface for Relay using Redis/Valkey.
#cfg(target="native")
pub struct RedisBackend[T] {
  client : @valkey.Client
  key : String
  serialize : (T) -> String
  deserialize : (String) -> T
  mut next_id : Int
}

///|
/// new creates a RedisBackend instance with the provided client and serializers.
#cfg(target="native")
pub fn[T] RedisBackend::new(
  client : @valkey.Client,
  key : String,
  serialize~ : (T) -> String,
  deserialize~ : (String) -> T,
) -> RedisBackend[T] {
  { client, key, serialize, deserialize, next_id: 1 }
}

///|
/// push sends a message to the Redis queue using RPUSH.
#cfg(target="native")
pub async fn[T] RedisBackend::push(
  self : RedisBackend[T],
  v : T,
) -> Unit raise Error {
  let serialized = (self.serialize)(v)
  match self.client.request(["RPUSH", self.key, serialized]) {
    @valkey.Integer(_) => ()
    _ => raise QueueError::OperationFailed("Unexpected RPUSH response")
  }
}

///|
/// pop extracts a message from the Redis queue in a blocking manner using BLPOP.
#cfg(target="native")
pub async fn[T] RedisBackend::pop(
  self : RedisBackend[T],
) -> Message[T] raise Error {
  match self.client.request(["BLPOP", self.key, "0"]) {
    @valkey.Array(Some(items)) => {
      if items.length() != 2 {
        raise QueueError::OperationFailed("Unexpected BLPOP response length")
      }

      match items[1] {
        @valkey.BulkString(Some(payload)) => {
          let id = "valkey:\{self.key}:\{self.next_id}"
          self.next_id = self.next_id + 1
          Message::new(id, (self.deserialize)(payload))
        }
        _ => raise QueueError::OperationFailed("Unexpected BLPOP payload")
      }
    }
    _ => raise QueueError::OperationFailed("Unexpected BLPOP response")
  }
}

///|
/// pop_nowait extracts a message without blocking, returning None when empty.
#cfg(target="native")
pub async fn[T] RedisBackend::pop_nowait(
  self : RedisBackend[T],
) -> Message[T]? raise Error {
  match self.client.request(["LPOP", self.key]) {
    @valkey.BulkString(Some(payload)) => {
      let id = "valkey:\{self.key}:\{self.next_id}"
      self.next_id = self.next_id + 1
      Some(Message::new(id, (self.deserialize)(payload)))
    }
    @valkey.BulkString(None) => None
    _ => raise QueueError::OperationFailed("Unexpected LPOP response")
  }
}

///|
/// size returns the current number of queued messages.
#cfg(target="native")
pub async fn[T] RedisBackend::size(
  self : RedisBackend[T],
) -> Int raise Error {
  match self.client.request(["LLEN", self.key]) {
    @valkey.Integer(n) => n.to_int()
    _ => raise QueueError::OperationFailed("Unexpected LLEN response")
  }
}

///|
/// ack confirms message processing.
///
/// Current Valkey backend pop semantics remove the message from the list when
/// BLPOP returns, so ack is a no-op until visibility-timeout tracking is added.
#cfg(target="native")
pub async fn[T] RedisBackend::ack(
  _self : RedisBackend[T],
  _id : String,
) -> Unit raise Error {
  ()
}

///|
/// nack signals processing failure.
///
/// Current Valkey backend does not retain the popped payload by id, so nack is
/// a no-op until in-flight tracking is added.
///|
/// nack is a no-op for the list-based Valkey backend.
///
/// BLPOP removes the message immediately, so the backend cannot requeue by id.
#cfg(target="native")
pub async fn[T] RedisBackend::nack(
  _self : RedisBackend[T],
  _id : String,
) -> NackResult raise Error {
  SentToDlq
}

///|
/// to_relay_queue exports the backend as a generic RelayQueue.
#cfg(target="native")
pub fn[T] RedisBackend::to_relay_queue(self : RedisBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push=async fn(v) { self.push(v) },
    pop=async fn() { self.pop() },
    ack=async fn(id) { self.ack(id) },
    nack=async fn(id) { self.nack(id) },
    size=fn() { 0 },
  )
}