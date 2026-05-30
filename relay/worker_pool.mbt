///|
/// WorkerStats tracks basic worker processing counters.
pub struct WorkerStats {
  mut processed : Int
  mut succeeded : Int
  mut failed : Int
  mut retries : Int
  mut dlq_routed : Int
  mut ack_failed : Int
  mut nack_failed : Int
}

///|
/// new creates empty worker stats.
pub fn WorkerStats::new() -> WorkerStats {
  {
    processed: 0,
    succeeded: 0,
    failed: 0,
    retries: 0,
    dlq_routed: 0,
    ack_failed: 0,
    nack_failed: 0,
  }
}

///|
/// WorkerPool manages a group of concurrent workers that process messages from the queue.
pub struct WorkerPool[T] {
  queue : RelayQueue[T]
  concurrency : Int
  stats : WorkerStats
}

///|
/// new creates a new worker pool with the specified concurrency.
pub fn[T] WorkerPool::new(
  queue : RelayQueue[T],
  concurrency~ : Int,
) -> WorkerPool[T] {
  { queue, concurrency, stats: WorkerStats::new() }
}

///|
/// stats returns the current worker processing counters.
pub fn[T] WorkerPool::stats(self : WorkerPool[T]) -> WorkerStats {
  self.stats
}

///|
/// run starts the pool. Each worker is launched as a background task within a TaskGroup.
pub async fn[T] WorkerPool::run(
  self : WorkerPool[T],
  handler : async (T) -> Unit raise Error,
) -> Unit {
  @async.with_task_group(tg => {
    for i = 0; i < self.concurrency; i = i + 1 {
      tg.spawn_bg(async fn() { self.start_single_worker(handler) })
    }
  })
}

///|
async fn[T] WorkerPool::start_single_worker(
  self : WorkerPool[T],
  handler : async (T) -> Unit raise Error,
) -> Unit {
  for ;; {
    let msg = self.queue.pop() catch { _ => break }

    self.stats.processed += 1

    let result = try {
      handler(msg.payload)
      Ok(())
    } catch {
      e => Err(e)
    }

    match result {
      Ok(_) => {
        self.stats.succeeded += 1
        self.queue.ack(msg.id) catch {
          _ => self.stats.ack_failed += 1
        }
      }
      Err(_) => {
        self.stats.failed += 1

        let result = self.queue.nack(msg.id) catch {
          _ => {
            self.stats.nack_failed += 1
            continue
          }
        }

        match result {
          Requeued => self.stats.retries += 1
          SentToDlq => self.stats.dlq_routed += 1
        }
      }
    }
  }
}
