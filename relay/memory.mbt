///| InMemoryBackend uses @aqueue.Queue from moonbitlang/async for local, non-blocking storage.
pub struct InMemoryBackend[T] {
  queue : @aqueue.Queue[Message[T]]
  mut next_id : Int
  mut count : Int
}

///| new creates a new InMemoryBackend with a fixed capacity.
pub fn[T] InMemoryBackend::new(capacity : Int) -> InMemoryBackend[T] {
  {
    queue: @aqueue.Queue::new(kind=Blocking(capacity)),
    next_id: 1,
    count: 0
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

///| pop retrieves a message from the internal queue.
pub async fn[T] InMemoryBackend::pop(self : InMemoryBackend[T]) -> Message[T] raise Error {
  let msg = self.queue.get()
  self.count = self.count - 1
  msg
}

///| size returns the cached count of messages.
pub fn[T] InMemoryBackend::size(self : InMemoryBackend[T]) -> Int {
  self.count
}

///| to_relay_queue converts the backend into a generic RelayQueue interface.
pub fn[T] InMemoryBackend::to_relay_queue(self : InMemoryBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push = async fn(v) { self.push(v) },
    pop = async fn() { self.pop() },
    size = fn() { self.count }
  )
}
