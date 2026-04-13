async fn run_demo() -> Unit {
  let backend = @relay.InMemoryBackend::new(10)
  let q = backend.to_relay_queue()
  
  try {
    q.push("Hello, V2!")
    q.push("MoonBit Async Relay")
    
    let msg1 = q.pop()
    println("Received (ID \{msg1.id}): \{msg1.payload}")
    
    let msg2 = q.pop()
    println("Received (ID \{msg2.id}): \{msg2.payload}")
  } catch {
    _ => println("Error in demo")
  }
}

fn main {
  ignore(run_demo)
  println("Relay V2 is ready!")
}
