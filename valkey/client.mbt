// Valkey native client

#cfg(target = "native")
pub struct Client {
  conn : @socket.Tcp
}

pub suberror ValkeyError {
  ConnectionError(String)
} derive(Debug, ToJson)

#cfg(target = "native")
pub async fn Client::connect(host : String, port : Int) -> Client raise Error {
  try {
    let addr = @socket.Addr::resolve(host, port~)
    let conn = @socket.Tcp::connect(addr)
    { conn: conn }
  } catch {
    e => raise ConnectionError(e.to_string())
  }
}

#cfg(target = "native")
pub async fn Client::send_command(self : Client, args : Array[String]) -> Unit raise Error {
  let mut cmd = "*" + args.length().to_string() + "\r\n"
  for arg in args {
    cmd = cmd + "$" + arg.length().to_string() + "\r\n" + arg + "\r\n"
  }
  let data = @utf8.encode(cmd)
  try {
    @io.Writer::write(self.conn, data)
  } catch {
    e => raise ConnectionError("Failed to send command: \{e}")
  }
}
