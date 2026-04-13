// Valkey native client

///| Client is a native Valkey/Redis client supporting asynchronous operations.
#cfg(target="native")
pub struct Client {
  conn : @socket.Tcp
}

///| ValkeyError represents the error types handled by the Valkey driver.
pub suberror ValkeyError {
  ///| ConnectionError indicates a TCP communication failure.
  ConnectionError(String)
} derive(Debug, ToJson)

///| connect opens an asynchronous connection to the specified host and port.
#cfg(target="native")
pub async fn Client::connect(host : String, port : Int) -> Client raise Error {
  try {
    let addr = @socket.Addr::resolve(host, port~)
    let conn = @socket.Tcp::connect(addr)
    { conn: conn }
  } catch {
    e => raise ConnectionError(e.to_string())
  }
}

///| send_command encodes and sends a RESP (Redis Serialization Protocol) command to the server.
#cfg(target="native")
pub async fn Client::send_command(self : Client, args : Array[String]) -> Unit raise Error {
  let mut cmd = "*" + args.length().to_string() + "\r\n"
  for arg in args {
    cmd = cmd + "$" + arg.length().to_string() + "\r\n" + arg + "\r\n"
  }
  let data = @utf8.encode(cmd)
  try {
    @io.Writer::write(self.conn, data)
  } catch {
    e => raise ConnectionError("Write failed: \{e}")
  }
}
