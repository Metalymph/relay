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