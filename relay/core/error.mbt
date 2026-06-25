///|
/// QueueError represents errors related to queue lifecycle and operations.
pub(all) suberror QueueError {
  OperationFailed(String)
} derive(Debug, ToJson)
