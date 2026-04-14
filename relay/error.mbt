///|
/// QueueError represents errors related to queue lifecycle and operations.
pub suberror QueueError {
  OperationFailed(String)
} derive(Debug, ToJson)

///|
fn _dummy_use() -> Unit {
  let _ = QueueError::OperationFailed("dummy")
  let _ : @async.RetryMethod? = None
  let _ : @aqueue.Queue[Unit]? = None
  let _ : @valkey.RespValue? = None
  let _ : @hashmap.HashMap[Int, Int]? = None
  ()
}
