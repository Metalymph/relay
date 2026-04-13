// In MoonBit, tests that use async need to block on an event loop or be executed inside one.
// Since we are using `@async/aqueue`, we write tests wrapped in normal sync functions
// using standard testing practices (if MoonBit test runner supports async tests directly, we will use `async` on the test).

test "in_memory_queue_basic" {
  // To avoid blocking the test runner without async/await context,
  // we do a simple sync check or if test supports async, we do an async test.
  let backend : InMemoryBackend[Int] = InMemoryBackend::new(10)
  assert_eq(backend.size(), 0)
}
