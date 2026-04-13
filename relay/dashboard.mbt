///| Dashboard fornisce una rappresentazione visuale dello stato della RelayQueue.
pub struct Dashboard[T] {
  queue : RelayQueue[T]
  backend : InMemoryBackend[T]
}

///| new crea una nuova dashboard per la coda e il backend forniti.
pub fn[T] Dashboard::new(queue : RelayQueue[T], backend : InMemoryBackend[T]) -> Dashboard[T] {
  { queue: queue, backend: backend }
}

///| render stampa uno snapshot ANSI a colori dello stato della coda.
pub fn[T] Dashboard::render(self : Dashboard[T]) -> Unit {
  let main_size = self.queue.size()
  let dlq_size = self.backend.dlq_size()
  let in_flight = self.backend.in_flight.size()
  
  println("\u001b[2J\u001b[H") // Pulisce lo schermo e resetta il cursore
  println("\u001b[1;36m=== RELAY MESSAGE QUEUE DASHBOARD ===\u001b[0m")
  println("\u001b[33mStatus: \u001b[32mRUNNING\u001b[0m")
  println("-------------------------------------")
  println("\u001b[1mMain Queue:\u001b[0m    \{main_size} messages")
  println("\u001b[1mIn-Flight:\u001b[0m     \{in_flight} messages")
  println("\u001b[1;31mDead Letters:\u001b[0m  \{dlq_size} messages")
  println("-------------------------------------")
  println("\u001b[90mUltimo Update: snapshot in tempo reale\u001b[0m")
}

///| start_auto_render avvia un ciclo infinito di renderizzazione.
pub async fn[T] Dashboard::start_auto_render(self : Dashboard[T]) -> Unit {
  for ;; {
    self.render()
  }
}
