///| Errore fittizio per il test
suberror MyError {
  ProcessingFailed
}

async test "worker_pool_concurrency_and_ack" {
  let backend : InMemoryBackend[String] = InMemoryBackend::new(20)
  let queue = backend.to_relay_queue()
  let pool = WorkerPool::new(queue, concurrency=2)
  let processed : @hashmap.HashMap[String, Bool] = @hashmap.new()
  
  for i = 1; i <= 10; i = i + 1 {
    queue.push("Task \{i}")
  }
  
  @async.with_task_group(async fn(tg) {
    tg.spawn_bg(async fn() {
      pool.run(async fn(payload) {
        processed.set(payload, true)
      })
    })
    
    for ;; {
      if processed.length() >= 10 {
        tg.return_immediately(())
        break
      }
      @async.pause()
    }
  })

  assert_eq(processed.length(), 10)
  assert_eq(backend.count, 0)
}

async test "worker_pool_nack_handling" {
  let backend : InMemoryBackend[String] = InMemoryBackend::new(10, policy=RetryPolicy::new(1))
  let queue = backend.to_relay_queue()
  let pool = WorkerPool::new(queue, concurrency=1)
  
  queue.push("Faulty Task")
  
  @async.with_task_group(async fn(tg) {
    tg.spawn_bg(async fn() {
      pool.run(async fn(_) {
        raise ProcessingFailed
      })
    })
    
    for ;; {
      if backend.dlq_size() >= 1 {
        tg.return_immediately(())
        break
      }
      @async.pause()
    }
  })
  
  assert_eq(backend.dlq_size(), 1)
}
