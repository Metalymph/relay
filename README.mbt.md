# Cloud Kit: Relay & Valkey for MoonBit

A unified MoonBit workspace providing a **robust, distributed message queue (Relay)** and a **native asynchronous RESP client (Valkey/Redis)**.

This monorepo contains two distinct packages. They are entirely built on the `moonbitlang/async` runtime, enabling highly concurrent network operations without blocking the main event thread.

## Architecture

```text
moon-cloud-kit/
  ├─ valkey/        -> "username/valkey"    (Native RESP Client)
  └─ relay/         -> "username/relay"     (Message Queue & Backends)
```

1. **`username/valkey`**: A lightweight, robust Redis/Valkey client implementing the RESP protocol natively in MoonBit. Handles TCP connections (`@socket.Tcp`) and parses multiplexed streams.
2. **`username/relay`**: An abstracted, asynchronous message queue designed for distributed cloud systems. Provides a `RelayQueue[T]` interface over pluggable storage engines.

### Storage Engines (Relay)

- **`InMemoryBackend`**: High-performance, single-node asynchronous queue backed by `@aqueue.Queue`. Ideal for local actors or testing.
- **`RedisBackend`**: Distributed, multi-process queue using Redis commands for reliable dispatch.

---

## 📦 Getting Started

### Using as a Monorepo / Standalone

To compile and test the entire workspace natively:

```bash
# Verify the entire workspace
moon check --target native

# Run the complete test suite
moon test --target native
```

### Example Usage: Worker Pool & Reliability (V3)

Relay V3 introduces support for parallel processing via **WorkerPool** and automatic error handling (Ack/Nack/DLQ).

```moonbit
import "username/relay"

pub async fn start_processing() -> Unit raise Error {
  // 1. Initialize backend and queue
  let backend = relay.InMemoryBackend::new(100, policy=relay.RetryPolicy::default())
  let queue = backend.to_relay_queue()

  // 2. Create a concurrent WorkerPool (e.g., 4 workers in parallel)
  let pool = relay.WorkerPool::new(queue, concurrency=4)

  // 3. Start processing
  // The pool automatically handles Ack (success) and Nack (failure)
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

- [x] **Valkey Client**: TCP connection, raw RESP command sending, primitive parsing.
- [x] **Relay - Memory**: FIFO asynchronous queue with In-Flight tracking.
- [x] **Relay - Redis**: `RelayQueue` implementation mapped to Valkey commands.
- [x] **Relay - Worker Pool**: Concurrency management via TaskGroups with automatic Ack/Nack.
- [x] **Dashboard CLI**: Live ANSI interface to monitor queues and Dead Letter Queues.