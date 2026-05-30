// Valkey native client

///|
/// Client is a native Valkey/Redis client supporting asynchronous operations.
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