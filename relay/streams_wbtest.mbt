///|
#cfg(target="native")
async test "redis_stream_backend_push_pop_ack" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let stream = "relay:test:stream:backend"
  let group = "relay:test:stream:group"
  let consumer = "relay:test:stream:consumer"

  let _ = client.del(stream) catch { _ => 0L }

  let backend = RedisStreamBackend::new(
    client,
    stream,
    group,
    consumer,
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  backend.init() catch {
    e => fail("init failed: \{e}")
  }

  backend.push("hello") catch {
    e => fail("push failed: \{e}")
  }

  let msg = backend.pop() catch {
    e => fail("pop failed: \{e}")
  }

  assert_eq(msg.payload, "hello")

  backend.ack(msg.id) catch {
    e => fail("ack failed: \{e}")
  }
}

///|
#cfg(target="native")
async test "redis_stream_backend_to_relay_queue_push_pop_ack" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let stream = "relay:test:stream:queue"
  let group = "relay:test:stream:queue:group"
  let consumer = "relay:test:stream:queue:consumer"

  let _ = client.del(stream) catch { _ => 0L }

  let backend = RedisStreamBackend::new(
    client,
    stream,
    group,
    consumer,
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  backend.init() catch {
    e => fail("init failed: \{e}")
  }

  let queue = backend.to_relay_queue()

  queue.push("hello") catch {
    e => fail("queue push failed: \{e}")
  }

  let msg = queue.pop() catch {
    e => fail("queue pop failed: \{e}")
  }

  assert_eq(msg.payload, "hello")

  queue.ack(msg.id) catch {
    e => fail("queue ack failed: \{e}")
  }
}

///|
#cfg(target="native")
async test "redis_stream_backend_recover_pending" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let stream = "relay:test:stream:backend:recover"
  let group = "relay:test:stream:backend:recover:group"

  let _ = client.del(stream) catch { _ => 0L }

  let backend1 = RedisStreamBackend::new(
    client,
    stream,
    group,
    "consumer-1",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  backend1.init() catch {
    e => fail("init failed: \{e}")
  }

  backend1.push("recover-me") catch {
    e => fail("push failed: \{e}")
  }

  let original = backend1.pop() catch {
    e => fail("pop failed: \{e}")
  }

  assert_eq(original.payload, "recover-me")

  let client2 = @valkey.Client::connect("127.0.0.1", 6381) catch {
    e => fail("second connect failed: \{e}")
  }

  let backend2 = RedisStreamBackend::new(
    client2,
    stream,
    group,
    "consumer-2",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  let recovered = backend2.recover_pending(0) catch {
    e => fail("recover_pending failed: \{e}")
  }

  match recovered {
    Some(msg) => {
      assert_eq(msg.id, original.id)
      assert_eq(msg.payload, "recover-me")

      backend2.ack(msg.id) catch {
        e => fail("ack failed: \{e}")
      }
    }
    None => fail("Expected recovered pending message")
  }
}