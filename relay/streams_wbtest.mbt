///|
#cfg(target="native")
async test "redis_stream_backend_nack_message_moves_to_dlq" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let stream = "relay:test:stream:dlq"
  let dlq_stream = "relay:test:stream:dlq:dead"
  let group = "relay:test:stream:dlq:group"

  let _ = client.del(stream) catch { _ => 0L }
  let _ = client.del(dlq_stream) catch { _ => 0L }

  let backend = RedisStreamBackend::new_with_dlq(
    client,
    stream,
    dlq_stream,
    group,
    "consumer-1",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  backend.init() catch {
    e => fail("init failed: \{e}")
  }

  backend.push("dead-letter-me") catch {
    e => fail("push failed: \{e}")
  }

  let msg = backend.pop() catch {
    e => fail("pop failed: \{e}")
  }

  backend.nack_message(msg) catch {
    e => fail("nack_message failed: \{e}")
  }

  let pending_after = backend.pending_count() catch {
    e => fail("pending_count failed: \{e}")
  }

  assert_eq(pending_after, 0L)

  let dlq_client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    e => fail("dlq connect failed: \{e}")
  }

  let dlq_backend = RedisStreamBackend::new(
    dlq_client,
    dlq_stream,
    "relay:test:stream:dlq:dead:group",
    "dlq-consumer",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  dlq_backend.init() catch {
    e => fail("dlq init failed: \{e}")
  }

  let dlq_msg = dlq_backend.pop() catch {
    e => fail("dlq pop failed: \{e}")
  }

  assert_eq(dlq_msg.payload, "dead-letter-me")

  dlq_backend.ack(dlq_msg.id) catch {
    e => fail("dlq ack failed: \{e}")
  }
}