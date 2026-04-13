///| RetryPolicy defines how the queue handles failed message processing.
pub struct RetryPolicy {
  max_attempts : Int
}

///| new_policy creates a custom retry policy.
pub fn RetryPolicy::new(max_attempts : Int) -> RetryPolicy {
  { max_attempts: max_attempts }
}

///| default_policy provides a standard policy with 3 max attempts.
pub fn RetryPolicy::default() -> RetryPolicy {
  { max_attempts: 3 }
}

///| RelayQueue is the main entry point for interacting with the message queue.
/// It uses a closure-based backend abstraction to support multiple storage engines (Memory, Redis, etc.).
pub struct RelayQueue[T] {
  push_fn : async (T) -> Unit raise Error
  pop_fn : async () -> Message[T] raise Error
  ack_fn : async (String) -> Unit raise Error
  nack_fn : async (String) -> Unit raise Error
  size_fn : () -> Int
}

///| new creates a new RelayQueue with the provided backend functions.
pub fn[T] RelayQueue::new(
  push~ : async (T) -> Unit raise Error,
  pop~ : async () -> Message[T] raise Error,
  ack~ : async (String) -> Unit raise Error,
  nack~ : async (String) -> Unit raise Error,
  size~ : () -> Int
) -> RelayQueue[T] {
  { push_fn: push, pop_fn: pop, ack_fn: ack, nack_fn: nack, size_fn: size }
}

///| push adds a value to the queue. Asynchronous and thread-safe via the underlying backend.
pub async fn[T] RelayQueue::push(self : RelayQueue[T], value : T) -> Unit raise Error {
  (self.push_fn)(value)
}

///| pop removes and returns a value from the queue. Suspends if the queue is empty.
/// In V3, a popped message is considered "In Flight" until acknowledged.
pub async fn[T] RelayQueue::pop(self : RelayQueue[T]) -> Message[T] raise Error {
  (self.pop_fn)()
}

///| ack confirms that a message has been processed successfully.
/// The backend will permanently remove the message from its tracking system.
pub async fn[T] RelayQueue::ack(self : RelayQueue[T], id : String) -> Unit raise Error {
  (self.ack_fn)(id)
}

///| nack (negative acknowledgement) informs the queue that processing failed.
/// The backend will typically re-queue the message for another attempt, unless it exceeds the RetryPolicy.
pub async fn[T] RelayQueue::nack(self : RelayQueue[T], id : String) -> Unit raise Error {
  (self.nack_fn)(id)
}

///| size returns the current number of items in the queue.
pub fn[T] RelayQueue::size(self : RelayQueue[T]) -> Int {
  (self.size_fn)()
}
