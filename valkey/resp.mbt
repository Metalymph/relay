///| RespValue rappresenta i diversi tipi nel protocollo RESP (Redis Serialization Protocol).
pub enum RespValue {
  SimpleString(String)
  Error(String)
  Integer(Int64)
  BulkString(Option[String])
  Array(Option[Array[RespValue]])
} derive(Debug, ToJson)

///| RespError rappresenta gli errori durante il parsing RESP.
pub suberror RespError {
  ///| InvalidPrefix viene sollevato se un messaggio non inizia con un carattere RESP riconosciuto.
  InvalidPrefix(Int)
  ///| UnexpectedEndOfStream viene sollevato se il reader si chiude prematuramente.
  UnexpectedEndOfStream
  ///| MalformedNumber viene sollevato se un campo numerico non è valido.
  MalformedNumber
} derive(Debug, ToJson)

///| RespParser gestisce la decodifica dei messaggi RESP da uno stream.
pub struct RespParser[R] {
  reader : R
}

///| new crea un nuovo RespParser da un oggetto che implementa @io.Reader.
pub fn[R] RespParser::new(reader : R) -> RespParser[R] {
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
  let bytes : Array[Byte] = Array::new()
  for ;; {
    let b = self.read_byte()
    if b == 13 { // \r
      let next = self.read_byte()
      if next == 10 { // \n
        break
      }
      bytes.push((13).to_byte())
      bytes.push(next.to_byte())
    } else {
      bytes.push(b.to_byte())
    }
  }
  @utf8.decode(Bytes::from_array(bytes))
}

///| parse_value decodifica un singolo RespValue dal reader.
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
      let len = try { @string.parse_int(len_line) } catch { _ => raise MalformedNumber }
      if len == -1 {
        BulkString(None)
      } else {
        let buf = try {
          @io.Reader::read_exactly(self.reader, len)
        } catch {
          _ => raise UnexpectedEndOfStream
        }
        // Consumiamo \r\n finale
        let _ = self.read_byte() // \r
        let _ = self.read_byte() // \n
        BulkString(Some(@utf8.decode(buf)))
      }
    }
    42 => { // '*' Array
      let len_line = self.read_line()
      let len = try { @string.parse_int(len_line) } catch { _ => raise MalformedNumber }
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
