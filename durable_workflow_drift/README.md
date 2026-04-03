# durable_workflow_drift

**[Korean README](README.ko.md)**

Drift ORM implementation of `CheckpointStore` for [durable_workflow](../durable_workflow/).

## Features

- **Type-safe queries** via Drift's query builder and code generation
- **Reactive streams** — `watchExecution()`, `watchExecutionsByStatus()`, `watchCheckpoints()` for real-time UI updates
- **Automatic schema migration** via Drift's built-in migration system
- **Same schema** as `durable_workflow_sqlite` — same 5 tables, same indexes, same PRAGMA configuration
- **Flutter-ready** — works with `sqlite3_flutter_libs` for mobile/desktop

## Usage

```dart
import 'package:drift/native.dart';
import 'package:durable_workflow_drift/durable_workflow_drift.dart';

// Open database
final db = DurableWorkflowDatabase(NativeDatabase.createInBackground('workflow.db'));
final store = DriftCheckpointStore(db);

// Use with DurableEngine
final engine = DurableEngineImpl(store: store);

// Drift-specific: reactive queries
store.watchExecution('exec-1').listen((execution) {
  print('Status: ${execution?.status}');
});
```

## Setup

```yaml
dependencies:
  durable_workflow_drift: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  drift_dev: ^2.22.0
```

Run code generation:
```bash
dart run build_runner build
```

## Architecture

```
DriftCheckpointStore
  └─ DurableWorkflowDatabase (Drift @DriftDatabase)
       ├─ Workflows table
       ├─ WorkflowExecutions table
       ├─ StepCheckpoints table
       ├─ WorkflowTimers table
       └─ WorkflowSignals table
```

## Tests

```
Drift store tests: 31 ✅
```

Covers schema verification, CRUD operations for all entities, reactive queries, full lifecycle integration, and edge cases.

## License

See the repository root for license information.
