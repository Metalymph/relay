///|
/// Message[T] represents a wrapper for data sent through the queue.
pub struct Message[T] {
  /// id is a unique identifier assigned by the backend.
  id : String
  /// payload is the generic data contained in the message.
  payload : T
  /// attempt_count tracks how many times this message has been handled (useful for retries).
  mut attempt_count : Int
}

///|
pub fn[T] Message::increment_attempt(self : Message[T]) -> Unit {
  self.attempt_count = self.attempt_count + 1
}

///|
pub fn[T] Message::attempt_count(self : Message[T]) -> Int {
  self.attempt_count
}

///|
/// new creates a new message.
pub fn[T] Message::new(
  id : String,
  payload : T,
  attempt_count? : Int = 0,
) -> Message[T] {
  { id, payload, attempt_count }
}
