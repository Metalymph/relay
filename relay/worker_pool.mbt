///| WorkerPool manages a group of concurrent workers that process messages from the queue.
pub struct WorkerPool[T] {
  queue : RelayQueue[T]
  concurrency : Int
}

///| new creates a new worker pool with the specified concurrency.
pub fn[T] WorkerPool::new(queue : RelayQueue[T], concurrency~ : Int) -> WorkerPool[T] {
  { queue: queue, concurrency: concurrency }
}

///| run starts the pool. Each worker is launched as a background task within a TaskGroup.
/// This function suspends until all workers terminate (which usually happens when the
/// TaskGroup is cancelled or the queue is closed).
pub async fn[T] WorkerPool::run(
  self : WorkerPool[T], 
  handler : async (T) -> Unit raise Error
) -> Unit {
  @async.with_task_group(async fn(tg) {
    for i = 0; i < self.concurrency; i = i + 1 {
      tg.spawn_bg(async fn() {
        self.start_single_worker(handler)
      })
    }
  })
}

///| start_single_worker defines the lifecycle of a single worker in the pool.
async fn[T] WorkerPool::start_single_worker(
  self : WorkerPool[T],
  handler : async (T) -> Unit raise Error
) -> Unit {
  for ;; {
    // 1. Pop message (suspends if queue is empty)
    let msg = try {
      self.queue.pop()
    } catch {
      _ => break // Exit if queue fails or is closed
    }

    // 2. Process via the user-provided handler
    let result = try {
      handler(msg.payload)
      Ok(())
    } catch {
      e => Err(e)
    }

    // 3. Handle outcome: Ack on success, Nack on error
    match result {
      Ok(_) => {
        let _ = try { self.queue.ack(msg.id) } catch { _ => () }
      }
      Err(_) => {
        let _ = try { self.queue.nack(msg.id) } catch { _ => () }
      }
    }
  }
}
