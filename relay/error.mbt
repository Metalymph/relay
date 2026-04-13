///| QueueError represents errors related to queue lifecycle and operations.
pub suberror QueueError {
  Closed
  Timeout
  BackendError(String)
} derive(Debug, ToJson)
