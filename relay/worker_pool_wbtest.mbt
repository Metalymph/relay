///|
async test "worker_pool_concurrency" {
  let backend = InMemoryBackend::new(100, policy=RetryPolicy::new(1))
  let queue = backend.to_relay_queue()

  for i = 0; i < 5; i = i + 1 {
    queue.push("msg \{i}")
  }

  let pool = WorkerPool::new(queue, concurrency=2)

  @async.with_task_group(tg => {
    tg.spawn_bg(async fn() { pool.run(_payload => ()) })

    // Give workers time to process
    @async.pause()
    @async.pause()
    tg.return_immediately(()) catch {
      _ => ()
    }
  })

  let stats = pool.stats()

  assert_eq(stats.processed, 5)
  assert_eq(stats.succeeded, 5)
  assert_eq(stats.failed, 0)

  // 5 processed, 0 in flight, 0 in DLQ
  assert_eq(backend.in_flight.length(), 0)

  assert_eq(stats.ack_failed, 0)
  assert_eq(stats.nack_failed, 0)
}

///|
async test "worker_pool_nack_on_error" {
  let backend = InMemoryBackend::new(100, policy=RetryPolicy::new(1))
  let queue = backend.to_relay_queue()

  queue.push("fail")

  let pool = WorkerPool::new(queue, concurrency=1)

  @async.with_task_group(tg => {
    tg.spawn_bg(async fn() {
      pool.run(payload => {
        if payload == "fail" {
          raise QueueError::OperationFailed("Processing failed")
        }
      })
    })

    @async.pause()
    @async.pause()
    tg.return_immediately(()) catch {
      _ => ()
    }
  })

  let stats = pool.stats()

  assert_eq(stats.processed, 1)
  assert_eq(stats.succeeded, 0)
  assert_eq(stats.failed, 1)

  // Should have failed and reached DLQ
  assert_eq(backend.dlq_size(), 1)

  assert_eq(stats.ack_failed, 0)
  assert_eq(stats.nack_failed, 0)
}