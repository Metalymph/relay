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

///|
#cfg(target="native")
async test "redis_backend_pop_nowait_empty" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let backend = RedisBackend::new(
    client,
    "relay:test:queue:empty",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  let _ = client.del("relay:test:queue:empty") catch { _ => 0L }

  let msg = backend.pop_nowait() catch {
    e => fail("pop_nowait failed: \{e}")
  }

  match msg {
    None => ()
    Some(_) => fail("Expected no message")
  }
}

///|
#cfg(target="native")
async test "redis_backend_pop_nowait_roundtrip" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let backend = RedisBackend::new(
    client,
    "relay:test:queue:nowait",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  let _ = client.del("relay:test:queue:nowait") catch { _ => 0L }

  backend.push("hello") catch {
    e => fail("push failed: \{e}")
  }

  let msg = backend.pop_nowait() catch {
    e => fail("pop_nowait failed: \{e}")
  }

  match msg {
    Some(m) => assert_eq(m.payload, "hello")
    None => fail("Expected message")
  }
}

///|
///|
#cfg(target="native")
async test "redis_backend_size" {
  let client = @valkey.Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let backend = RedisBackend::new(
    client,
    "relay:test:size",
    serialize=fn(v : String) { v },
    deserialize=fn(v : String) { v },
  )

  let _ = client.del("relay:test:size") catch { _ => 0L }

  let empty_size = backend.size() catch {
    e => fail("size failed: \{e}")
  }
  assert_eq(empty_size, 0)

  backend.push("a") catch {
    e => fail("push a failed: \{e}")
  }

  backend.push("b") catch {
    e => fail("push b failed: \{e}")
  }

  let filled_size = backend.size() catch {
    e => fail("size failed: \{e}")
  }
  assert_eq(filled_size, 2)
}