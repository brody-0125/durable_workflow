## 0.2.0

### Breaking Changes

- **Removed `idempotencyKey`** from `WorkflowContext.step()`, `StepCheckpoint`,
  and `StepExecutor.executeStep()`. The field was stored but never used for
  deduplication. DB column preserved as null for schema compatibility.
- **`CheckpointStore` now requires 3 new methods**: `saveCheckpoints()`,
  `deleteOldTimers()`, `deleteOldSignals()`. All implementations must be updated.
- **Exception types changed**: `StateError` for missing executions is now
  `WorkflowExecutionNotFoundException`. Signal timeout throws
  `WorkflowTimeoutException` instead of `TimeoutException`.

### Migration Guide

```dart
// Before (0.1.x)
try {
  await engine.cancel('nonexistent');
} on StateError catch (e) { ... }

// After (0.2.0)
try {
  await engine.cancel('nonexistent');
} on WorkflowExecutionNotFoundException catch (e) { ... }
```

```dart
// Before (0.1.x)
await ctx.step('pay', () async => result, idempotencyKey: 'key');

// After (0.2.0) — idempotencyKey parameter removed
await ctx.step('pay', () async => result);
```

### New Features

- **`DurableEngine.dispose()`** declared in the abstract interface — no more
  casting to `DurableEngineImpl` to release resources.
- **Custom exception hierarchy**: `DurableWorkflowException` base class with
  `WorkflowTimeoutException`, `WorkflowExecutionNotFoundException`,
  `CompensationException` subtypes.
- **`DurableEngineObserver`**: lifecycle monitoring hooks for step execution,
  retry, compensation, recovery, and error events.
- **Input validation**: `workflowType`, `stepName`, `signalName` are validated
  at API boundaries (empty, control chars, length > 256).
- **Error formatter**: optional `errorFormatter` parameter on `DurableEngineImpl`
  to sanitize error messages before persistence.
- **CheckpointStore cleanup**: `deleteOldTimers()` and `deleteOldSignals()`
  for pruning terminal-state records, `saveCheckpoints()` for batch inserts.

### Improvements

- Recovery scanner reentrance guard prevents concurrent `scan()` calls.
- Signal timeout race condition protection with double-guard on completer state.
- Engine dispose cancels active executors and safely closes observer streams.
- Duplicate execution ID prevention in `_executeBody`.

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
