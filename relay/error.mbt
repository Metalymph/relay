///| QueueError represents errors related to queue lifecycle and operations.
pub suberror QueueError {
  BackendError(String)
} derive(Debug, ToJson)
