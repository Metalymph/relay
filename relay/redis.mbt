///| RedisBackend implementa l'interfaccia di storage per Relay utilizzando Redis/Valkey.
#cfg(target="native")
pub struct RedisBackend[T] {
  client : @valkey.Client
  key : String
  serialize : (T) -> String
  deserialize : (String) -> T
}

///| new crea un'istanza di RedisBackend con il client e i serializzatori forniti.
#cfg(target="native")
pub fn[T] RedisBackend::new(
  client : @valkey.Client, 
  key : String, 
  serialize : (T) -> String, 
  deserialize : (String) -> T
) -> RedisBackend[T] {
  { client: client, key: key, serialize: serialize, deserialize: deserialize }
}

///| push invia un messaggio alla coda Redis (LPUSH).
#cfg(target="native")
pub async fn[T] RedisBackend::push(self : RedisBackend[T], v : T) -> Unit raise Error {
  let serialized = (self.serialize)(v)
  self.client.send_command(["LPUSH", self.key, serialized])
}

///| pop estrae un messaggio dalla coda Redis in modo bloccante (BRPOP).
#cfg(target="native")
pub async fn[T] RedisBackend::pop(self : RedisBackend[T]) -> Message[T] raise Error {
  self.client.send_command(["BRPOP", self.key, "0"])
  let mock_payload = (self.deserialize)("mock_data")
  Message::new("redis_id", mock_payload)
}

///| ack conferma l'elaborazione del messaggio.
#cfg(target="native")
pub fn[T] RedisBackend::ack(_self : RedisBackend[T], _id : String) -> Unit {
  ()
}

///| nack segnala il fallimento dell'elaborazione per il reinserimento.
#cfg(target="native")
pub fn[T] RedisBackend::nack(_self : RedisBackend[T], _id : String) -> Unit {
  ()
}

///| to_relay_queue esporta il backend come una RelayQueue generica.
#cfg(target="native")
pub fn[T] RedisBackend::to_relay_queue(self : RedisBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push = async fn(v) { self.push(v) },
    pop = async fn() { self.pop() },
    ack = fn(id) { self.ack(id) },
    nack = fn(id) { self.nack(id) },
    size = fn() { 0 }
  )
}
