///|
#cfg(target="native")
async test "valkey_client_ping_pong" {
  let client = Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let res = client.request(["PING"]) catch {
    e => fail("PING failed: \{e}")
  }

  match res {
    SimpleString(s) => assert_eq(s, "PONG")
    _ => fail("Expected PONG")
  }
}

///|
#cfg(target="native")
async test "valkey_ping" {
  let client = Client::connect("127.0.0.1", 6381) catch {
    e => fail("Connect failed: \{e}")
  }

  client.ping() catch {
    e => fail("Ping failed: \{e}")
  }
}

///|
#cfg(target="native")
async test "valkey_set_get" {
  let client = Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  client.set("relay:test:key", "hello") catch {
    e => fail("SET failed: \{e}")
  }

  let value = client.get("relay:test:key") catch {
    e => fail("GET failed: \{e}")
  }

  assert_eq(value, Some("hello"))
}

///|
#cfg(target="native")
async test "valkey_get_missing_key" {
  let client = Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let value = client.get("relay:test:missing") catch {
    e => fail("GET failed: \{e}")
  }

  assert_eq(value, None)
}

///|
#cfg(target="native")
async test "valkey_del" {
  let client = Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  client.set("relay:test:del", "value") catch {
    e => fail("SET failed: \{e}")
  }

  let deleted = client.del("relay:test:del") catch {
    e => fail("DEL failed: \{e}")
  }

  assert_eq(deleted, 1L)

  let value = client.get("relay:test:del") catch {
    e => fail("GET failed: \{e}")
  }

  assert_eq(value, None)
}

///|
#cfg(target="native")
async test "valkey_exists" {
  let client = Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let missing = client.exists("relay:test:exists:missing") catch {
    e => fail("EXISTS failed: \{e}")
  }

  assert_false(missing)

  client.set("relay:test:exists", "value") catch {
    e => fail("SET failed: \{e}")
  }

  let present = client.exists("relay:test:exists") catch {
    e => fail("EXISTS failed: \{e}")
  }

  assert_true(present)
}

///|
#cfg(target="native")
async test "valkey_stream_xadd_read_ack" {
  let client = Client::connect("127.0.0.1", 6381) catch {
    _ => return
  }

  let stream = "relay:test:stream"
  let group = "relay:test:group"
  let consumer = "relay:test:consumer"

  let _ = client.del(stream) catch { _ => 0L }

  client.xgroup_create(stream, group) catch {
    e => fail("XGROUP CREATE failed: \{e}")
  }

  let id = client.xadd(stream, "hello") catch {
    e => fail("XADD failed: \{e}")
  }

  assert_true(id.length() > 0)

  let msg = client.xreadgroup(stream, group, consumer, 1) catch {
    e => fail("XREADGROUP failed: \{e}")
  }

  match msg {
    Some((read_id, payload)) => {
      assert_eq(read_id, id)
      assert_eq(payload, "hello")

      let acked = client.xack(stream, group, read_id) catch {
        e => fail("XACK failed: \{e}")
      }

      assert_eq(acked, 1L)
    }
    None => fail("Expected stream message")
  }
}