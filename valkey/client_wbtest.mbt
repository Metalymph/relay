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