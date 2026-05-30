///|
struct FixedReader {
  data : Bytes
  mut offset : Int
  internal_buffer : @io.ReaderBuffer
}

fn FixedReader::new(s : String) -> FixedReader {
  {
    data: @utf8.encode(s),
    offset: 0,
    internal_buffer: @io.ReaderBuffer::new(),
  }
}

///|
impl @io.Reader for FixedReader with _get_internal_buffer(self) {
  self.internal_buffer
}

///|
impl @io.Reader for FixedReader with _direct_read(self, buf, offset~, max_len~) {
  let available = self.data.length() - self.offset
  let len = if max_len < available { max_len } else { available }
  if len <= 0 {
    return 0
  }
  for i = 0; i < len; i = i + 1 {
    buf[offset + i] = self.data[self.offset + i]
  }
  self.offset = self.offset + len
  len
}

///|
async test "resp_parse_simple_string" {
  let reader = FixedReader::new("+OK\r\n")
  let parser = RespParser::new(reader)
  let val = parser.parse_value() catch { e => fail("Failed: \{e}") }
  match val {
    SimpleString(s) => assert_eq(s, "OK")
    _ => fail("Expected SimpleString")
  }
}

///|
async test "resp_parse_integer" {
  let reader = FixedReader::new(":1000\r\n")
  let parser = RespParser::new(reader)
  let val = parser.parse_value() catch { e => fail("Failed: \{e}") }
  match val {
    Integer(i) => assert_eq(i, 1000L)
    _ => fail("Expected Integer")
  }
}

///|
async test "resp_parse_bulk_string" {
  let reader = FixedReader::new("$6\r\nfoobar\r\n")
  let parser = RespParser::new(reader)
  let val = parser.parse_value() catch { e => fail("Failed: \{e}") }
  match val {
    BulkString(Some(s)) => assert_eq(s, "foobar")
    _ => fail("Expected BulkString")
  }
}

///|
async test "resp_parse_array" {
  let reader = FixedReader::new("*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n")
  let parser = RespParser::new(reader)
  let val = parser.parse_value() catch { e => fail("Failed: \{e}") }
  match val {
    Array(Some(arr)) => {
      assert_eq(arr.length(), 2)
      match arr[0] {
        BulkString(Some(s)) => assert_eq(s, "foo")
        _ => fail("Expected foo")
      }
    }
    _ => fail("Expected Array")
  }
}

///|
test "resp_encode_command_uses_utf8_byte_lengths" {
  let encoded = @utf8.decode(encode_command(["SET", "city", "città"]))

  assert_eq(encoded, "*3\r\n$3\r\nSET\r\n$4\r\ncity\r\n$6\r\ncittà\r\n")
}

///|
test "resp_encode_command_uses_utf8_byte_lengths_for_emoji" {
  let encoded = @utf8.decode(encode_command(["SET", "emoji", "🚀"]))

  assert_eq(encoded, "*3\r\n$3\r\nSET\r\n$5\r\nemoji\r\n$4\r\n🚀\r\n")
}

///|
test "resp_encode_command_ascii" {
  let encoded = @utf8.decode(encode_command(["PING"]))
  assert_eq(encoded, "*1\r\n$4\r\nPING\r\n")
}

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