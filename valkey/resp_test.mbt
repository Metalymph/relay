struct FixedReader {
  data : Bytes
  mut offset : Int
}

fn FixedReader::new(s : String) -> FixedReader {
  { data: @utf8.encode(s), offset: 0 }
}

impl @io.Reader for FixedReader with _get_internal_buffer(_self) {
  @io.ReaderBuffer::new()
}

impl @io.Reader for FixedReader with _direct_read(self, buf, offset~, max_len~) {
  let available = self.data.length() - self.offset
  let len = if max_len < available { max_len } else { available }
  if len <= 0 { return 0 }
  for i = 0; i < len; i = i + 1 {
    buf[offset + i] = self.data[self.offset + i]
  }
  self.offset = self.offset + len
  len
}

async test "resp_parse_simple_string" {
  let reader = FixedReader::new("+OK\r\n")
  let parser = RespParser::new(reader)
  let val = try { parser.parse_value() } catch { e => fail("Failed: \{e}") }
  match val {
    SimpleString(s) => assert_eq(s, "OK")
    _ => fail("Expected SimpleString")
  }
}

async test "resp_parse_integer" {
  let reader = FixedReader::new(":1000\r\n")
  let parser = RespParser::new(reader)
  let val = parser.parse_value()
  match val {
    Integer(i) => assert_eq(i, 1000L)
    _ => fail("Expected Integer")
  }
}

async test "resp_parse_bulk_string" {
  let reader = FixedReader::new("$6\r\nfoobar\r\n")
  let parser = RespParser::new(reader)
  let val = parser.parse_value()
  match val {
    BulkString(Some(s)) => assert_eq(s, "foobar")
    _ => fail("Expected BulkString")
  }
}

async test "resp_parse_array" {
  let reader = FixedReader::new("*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n")
  let parser = RespParser::new(reader)
  let val = parser.parse_value()
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
