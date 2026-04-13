///| start_worker starts an infinite loop that pops messages from the queue and passes them to a handler.
pub async fn[T] start_worker(
  queue : RelayQueue[T],
  handler : (Message[T]) -> Unit
) -> Unit {
  for ;; {
    let msg = try {
      queue.pop()
    } catch {
      _ => break
    }
    handler(msg)
  }
}
