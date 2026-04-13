#cfg(target = "native")
///| Client è un client nativo Valkey/Redis.
pub struct Client {
  conn : @socket.Tcp
}

///| ValkeyError rappresenta errori che possono verificarsi durante le operazioni Valkey.
pub suberror ValkeyError {
  ///| ConnectionError si verifica quando una connessione TCP fallisce o viene interrotta.
  ConnectionError(String)
} derive(Debug, ToJson)

///| connect stabilisce una nuova connessione TCP verso un server Valkey/Redis.
#cfg(target = "native")
pub async fn Client::connect(host : String, port : Int) -> Client raise Error {
  let addr = @socket.Addr::resolve(host, port~)
  let conn = @socket.Tcp::connect(addr)
  { conn: conn }
}

///| send_command invia un comando RESP grezzo al server.
#cfg(target = "native")
pub async fn Client::send_command(self : Client, args : Array[String]) -> Unit raise Error {
  let mut cmd = "*" + args.length().to_string() + "\r\n"
  for arg in args {
    cmd = cmd + "$" + arg.length().to_string() + "\r\n" + arg + "\r\n"
  }
  let data = @utf8.encode(cmd)
  @io.Writer::write(self.conn, data)
}
