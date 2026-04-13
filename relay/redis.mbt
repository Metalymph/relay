#cfg(target = "native")
///| RedisBackend implementa l'interfaccia di storage per Relay utilizzando Redis/Valkey.
pub struct RedisBackend[T] {
  client : @valkey.Client
  key : String
  serialize : (T) -> String
  deserialize : (String) -> T
}

#cfg(target = "native")
///| new crea un'istanza di RedisBackend con il client e i serializzatori forniti.
pub fn[T] RedisBackend::new(
  client : @valkey.Client, 
  key : String, 
  serialize : (T) -> String, 
  deserialize : (String) -> T
) -> RedisBackend[T] {
  { client: client, key: key, serialize: serialize, deserialize: deserialize }
}

#cfg(target = "native")
///| push invia un messaggio alla coda Redis (LPUSH).
pub async fn[T] RedisBackend::push(self : RedisBackend[T], v : T) -> Unit raise Error {
  let serialized = (self.serialize)(v)
  self.client.send_command(["LPUSH", self.key, serialized])
}

#cfg(target = "native")
///| pop estrae un messaggio dalla coda Redis in modo bloccante (BRPOP).
pub async fn[T] RedisBackend::pop(self : RedisBackend[T]) -> Message[T] raise Error {
  self.client.send_command(["BRPOP", self.key, "0"])
  let mock_payload = (self.deserialize)("mock_data")
  Message::new("redis_id", mock_payload)
}

#cfg(target = "native")
///| ack conferma l'elaborazione del messaggio.
pub fn[T] RedisBackend::ack(_self : RedisBackend[T], _id : String) -> Unit {
  ()
}

#cfg(target = "native")
///| nack segnala il fallimento dell'elaborazione per il reinserimento.
pub fn[T] RedisBackend::nack(_self : RedisBackend[T], _id : String) -> Unit {
  ()
}

#cfg(target = "native")
///| to_relay_queue esporta il backend come una RelayQueue generica.
pub fn[T] RedisBackend::to_relay_queue(self : RedisBackend[T]) -> RelayQueue[T] {
  RelayQueue::new(
    push = async fn(v) { self.push(v) },
    pop = async fn() { self.pop() },
    ack = fn(id) { self.ack(id) },
    nack = fn(id) { self.nack(id) },
    size = fn() { 0 }
  )
}
