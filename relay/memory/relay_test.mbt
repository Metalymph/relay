// Tests for Relay V3 (Ack/Retry/DLQ)

///|
test "in_memory_queue_basic" {
  let backend : InMemoryBackend[Int] = InMemoryBackend::new(10)
  assert_eq(backend.size(), 0)
}

///|
async test "in_memory_ack_nack_logic" {
  let backend : InMemoryBackend[String] = InMemoryBackend::new(10)
  let queue = backend.to_relay_queue()

  queue.push("data1")
  let msg = queue.pop()
  assert_eq(msg.payload, "data1")

  let _ = queue.nack(msg.id)
  assert_eq(queue.size(), 1)

  let msg2 = queue.pop()
  assert_eq(msg2.attempt_count(), 1)
  queue.ack(msg2.id)
  assert_eq(queue.size(), 0)
}

///|
async test "in_memory_dlq_logic" {
  // Max 2 attempts: 0 (initial) + 1 (retry) -> then DLQ
  let policy = @core.RetryPolicy::new(2)
  let backend : InMemoryBackend[String] = InMemoryBackend::new(10, policy~)
  let queue = backend.to_relay_queue()

  queue.push("fail_me")

  // Attempt 1
  let msg1 = queue.pop()
  let _ = queue.nack(msg1.id)
  assert_eq(queue.size(), 1)
  assert_eq(backend.dlq_size(), 0)

  // Attempt 2 (Max reached)
  let msg2 = queue.pop()
  assert_eq(msg2.attempt_count(), 1)
  let _ = queue.nack(msg2.id)

  // Should be in DLQ now
  assert_eq(queue.size(), 0)
  assert_eq(backend.dlq_size(), 1)
}

///|
async test "in_memory_nack_result" {
  let policy = @core.RetryPolicy::new(2)
  let backend : InMemoryBackend[String] = InMemoryBackend::new(10, policy~)
  let queue = backend.to_relay_queue()

  queue.push("retry")

  let msg1 = queue.pop()

  match queue.nack(msg1.id) {
    @core.Requeued => ()
    _ => fail("Expected Requeued")
  }

  let msg2 = queue.pop()

  match queue.nack(msg2.id) {
    @core.SentToDlq => ()
    _ => fail("Expected SentToDlq")
  }
}
