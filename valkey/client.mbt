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
/// send_command encodes and sends a RESP (Redis Serialization Protocol) command to the server.
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
/// encode_command encodes command arguments as RESP array of bulk strings.
fn encode_command(args : Array[String]) -> Bytes {
  let mut cmd = "*" + args.length().to_string() + "\r\n"
  for arg in args {
    cmd = cmd + "$" + @utf8.encode(arg).length().to_string() + "\r\n" + arg + "\r\n"
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
