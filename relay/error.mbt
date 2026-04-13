///| QueueError represents errors related to queue lifecycle and operations.
pub suberror QueueError {
  OperationFailed(String)
} derive(Debug, ToJson)
