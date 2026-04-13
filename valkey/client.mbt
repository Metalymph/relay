///| ValkeyError represents errors that can occur during Valkey operations.
pub suberror ValkeyError {
  ///| ConnectionError occurs when a TCP connection fails or is dropped.
  ConnectionError(String)
} derive(Debug, ToJson)

///| Client is a native Valkey/Redis client.
pub struct Client {
  conn : @socket.Tcp
}

///| connect establishes a new TCP connection to a Valkey/Redis server.
pub async fn Client::connect(host : String, port : Int) -> Client raise ValkeyError {
  try {
    let addr = @socket.Addr::resolve(host, port~)
    let conn = @socket.Tcp::connect(addr)
    { conn: conn }
  } catch {
    _ => raise ConnectionError("Failed to connect to \{host}:\{port}")
  }
}

///| send_command sends a raw RESP command to the server.
/// Example: `client.send_command(["LPUSH", "myqueue", "data"])`
pub async fn Client::send_command(self : Client, args : Array[String]) -> Unit raise ValkeyError {
  let mut cmd = "*" + args.length().to_string() + "\r\n"
  for arg in args {
    cmd = cmd + "$" + arg.length().to_string() + "\r\n" + arg + "\r\n"
  }
  let data = @utf8.encode(cmd)
  try { 
    self.conn.write(data) 
  } catch {
    _ => raise ConnectionError("Failed to send command buffer")
  }
}
