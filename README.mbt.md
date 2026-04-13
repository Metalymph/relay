# Cloud Kit: Relay & Valkey for MoonBit

A unified MoonBit workspace providing a **robust, distributed message queue (Relay)** and a **native asynchronous RESP client (Valkey/Redis)**.

This monorepo contains due distinti package. Sono interamente basati sul runtime `moonbitlang/async`, che permette operazioni di rete altamente concorrenti senza bloccare il thread principale.

## Architecture

```text
moon-cloud-kit/
  ├─ valkey/        -> "username/valkey"    (Native RESP Client)
  └─ relay/         -> "username/relay"     (Message Queue & Backends)
```

1. **`username/valkey`**: Un client Redis/Valkey leggero e robusto che implementa nativamente il protocollo RESP in MoonBit. Gestisce connessioni TCP (`@socket.Tcp`) e parsing di stream moltiplicati.
2. **`username/relay`**: Una coda di messaggi asincrona astratta, progettata per sistemi distribuiti. Fornisce un'interfaccia `RelayQueue[T]` su motori di storage pluggabili.

### Storage Engines (Relay)

- **`InMemoryBackend`**: Coda asincrona single-node ad alte prestazioni basata su `@aqueue.Queue`. Ideale per attori locali o test.
- **`RedisBackend`**: Coda distribuita multi-processo che utilizza comandi Redis per il dispatch affidabile.

---

## 📦 Getting Started

### Utilizzo come Monorepo / Standalone

Per compilare e testare l'intero workspace nativamente:

```bash
# Verifica l'integrità del workspace
moon check --target native

# Esegui la suite di test completa
moon test --target native
```

### Esempio d'uso: Worker Pool & Affidabilità (V3)

Relay V3 introduce il supporto per l'elaborazione parallela tramite **WorkerPool** e la gestione automatica degli errori (Ack/Nack/DLQ).

```moonbit
import "username/relay"

pub async fn start_processing() -> Unit raise Error {
  // 1. Inizializza backend e coda
  let backend = relay.InMemoryBackend::new(100, policy=relay.RetryPolicy::default())
  let queue = backend.to_relay_queue()

  // 2. Crea un Pool di Worker concorrenti (es. 4 worker in parallelo)
  let pool = relay.WorkerPool::new(queue, concurrency=4)

  // 3. Avvia l'elaborazione
  // Il pool gestisce automaticamente Ack (successo) e Nack (errore)
  pool.run(async fn(payload) {
    println("Processing: \{payload}")
    if payload == "fail" {
       raise Error::new("Simulation failed")
    }
  })
}
```

---

## 🛠 Features Status

- [x] **Valkey Client**: Connessione TCP, invio comandi RESP, parsing dei primitivi.
- [x] **Relay - Memory**: Coda FIFO asincrona con supporto In-Flight tracking.
- [x] **Relay - Redis**: Implementazione `RelayQueue` mappata sui comandi Valkey.
- [x] **Relay - Worker Pool**: Gestione della concorrenza tramite TaskGroup e Ack/Nack automatici.
- [x] **Dashboard CLI**: Interfaccia ANSI live per monitorare code e Dead Letter Queue.