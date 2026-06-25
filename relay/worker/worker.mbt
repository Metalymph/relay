///|
/// start_worker starts an infinite loop that pops messages from the queue and passes them to a handler.
pub async fn[T] start_worker(
  queue : @core.RelayQueue[T],
  handler : (@core.Message[T]) -> Unit,
) -> Unit {
  for ;; {
    let msg = queue.pop() catch { _ => break }
    handler(msg)
  }
}
