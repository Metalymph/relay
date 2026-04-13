///| InMemoryBackend uses @aqueue.Queue from moonbitlang/async for local, non-blocking storage.
pub struct InMemoryBackend[T] {
  queue : @aqueue.Queue[Message[T]]
  dlq : @aqueue.Queue[Message[T]]
  in_flight : @hashmap.HashMap[String, Message[T]]
  policy : RetryPolicy
  mut next_id : Int
  mut count : Int
  mut dlq_count : Int
}

///| new creates a new InMemoryBackend with a fixed capacity and optional policy.
pub fn[T] InMemoryBackend::new(
  capacity : Int, 
  policy~ : RetryPolicy = RetryPolicy::default()
) -> InMemoryBackend[T] {
  {
    queue: @aqueue.Queue::new(kind=Blocking(capacity)),
    dlq: @aqueue.Queue::new(kind=Blocking(capacity)),
    in_flight: @hashmap.new(),
    policy: policy,
    next_id: 1,
    count: 0,
    dlq_count: 0
  }
}

///| push adds a message to the internal queue.
pub async fn[T] InMemoryBackend::push(self : InMemoryBackend[T], v : T) -> Unit raise Error {
  let id = self.next_id.to_string()
  self.next_id = self.next_id + 1
  self.count = self.count + 1
  let msg = Message::new(id, v)
  self.queue.put(msg)
}

///| pop retrieves a message and marks it as in-flight.
pub async fn[T] InMemoryBackend::pop(self : InMemoryBackend[T]) -> Message[T] raise Error {
  let msg = self.queue.get()
  self.in_flight.set(msg.id, msg)
  self.count = self.count - 1
  msg
}

///| ack confirms successful processing and removes from in-flight.
pub fn[T] InMemoryBackend::ack(self : InMemoryBackend[T], id : String) -> Unit {
  self.in_flight.remove(id)
}

///| nack re-inserts the message into the queue or moves to DLQ if max attempts reached.
pub async fn[T] InMemoryBackend::nack(self : InMemoryBackend[T], id : String) -> Unit raise Error {
  match self.in_flight.get(id) {
    Some(msg) => {
      self.in_flight.remove(id)
      msg.attempt_count = msg.attempt_count + 1
      if msg.attempt_count < self.policy.max_attempts {
        self.queue.put(msg)
        self.count = self.count + 1
      } else {
        self.dlq.put(msg)
        self.dlq_count = self.dlq_count + 1
      }
    }
    None => ()
  }
}

///| size returns the cached count of messages in the main queue.
pub fn[T] InMemoryBackend::size(self : InMemoryBackend[T]) -> Int {
  self.count
}

///| dlq_size returns the count of messages in the Dead Letter Queue.
pub fn[T] InMemoryBackend::dlq_size(self : InMemoryBackend[T]) -> Int {
  self.dlq_count
}

///| to_relay_queue converts the backend into a generic RelayQueue interface.
pub fn[T] InMemoryBackend::to_relay_queue(self : InMemoryBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push = async fn(v) { self.push(v) },
    pop = async fn() { self.pop() },
    ack = async fn(id) { self.ack(id) },
    nack = async fn(id) { self.nack(id) },
    size = fn() { self.count }
  )
}
