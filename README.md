# durable_workflow

[![Dart](https://img.shields.io/badge/Dart-%5E3.6-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests: 356](https://img.shields.io/badge/Tests-356%20passed-brightgreen)](#test-results)

**[Korean README (한국어)](README.ko.md)**

> Crash-proof durable workflow execution for Dart — powered by local SQLite, zero infrastructure required.

---

## Why durable_workflow?

Modern apps run multi-step processes — payments, file uploads, device provisioning, data pipelines. When these crash halfway through, you're left with inconsistent state and no easy way to recover.

**durable_workflow** solves this by persisting every workflow step to a local database. If a crash or restart happens, the workflow automatically resumes from the last completed step. No cloud services, no message queues, no external dependencies.

**Key benefits:**

- **Zero infrastructure** — runs entirely on-device with local SQLite
- **Crash recovery** — workflows resume exactly where they left off
- **Compensation (Saga)** — automatic rollback of completed steps on failure
- **Pure Dart** — works on server, desktop, CLI, and Flutter

---

## Packages

| Package | Description |
|---------|-------------|
| [`durable_workflow`](durable_workflow/) | Pure Dart core engine (zero dependencies) |
| [`durable_workflow_sqlite`](durable_workflow_sqlite/) | SQLite persistence via sqlite3 FFI |
| [`durable_workflow_drift`](durable_workflow_drift/) | Drift ORM persistence (reactive queries) |
| [`durable_workflow_examples`](durable_workflow_examples/) | Real-world use-case catalog (7 categories) |
| [`durable_workflow_flutter`](durable_workflow_flutter/) | Flutter platform adapters (WorkManager / BGTask) |

---

## Installation

Add the packages to your `pubspec.yaml`:

```yaml
dependencies:
  durable_workflow: ^0.2.0
  durable_workflow_sqlite: ^0.2.1   # for SQLite persistence
  # or
  durable_workflow_drift: ^0.2.0    # for Drift ORM persistence
```

> **System requirement:** `libsqlite3-dev` must be installed for SQLite FFI bindings.
>
> ```bash
> # Ubuntu / Debian
> sudo apt-get install libsqlite3-dev
>
> # macOS (included with system)
> # No additional installation needed
> ```

---

## Quick Start

### In-memory (testing / prototyping)

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

final engine = DurableEngineImpl(store: InMemoryCheckpointStore());

final result = await engine.run<String>('greet', (ctx) async {
  final name = await ctx.step('fetch', () async => 'World');
  return 'Hello, $name!';
});

print(result); // Hello, World!
engine.dispose();
```

### With SQLite persistence (production)

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';

final store = SqliteCheckpointStore.file('workflows.db');
final engine = DurableEngineImpl(store: store);

final result = await engine.run<String>('order', (ctx) async {
  // Step 1: Validate — persisted on completion
  final validated = await ctx.step('validate', () => validateOrder(input));

  // Step 2: Charge payment — with compensation for rollback
  final payment = await ctx.step('pay',
    () => chargePayment(validated.amount),
    compensate: () => refundPayment(payment.txId),
    retry: RetryPolicy.exponential(maxAttempts: 3),
  );

  // Step 3: Wait 24 hours — survives process restarts
  await ctx.sleep('wait_shipping', Duration(hours: 24));

  // Step 4: Wait for external event
  final confirmed = await ctx.waitSignal<bool>('delivery_confirmed');

  return 'Order ${confirmed ? "delivered" : "pending"}';
});

engine.dispose();
store.close();
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Checkpoint / Resume** | Each step is persisted; on crash recovery, execution resumes from the last checkpoint |
| **Retry Policies** | Exponential backoff with jitter, configurable per step |
| **Saga Compensation** | Reverse-order rollback of completed steps on failure |
| **Durable Timer** | `ctx.sleep()` persists to DB and survives process restarts |
| **Durable Signal** | `ctx.waitSignal()` + `engine.sendSignal()` for external event coordination |
| **Recovery Scanner** | Automatically detects and resumes interrupted workflows on restart |
| **Pluggable Persistence** | `CheckpointStore` interface — choose between InMemory, SQLite, or Drift |
| **Zero Dependencies** | Core package has no external dependencies |

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                        User Code                         │
│   engine.run('order', (ctx) async {                      │
│     await ctx.step('pay', () => charge(...));             │
│     await ctx.sleep('wait', Duration(hours: 24));        │
│     await ctx.waitSignal('confirmed');                   │
│   });                                                    │
└────────────────────────┬─────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────┐
│                   DurableEngineImpl                       │
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐  │
│  │ StepExecutor │ │ TimerManager │ │  SignalManager    │  │
│  │ checkpoint/  │ │ dart:async + │ │  Completer<T> +   │  │
│  │ resume loop  │ │ DB persist   │ │  DB persist       │  │
│  └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘  │
│         │                │                   │            │
│  ┌──────▼───────┐ ┌──────▼───────────────────▼─────────┐ │
│  │RetryExecutor │ │         RecoveryScanner             │ │
│  │ backoff +    │ │ scan RUNNING/SUSPENDED workflows    │ │
│  │ jitter       │ │ restore timers/signals → resume     │ │
│  └──────┬───────┘ └───────────────────────────────────┘  │
│         │                                                │
│  ┌──────▼───────┐                                        │
│  │    Saga      │                                        │
│  │ Compensator  │ reverse compensation on failure        │
│  └──────────────┘                                        │
└────────────────────────┬─────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────┐
│              CheckpointStore (abstract)                   │
│                                                          │
│  InMemory (testing) │ SQLite (prod) │ Drift (reactive)   │
└──────────────────────────────────────────────────────────┘
```

---

## Use Cases

The [`durable_workflow_examples`](durable_workflow_examples/) package includes real-world examples across 7 categories:

| Category | Examples |
|----------|----------|
| **E-Commerce** | Multi-step checkout with refund compensation |
| **File Sync & Upload** | Chunked uploads with resume capability |
| **IoT & Device** | Multi-step device provisioning workflows |
| **Finance & Banking** | KYC verification, P2P transfers, regulatory workflows |
| **Desktop App** | Long-running installers, DB migrations, batch processing |
| **Messaging & Chat** | Guaranteed message delivery, offline queues |
| **Healthcare** | Patient registration, prescription workflows |

---

## Test Results

```
durable_workflow:          258 tests ✅  (unit + integration)
durable_workflow_sqlite:    67 tests ✅
durable_workflow_drift:     31 tests ✅
durable_workflow_flutter:   39 tests ✅
──────────────────────────────────────
Total:                     395 tests ✅
```

CI runs on **Ubuntu latest** with Dart **stable** and **beta** SDKs. Minimum coverage threshold: **80%**.

---

## Project Structure

```
durable_workflow/
├── durable_workflow/              Pure Dart core (zero dependencies)
│   ├── lib/src/
│   │   ├── model/                 Domain models (immutable, JSON serializable)
│   │   ├── context/               WorkflowContext interface + implementation
│   │   ├── engine/                Execution engine (7 components)
│   │   └── persistence/           CheckpointStore interface + InMemory impl
│   ├── test/                      258 tests (unit + integration)
│   └── example/                   Runnable examples
├── durable_workflow_sqlite/       SQLite persistence implementation
│   ├── lib/src/                   SqliteCheckpointStore + schema + migrations
│   └── test/                      67 tests
├── durable_workflow_drift/        Drift ORM persistence implementation
│   ├── lib/src/                   DriftCheckpointStore + tables + reactive queries
│   └── test/                      31 tests
├── durable_workflow_flutter/      Flutter platform adapters
│   ├── lib/src/                   Lifecycle adapters, providers, and widgets
│   └── test/                      39 tests
├── durable_workflow_examples/     Real-world use-case catalog
│   └── lib/src/                   7 categories of workflow examples
└── docs/                          Design documents
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Core Package](durable_workflow/README.md) | API reference and getting started |
| [SQLite Package](durable_workflow_sqlite/README.md) | SQLite persistence setup |
| [Drift Package](durable_workflow_drift/README.md) | Drift ORM persistence setup |
| [Flutter Package](durable_workflow_flutter/README.md) | Flutter lifecycle adapters and widgets |
| [Examples](durable_workflow_examples/README.md) | Real-world use-case catalog |

---

## Contributing

```bash
# Clone the repository
git clone https://github.com/brody-0125/durable_workflow.git
cd durable_workflow

# Install system dependencies (Linux)
sudo apt-get install libsqlite3-dev

# Run tests for a specific package
cd durable_workflow
dart pub get
dart analyze --fatal-warnings
dart test
```

---

## License

MIT — see [LICENSE](LICENSE) for details.
