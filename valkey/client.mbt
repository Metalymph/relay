// Valkey native client

///|
/// Client is a native Valkey/Redis client supporting asynchronous operations.
#cfg(target="native")
pub struct Client {
  conn : @socket.Tcp
}

///|
/// ValkeyError represents the error types handled by the Valkey driver.
pub suberror ValkeyError {
  /// ConnectionError indicates a TCP communication failure.
  ConnectionError(String)
  /// ProtocolError indicates a RESP protocol parsing failure.
  ProtocolError(String)
} derive(Debug, ToJson)

///|
/// connect opens an asynchronous connection to the specified host and port.
#cfg(target="native")
pub async fn Client::connect(host : String, port : Int) -> Client raise Error {
  try {
    let addr = @socket.Addr::resolve(host, port~)
    let conn = @socket.Tcp::connect(addr)
    { conn, }
  } catch {
    e => raise ConnectionError(e.to_string())
  }
}

///|
/// send_command encodes and sends a RESP command to the server.
#cfg(target="native")
pub async fn Client::send_command(
  self : Client,
  args : Array[String],
) -> Unit raise Error {
  let data = encode_command(args)
  @io.Writer::write(self.conn, data) catch {
    e => raise ConnectionError("Write failed: \{e}")
  }
}

///|
/// read_response reads a RESP response from the server.
#cfg(target="native")
pub async fn Client::read_response(self : Client) -> RespValue raise Error {
  let parser = RespParser::new(self.conn)
  parser.parse_value() catch {
    err => raise ProtocolError("RESP parse failed: \{err}")
  }
}

///|
/// request sends a command and returns the response.
#cfg(target="native")
pub async fn Client::request(
  self : Client,
  args : Array[String],
) -> RespValue raise Error {
  self.send_command(args)
  self.read_response()
}

///|
/// ping sends a PING command to the server and expects a PONG response.
#cfg(target="native")
pub async fn Client::ping(self : Client) -> Unit raise Error {
  match self.request(["PING"]) {
    SimpleString("PONG") => ()
    _ => raise ProtocolError("Expected PONG")
  }
}

///|
/// get returns a string value by key, or None when the key does not exist.
#cfg(target="native")
pub async fn Client::get(
  self : Client,
  key : String,
) -> String? raise Error {
  match self.request(["GET", key]) {
    BulkString(Some(value)) => Some(value)
    BulkString(None) => None
    _ => raise ProtocolError("Unexpected GET response")
  }
}

///|
/// set stores a string value by key.
#cfg(target="native")
pub async fn Client::set(
  self : Client,
  key : String,
  value : String,
) -> Unit raise Error {
  match self.request(["SET", key, value]) {
    SimpleString("OK") => ()
    _ => raise ProtocolError("Expected OK")
  }
}

///|
/// del removes a key and returns the number of deleted keys.
#cfg(target="native")
pub async fn Client::del(
  self : Client,
  key : String,
) -> Int64 raise Error {
  match self.request(["DEL", key]) {
    Integer(n) => n
    _ => raise ProtocolError("Expected integer DEL response")
  }
}

///|
/// exists returns true when the key exists.
#cfg(target="native")
pub async fn Client::exists(
  self : Client,
  key : String,
) -> Bool raise Error {
  match self.request(["EXISTS", key]) {
    Integer(0L) => false
    Integer(_) => true
    _ => raise ProtocolError("Expected integer EXISTS response")
  }
}

///|
/// xadd appends a payload field to a stream and returns the generated entry id.
#cfg(target="native")
pub async fn Client::xadd(
  self : Client,
  stream : String,
  payload : String,
) -> String raise Error {
  match self.request(["XADD", stream, "*", "payload", payload]) {
    BulkString(Some(id)) => id
    _ => raise ProtocolError("Unexpected XADD response")
  }
}

///|
/// xgroup_create creates a consumer group for a stream, creating the stream if needed.
#cfg(target="native")
pub async fn Client::xgroup_create(
  self : Client,
  stream : String,
  group : String,
) -> Unit raise Error {
  match self.request(["XGROUP", "CREATE", stream, group, "0", "MKSTREAM"]) {
    SimpleString("OK") => ()
    Error(err) => raise ProtocolError("XGROUP CREATE failed: \{err}")
    _ => raise ProtocolError("Unexpected XGROUP CREATE response")
  }
}

///|
/// xreadgroup reads one payload entry from a stream consumer group.
#cfg(target="native")
pub async fn Client::xreadgroup(
  self : Client,
  stream : String,
  group : String,
  consumer : String,
  count : Int,
) -> (String, String)? raise Error {
  match self.request([
    "XREADGROUP",
    "GROUP",
    group,
    consumer,
    "COUNT",
    count.to_string(),
    "STREAMS",
    stream,
    ">",
  ]) {
    Array(None) => None
    Array(Some(streams)) => parse_xreadgroup_one(streams)
    _ => raise ProtocolError("Unexpected XREADGROUP response")
  }
}

///|
/// xautoclaim claims one pending stream entry and returns its `(id, payload)`.
#cfg(target="native")
pub async fn Client::xautoclaim(
  self : Client,
  stream : String,
  group : String,
  consumer : String,
  min_idle_ms : Int,
) -> (String, String)? raise Error {
  match self.request([
    "XAUTOCLAIM",
    stream,
    group,
    consumer,
    min_idle_ms.to_string(),
    "0-0",
    "COUNT",
    "1",
  ]) {
    Array(Some(items)) => parse_xautoclaim_one(items)
    _ => raise ProtocolError("Unexpected XAUTOCLAIM response")
  }
}

///|
/// xack acknowledges a stream entry and returns the number of acknowledged ids.
#cfg(target="native")
pub async fn Client::xack(
  self : Client,
  stream : String,
  group : String,
  id : String,
) -> Int64 raise Error {
  match self.request(["XACK", stream, group, id]) {
    Integer(n) => n
    _ => raise ProtocolError("Unexpected XACK response")
  }
}

///|
/// parse_xreadgroup_one extracts the first `(id, payload)` pair from XREADGROUP.
#cfg(target="native")
fn parse_xreadgroup_one(
  streams : Array[RespValue],
) -> (String, String)? raise Error {
  if streams.length() == 0 {
    return None
  }

  match streams[0] {
    Array(Some(stream_entry)) => {
      if stream_entry.length() != 2 {
        raise ProtocolError("Unexpected stream entry shape")
      }

      match stream_entry[1] {
        Array(Some(messages)) => {
          parse_stream_messages_one(messages)
        }
        _ => raise ProtocolError("Unexpected stream messages")
      }
    }
    _ => raise ProtocolError("Unexpected stream wrapper")
  }
}

///|
/// parse_xautoclaim_one extracts the first `(id, payload)` pair from XAUTOCLAIM.
#cfg(target="native")
fn parse_xautoclaim_one(
  items : Array[RespValue],
) -> (String, String)? raise Error {
  if items.length() < 2 {
    raise ProtocolError("Unexpected XAUTOCLAIM response shape")
  }

  match items[1] {
    Array(Some(messages)) => parse_stream_messages_one(messages)
    _ => raise ProtocolError("Unexpected XAUTOCLAIM messages")
  }
}

///|
/// parse_stream_messages_one extracts the first stream message from a messages array.
#cfg(target="native")
fn parse_stream_messages_one(
  messages : Array[RespValue],
) -> (String, String)? raise Error {
  if messages.length() == 0 {
    return None
  }

  match messages[0] {
    Array(Some(message)) => {
      if message.length() != 2 {
        raise ProtocolError("Unexpected message shape")
      }

      let id = match message[0] {
        BulkString(Some(value)) => value
        _ => raise ProtocolError("Unexpected stream id")
      }

      let payload = match message[1] {
        Array(Some(fields)) => parse_stream_payload(fields)
        _ => raise ProtocolError("Unexpected stream fields")
      }

      Some((id, payload))
    }
    _ => raise ProtocolError("Unexpected message value")
  }
}

///|
/// parse_stream_payload extracts the `payload` field from stream entry fields.
#cfg(target="native")
fn parse_stream_payload(fields : Array[RespValue]) -> String raise Error {
  for i = 0; i + 1 < fields.length(); i = i + 2 {
    match fields[i] {
      BulkString(Some("payload")) =>
        match fields[i + 1] {
          BulkString(Some(value)) => return value
          _ => raise ProtocolError("Unexpected payload field value")
        }
      _ => ()
    }
  }

  raise ProtocolError("Missing payload field")
}

///|
/// encode_command encodes command arguments as a RESP array of bulk strings.
fn encode_command(args : Array[String]) -> Bytes {
  let mut cmd = "*" + args.length().to_string() + "\r\n"
  for arg in args {
    let bytes = @utf8.encode(arg)
    cmd = cmd + "$" + bytes.length().to_string() + "\r\n" + arg + "\r\n"
  }
  @utf8.encode(cmd)
}

///|
#cfg(target="native")
fn _dummy_use_native() -> Unit {
  let _ = @socket.IpProtocolPreference::OnlyV4
  let _ : @async.RetryMethod? = None
  ()
}

///|
#cfg(not(target="native"))
fn _dummy_use_non_native() -> Unit {
  let _ : @async.RetryMethod? = None
  ()
}