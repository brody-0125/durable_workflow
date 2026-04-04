# durable_workflow

**[Korean README](README.ko.md)**

Durable Workflows for Dart. Provides checkpoint/resume
workflow execution with zero external dependencies.

## Features

- **Checkpoint/Resume** -- each workflow step is persisted before execution;
  on crash, the engine replays completed steps from cache and continues from
  the last checkpoint.
- **Retry** -- per-step retry with fixed-interval or exponential-backoff
  policies.
- **Saga compensation** -- register a `compensate` callback per step;
  on failure the engine runs compensations in reverse order.
- **Durable signals** -- `ctx.waitSignal()` suspends the workflow until an
  external event arrives via `engine.sendSignal()`.
- **Durable timers** -- `ctx.sleep()` persists a timer record so the delay
  survives process restarts.
- **Pluggable persistence** -- implement `CheckpointStore` to use SQLite,
  Drift, Hive, or any other backend. Ships with `InMemoryCheckpointStore`
  (test only — import from `package:durable_workflow/testing.dart`) and
  `SqliteCheckpointStore` (in `durable_workflow_sqlite`) for production.

## Getting Started

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart'; // InMemoryCheckpointStore (test only)

Future<void> main() async {
  final engine = DurableEngineImpl(store: InMemoryCheckpointStore());

  final result = await engine.run<String>('greet', (ctx) async {
    final name = await ctx.step<String>('fetch_name', () async => 'World');
    return 'Hello, $name!';
  });

  print(result); // Hello, World!
  engine.dispose();
}
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  durable_workflow: ^0.1.0
```

For SQLite persistence, also add:

```yaml
dependencies:
  durable_workflow_sqlite: ^0.1.0
```

## API Overview

### DurableEngine

The top-level orchestrator:

| Method | Description |
|--------|-------------|
| `run<T>(type, body, {input, ttl, guarantee})` | Execute a workflow |
| `sendSignal(execId, name, payload)` | Deliver a signal to a waiting workflow |
| `cancel(execId)` | Cancel a running workflow |
| `observe(execId)` | Stream of execution state changes |

### WorkflowContext

Provided to the workflow body:

| Method | Description |
|--------|-------------|
| `step<T>(name, action, {compensate, retry, idempotencyKey, serialize, deserialize})` | Execute a durable step |
| `sleep(name, duration)` | Suspend for a duration (durable timer) |
| `waitSignal<T>(name, {timeout})` | Wait for an external signal |

### CheckpointStore

Persistence interface -- implement for your backend:

| Method | Description |
|--------|-------------|
| `saveCheckpoint` / `loadCheckpoints` | Step checkpoint CRUD |
| `saveExecution` / `loadExecution` | Execution state CRUD |
| `saveTimer` / `loadPendingTimers` | Durable timer persistence |
| `saveSignal` / `loadPendingSignals` | Signal persistence |

### RecoveryScanner

Call on engine startup to resume interrupted workflows:

```dart
final scanner = RecoveryScanner(store: store, engine: engine);
final result = await scanner.scan(workflowRegistry: {
  'order_processing': orderWorkflowBody,
});
print('Resumed: ${result.resumed.length}, Expired: ${result.expired.length}');
```

## Domain Models

### Execution Status State Machine

```
PENDING → RUNNING → COMPLETED
                  → SUSPENDED → RUNNING (timer/signal)
                  → FAILED → COMPENSATING → FAILED (final)
                  → CANCELLED
```

### Sealed Classes

| Type | Variants |
|------|----------|
| `ExecutionStatus` | Pending, Running, Suspended, Completed, Failed, Compensating, Cancelled |
| `RetryPolicy` | RetryPolicyNone, RetryPolicyFixed, RetryPolicyExponential |

### Enums

| Type | Values |
|------|--------|
| `WorkflowGuarantee` | foregroundOnly, bestEffortBackground |
| `StepStatus` | intent, completed, failed, compensated |
| `TimerStatus` | pending, fired, cancelled |
| `SignalStatus` | pending, delivered, expired |

## Architecture

```
durable_workflow/
  lib/src/
    model/          # Value objects: ExecutionStatus, RetryPolicy, StepCheckpoint, etc.
    context/        # WorkflowContext interface + implementation
    engine/         # DurableEngine, StepExecutor, RetryExecutor, SagaCompensator,
                    #   TimerManager, SignalManager, RecoveryScanner
    persistence/    # CheckpointStore interface + InMemoryCheckpointStore (test only)
  lib/
    testing.dart    # Test-only barrel exporting InMemoryCheckpointStore
```

### Engine Components

| Component | Responsibility |
|-----------|---------------|
| `DurableEngineImpl` | Top-level orchestrator — run, cancel, observe, signal |
| `StepExecutor` | Checkpoint/resume loop for individual steps |
| `RetryExecutor` | Exponential backoff with jitter calculation |
| `SagaCompensator` | Reverse-order compensation execution |
| `TimerManager` | Durable timer persistence + dart:async polling |
| `SignalManager` | Completer-based signal delivery + DB persistence |
| `RecoveryScanner` | Scan RUNNING/SUSPENDED executions on startup |

## Example

See [`example/order_processing.dart`](example/order_processing.dart) for a
complete runnable example.

## Tests

```
Model + interface tests:  100
Engine unit tests:         94
Persistence tests:         18
Integration tests:         22
Total:                    234
```

## Security Considerations

Checkpoint data (step inputs, outputs, error messages) is stored as plaintext
in the underlying database. Keep the following in mind for production use:

- **Do not store secrets** (API keys, passwords, tokens) as step results.
  Use references or IDs instead.
- **Use custom serializers** to encrypt sensitive fields before persistence:
  ```dart
  await ctx.step('process_payment',
    () async => processPayment(cardNumber),
    serialize: (result) => encrypt(jsonEncode(result)),
    deserialize: (data) => PaymentResult.fromJson(jsonDecode(decrypt(data))),
  );
  ```
- **Place database files** in the app's private data directory
  (e.g., `getApplicationDocumentsDirectory()` on Flutter).
- **Use the `errorFormatter` parameter** on `DurableEngineImpl` to strip
  stack traces and redact sensitive data from persisted error messages.
- For full database encryption, consider using
  [sqlcipher_flutter_libs](https://pub.dev/packages/sqlcipher_flutter_libs)
  with the SQLite backend.

## License

See the repository root for license information.
