# durable_workflow_sqlite

**[Korean README](README.ko.md)**

SQLite implementation of `CheckpointStore` for the [`durable_workflow`](../durable_workflow/) library.
Uses [sqlite3](https://pub.dev/packages/sqlite3) FFI for high-performance local persistence.

## Features

- **SQLite3 FFI** -- direct native access via `package:sqlite3`, no platform channels
- **WAL journal mode** -- concurrent reads and writes for optimal performance
- **Automatic schema migration** -- `PRAGMA user_version` based versioning
- **ACID transactions** -- all writes use `BEGIN IMMEDIATE` for consistency
- **File and in-memory modes** -- file-based for production, in-memory for testing

## Getting Started

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';

// File-based (production)
final store = SqliteCheckpointStore.file('workflows.db');
final engine = DurableEngineImpl(store: store);

final result = await engine.run<String>('my_workflow', (ctx) async {
  return await ctx.step('greet', () async => 'Hello!');
});

engine.dispose();
store.close();
```

```dart
// In-memory (testing)
final store = SqliteCheckpointStore.inMemory();
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  durable_workflow: ^0.1.0
  durable_workflow_sqlite: ^0.1.0
```

## SQLite Schema

5 tables with 5 indexes:

| Table | Purpose |
|-------|---------|
| `workflows` | Workflow type definitions (id, type, version) |
| `workflow_executions` | Execution instances (status, TTL, guarantee) |
| `step_checkpoints` | INTENT/COMPLETED/FAILED/COMPENSATED records per step |
| `workflow_timers` | Durable timer records (fire_at, PENDING/FIRED) |
| `workflow_signals` | External event records (PENDING/DELIVERED/EXPIRED) |

### PRAGMA Configuration

```sql
PRAGMA journal_mode = WAL;       -- Read/write concurrency
PRAGMA foreign_keys = ON;        -- Referential integrity
PRAGMA synchronous = NORMAL;     -- Write performance (safe with WAL)
PRAGMA busy_timeout = 5000;      -- 5s retry wait for concurrent access
```

## API

### SqliteCheckpointStore

| Constructor | Description |
|-------------|-------------|
| `SqliteCheckpointStore(Database db)` | Create from an already-opened database |
| `SqliteCheckpointStore.file(String path)` | Open a file-based database |
| `SqliteCheckpointStore.inMemory()` | Open an in-memory database |

| Method | Description |
|--------|-------------|
| `close()` | Close the underlying database connection |

All `CheckpointStore` interface methods are implemented:
- `saveCheckpoint` / `loadCheckpoints` -- step checkpoint persistence
- `saveExecution` / `loadExecution` / `loadExecutionsByStatus` -- execution state
- `saveTimer` / `loadPendingTimers` -- durable timer persistence
- `saveSignal` / `loadPendingSignals` -- signal persistence

### Schema Utilities

| Export | Description |
|--------|-------------|
| `schemaVersion` | Current schema version number |
| `migrate(Database db)` | Apply pending schema migrations |

## Tests

```
SQLite store tests: 59 ✅
```

Covers CRUD operations, PRAGMA verification, schema migration, foreign key constraints, and edge cases.

## License

See the repository root for license information.
