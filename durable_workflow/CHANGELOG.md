## 0.1.0

- Initial release.
- Core durable workflow engine with checkpoint/resume semantics.
- Saga compensation pattern for automatic rollback.
- Durable timers that survive process restarts.
- External signal coordination via `waitSignal`.
- Configurable retry policies (fixed interval, exponential backoff).
- Pluggable `CheckpointStore` persistence interface.
- `InMemoryCheckpointStore` for testing.
- `RecoveryScanner` for automatic detection and resumption of interrupted workflows.
