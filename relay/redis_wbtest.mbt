///|
#cfg(target="native")
async test "redis_backend_push_pop_roundtrip" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let backend = RedisBackend::new(
    client,
    "relay:test:queue",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  let _ = client.del("relay:test:queue") catch { _ => 0L }

  backend.push("hello") catch {
    e => fail("push failed: \{e}")
  }

  let msg = backend.pop() catch {
    e => fail("pop failed: \{e}")
  }

  assert_eq(msg.payload, "hello")
}