# Cloud Kit: Relay & Valkey for MoonBit

A unified MoonBit workspace providing a **robust, distributed message queue (Relay)** and a **native asynchronous RESP client (Valkey/Redis)**.

This monorepo contains two distinct and independently publishable packages. They are entirely built on the first-class `moonbitlang/async` runtime, enabling highly concurrent network operations without blocking the main event thread.

## Architecture

```text
moon-cloud-kit/
  ├─ valkey/        -> "metalymph/valkey"    (Native RESP Client)
  └─ relay/         -> "metalymph/relay"     (Message Queue & Backends)
```

1. **`metalymph/valkey`**: A lightweight, robust Redis/Valkey client implementing the RESP protocol natively in MoonBit. It handles TCP connections (`@socket.Tcp`) and parses multiplexed streams.
2. **`metalymph/relay`**: An abstracted, asynchronous message queue designed for distributed cloud systems. Provides a `RelayQueue[T]` wrapper over pluggable storage engines.

### Storage Engines (Relay)

- **`InMemoryBackend`**: High-performance, single-node asynchronous queue backed by `@aqueue.Queue`. Perfect for local actors, background jobs within the same service, or testing.
- **`RedisBackend`** (Powered by `valkey`): Cloud-ready, multi-process distributed queue using Redis `LPUSH` and `BRPOP` commands for reliable dispatch.

---

## 📦 Getting Started

### Using as a Monorepo/Standalone

To run and test the complete workspace natively:

```bash
# Verify the entire workspace
moon check --target native

# Run the test suites
moon test --target native
```

### Importing into your MoonBit Server/CLI

If you are building a MoonBit application and want to use **Relay** as your message queue:

1. Add the dependency to your project's `moon.mod.json`:

```json
{
  "deps": {
    "metalymph/relay": "0.1.0"
  }
}
```

1. Import the packages in your `moon.pkg`:

```json
{
  "import": [
    "metalymph/relay"
  ]
}
```

1. Initialize and use the queue in your code:

```moonbit
import "metalymph/relay"

pub async fn start_background_jobs() -> Unit!Error {
  // 1. Initialize an in-memory queue with a capacity of 100
  let memory_backend = relay.InMemoryBackend::new(100)
  let queue = memory_backend.to_relay_queue()

  // 2. Start a background worker 
  // The worker will suspend asynchronously when the queue is empty
  let _ = relay.start_worker(queue, fn(msg) {
    println("Processing job: " + msg.id)
  })

  // 3. Push jobs into the queue asynchronously
  queue.push!("job_data_1")
  queue.push!("job_data_2")
}
```

*(For Redis, you would initialize `relay.RedisBackend::new(host, port)` instead).*

---

## 🛠 Features Status

- [x] **Valkey Client**: TCP connection scaffold, raw RESP command sending, RESP primitive parsing (`String`, `Integer`, `Array`, `BulkString`, `Error`).
- [x] **Relay - Memory**: Complete, passing tests. FIFO asynchronous actor suspension bounded queues.
- [x] **Relay - Redis**: (Integration in progress). Decoupled `RelayQueue` implementation mapping directly to Valkey stream calls.
- [x] **Relay - Worker**: Acknowledgement and retry tracking logic (V3).