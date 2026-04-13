#cfg(target="native")
async fn main {
  let backend = @relay.InMemoryBackend::new(100, policy=@relay.RetryPolicy::new(1))
  let queue = backend.to_relay_queue()
  let dashboard = @relay.Dashboard::new(queue, backend)
  
  try {
    // 1. Push 10 messages
    for i = 1; i <= 10; i = i + 1 {
      queue.push("Msg \{i}")
    }
    
    // 2. Simulate 3 In-Flight messages
    let _ = queue.pop()
    let _ = queue.pop()
    let _ = queue.pop()
    
    // 3. Force 2 into DLQ (max_attempts = 1)
    let m1 = queue.pop()
    queue.nack(m1.id)
    let m2 = queue.pop()
    queue.nack(m2.id)
    
    // 4. Render dashboard
    dashboard.render()
    
    println("\nMixed State Demo completed successfully!")
  } catch {
    e => println("Error: \{e}")
  }
}

#cfg(not(target="native"))
fn main {
  println("This demo is only supported on native target.")
}
