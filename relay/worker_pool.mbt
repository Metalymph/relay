///| WorkerPool gestisce un gruppo di worker concorrenti che elaborano messaggi dalla coda.
pub struct WorkerPool[T] {
  queue : RelayQueue[T]
  concurrency : Int
}

///| new crea un nuovo pool di worker con la concorrenza specificata.
pub fn[T] WorkerPool::new(queue : RelayQueue[T], concurrency~ : Int) -> WorkerPool[T] {
  { queue: queue, concurrency: concurrency }
}

///| run avvia il pool. Ogni worker viene lanciato come un task in background in un TaskGroup.
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

///| start_single_worker definisce il ciclo di vita di un singolo worker nel pool.
async fn[T] WorkerPool::start_single_worker(
  self : WorkerPool[T],
  handler : async (T) -> Unit raise Error
) -> Unit {
  for ;; {
    let msg = try {
      self.queue.pop()
    } catch {
      _ => break
    }

    let result = try {
      handler(msg.payload)
      Ok(())
    } catch {
      e => Err(e)
    }

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
