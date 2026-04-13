///| RespValue represents the different types in the RESP (Redis Serialization Protocol).
pub enum RespValue {
  SimpleString(String)
  Error(String)
  Integer(Int64)
  BulkString(Option[String])
  Array(Option[Array[RespValue]])
} derive(Debug, ToJson)

///| RespError represents errors during RESP parsing.
pub suberror RespError {
  ///| InvalidPrefix occurs when a message does not start with a recognized RESP character.
  InvalidPrefix(Int)
  ///| UnexpectedEndOfStream occurs when the reader closes before a message is complete.
  UnexpectedEndOfStream
  ///| MalformedNumber occurs when an integer or length field is not a valid number.
  MalformedNumber
} derive(Debug, ToJson)

///| RespParser handles decoding RESP messages from a stream.
pub struct RespParser[R] {
  reader : R
}

///| new creates a new RespParser from any object implementing @io.Reader.
pub fn[R : @io.Reader] RespParser::new(reader : R) -> RespParser[R] {
  { reader: reader }
}

async fn[R : @io.Reader] RespParser::read_byte(self : RespParser[R]) -> Int raise Error {
  let b = try {
    @io.Reader::read_exactly(self.reader, 1)
  } catch {
    _ => raise UnexpectedEndOfStream
  }
  b[0].to_int()
}

async fn[R : @io.Reader] RespParser::read_line(self : RespParser[R]) -> String raise Error {
  let mut line = ""
  for ;; {
    let b = self.read_byte()
    if b == 13 { // \r
      let next = self.read_byte()
      if next == 10 { // \n
        break line
      }
      line = line + "\r" + next.to_char().to_string()
    } else {
      line = line + b.to_char().to_string()
    }
  }
}

///| parse_value decodes a single RespValue from the reader.
pub async fn[R : @io.Reader] RespParser::parse_value(self : RespParser[R]) -> RespValue raise Error {
  let prefix = self.read_byte()
  match prefix {
    43 => { // '+' Simple String
      SimpleString(self.read_line())
    }
    45 => { // '-' Error
      Error(self.read_line())
    }
    58 => { // ':' Integer
      let line = self.read_line()
      try {
        Integer(@string.parse_int64(line))
      } catch {
        _ => raise MalformedNumber
      }
    }
    36 => { // '$' Bulk String
      let len_line = self.read_line()
      let len = @string.parse_int(len_line)
      if len == -1 {
        BulkString(None)
      } else {
        let buf = try {
          @io.Reader::read_exactly(self.reader, len)
        } catch {
          _ => raise UnexpectedEndOfStream
        }
        // Consume \r\n
        let _ = self.read_byte() // \r
        let _ = self.read_byte() // \n
        BulkString(Some(@utf8.decode(buf)))
      }
    }
    42 => { // '*' Array
      let len_line = self.read_line()
      let len = @string.parse_int(len_line)
      if len == -1 {
        Array(None)
      } else {
        let arr = Array::new(capacity=len)
        for i = 0; i < len; i = i + 1 {
          arr.push(self.parse_value())
        }
        Array(Some(arr))
      }
    }
    _ => raise InvalidPrefix(prefix)
  }
}
