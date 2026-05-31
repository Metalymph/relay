test "redis_streams_capabilities" {
  let caps = BackendCapabilities::redis_streams()

  assert_true(caps.supports_ack)
  assert_true(caps.supports_dlq)
  assert_true(caps.supports_pending)
  assert_true(caps.supports_consumer_groups)
}

test "in_memory_capabilities" {
  let caps = BackendCapabilities::in_memory()

  assert_true(caps.supports_ack)
  assert_true(caps.supports_dlq)

  assert_false(caps.supports_pending)
  assert_false(caps.supports_consumer_groups)
}