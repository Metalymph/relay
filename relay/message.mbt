///| Message[T] represents a wrapper for data sent through the queue.
pub struct Message[T] {
  ///| id is a unique identifier assigned by the backend.
  pub id : String
  ///| payload is the generic data contained in the message.
  pub payload : T
  ///| attempt_count tracks how many times this message has been handled (useful for retries).
  pub attempt_count : Int
}

///| new creates a new message.
pub fn[T] Message::new(id : String, payload : T, attempt_count~ : Int = 0) -> Message[T] {
  { id: id, payload: payload, attempt_count: attempt_count }
}
