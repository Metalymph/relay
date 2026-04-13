async fn main {
  let backend = @relay.InMemoryBackend::new(100, policy=@relay.RetryPolicy::new(1))
  let queue = backend.to_relay_queue()
  let dashboard = @relay.Dashboard::new(queue, backend)
  
  try {
    // Puschiamo 10 messaggi
    for i = 1; i <= 10; i = i + 1 {
      queue.push("Msg \{i}")
    }
    
    // 3 In-Flight
    let _ = queue.pop()
    let _ = queue.pop()
    let _ = queue.pop()
    
    // 2 in DLQ (max_attempts = 1)
    let m1 = queue.pop()
    queue.nack(m1.id)
    let m2 = queue.pop()
    queue.nack(m2.id)
    
    // Risultato atteso: 
    // In coda: 10 - 3 - 2 = 5
    // In-Flight: 3
    // DLQ: 2
    
    dashboard.render()
    
    println("\nDemo Mixed State completata!")
  } catch {
    e => println("Errore: \{e}")
  }
}
