///| Dashboard provides a visual representation of the RelayQueue state.
pub struct Dashboard[T] {
  queue : RelayQueue[T]
  backend : InMemoryBackend[T]
}

///| new creates a new dashboard for the provided queue and backend.
pub fn[T] Dashboard::new(queue : RelayQueue[T], backend : InMemoryBackend[T]) -> Dashboard[T] {
  { queue: queue, backend: backend }
}

///| render prints an ANSI color-coded snapshot of the current queue state.
pub fn[T] Dashboard::render(self : Dashboard[T]) -> Unit {
  let main_size = self.queue.size()
  let dlq_size = self.backend.dlq_size()
  let in_flight = self.backend.in_flight.length()
  
  println("\u001b[2J\u001b[H") // Clear screen and reset cursor
  println("\u001b[1;36m=== RELAY MESSAGE QUEUE DASHBOARD ===\u001b[0m")
  println("\u001b[33mStatus: \u001b[32mRUNNING\u001b[0m")
  println("-------------------------------------")
  println("\u001b[1mMain Queue:\u001b[0m    \{main_size} messages")
  println("\u001b[1mIn-Flight:\u001b[0m     \{in_flight} messages")
  println("\u001b[1;31mDead Letters:\u001b[0m  \{dlq_size} messages")
  println("-------------------------------------")
  println("\u001b[90mLast Update: real-time snapshot\u001b[0m")
}

///| start_auto_render starts an infinite loop of rendering.
pub fn[T] Dashboard::start_auto_render(self : Dashboard[T]) -> Unit {
  for ;; {
    self.render()
  }
}
