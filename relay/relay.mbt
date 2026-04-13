///| RelayQueue is the main entry point for interacting with the message queue.
/// It uses a closure-based backend abstraction to support multiple storage engines (Memory, Redis, etc.).
pub struct RelayQueue[T] {
  push_fn : async (T) -> Unit raise Error
  pop_fn : async () -> Message[T] raise Error
  size_fn : () -> Int
}

///| new creates a new RelayQueue with the provided backend functions.
pub fn[T] RelayQueue::new(
  push~ : async (T) -> Unit raise Error,
  pop~ : async () -> Message[T] raise Error,
  size~ : () -> Int
) -> RelayQueue[T] {
  { push_fn: push, pop_fn: pop, size_fn: size }
}

///| push adds a value to the queue. Asynchronous and thread-safe via the underlying backend.
pub async fn[T] RelayQueue::push(self : RelayQueue[T], value : T) -> Unit raise Error {
  (self.push_fn)(value)
}

///| pop removes and returns a value from the queue. Suspends if the queue is empty.
pub async fn[T] RelayQueue::pop(self : RelayQueue[T]) -> Message[T] raise Error {
  (self.pop_fn)()
}

///| size returns the current number of items in the queue.
pub fn[T] RelayQueue::size(self : RelayQueue[T]) -> Int {
  (self.size_fn)()
}
