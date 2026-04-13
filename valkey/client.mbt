// Valkey native client

///| Client è un client nativo per Valkey/Redis che supporta operazioni asincrone.
#cfg(target="native")
pub struct Client {
  conn : @socket.Tcp
}

///| ValkeyError rappresenta le tipologie di errore gestite dal driver Valkey.
pub suberror ValkeyError {
  ///| ConnectionError indica un fallimento nella comunicazione TCP.
  ConnectionError(String)
} derive(Debug, ToJson)

///| connect apre una connessione asincrona verso l'host e la porta specificati.
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

///| send_command codifica e invia un comando RESP (Redis Serialization Protocol) al server.
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
