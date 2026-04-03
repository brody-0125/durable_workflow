# durable_workflow_flutter

Flutter platform adapters for [durable_workflow](../durable_workflow/). Provides lifecycle-aware recovery, optional background scheduling, and monitoring widgets for durable workflow executions.

---

## Features

| Feature | Description |
|---------|-------------|
| **Foreground Recovery** | Auto-resumes interrupted workflows when the app returns to foreground |
| **Background Adapter** | Abstract interface for WorkManager (Android) / BGTask (iOS) integration |
| **DurableWorkflowProvider** | Single widget for engine initialization + lifecycle binding |
| **ExecutionMonitor** | Real-time workflow state widget via `StreamBuilder` |
| **ExecutionListTile** | Material ListTile with status icon, cancel/retry actions |

## Quick Start

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';

void main() {
  runApp(
    DurableWorkflowProvider(
      store: SqliteCheckpointStore(path: 'workflows.db'),
      workflowRegistry: {
        'order_processing': orderWorkflow,
      },
      child: const MyApp(),
    ),
  );
}

// Access engine from any descendant widget
final engine = DurableWorkflowProvider.of(context);
await engine.run('order_processing', orderWorkflow);
```

## Architecture

```
DurableWorkflowProvider
├── DurableEngineImpl          (core engine)
├── AppLifecycleObserver       (WidgetsBindingObserver)
│   ├── resumed → ForegroundRecovery.scan()
│   ├── paused  → BackgroundAdapter.scheduleRecovery()
│   └── detached→ dispose()
├── ForegroundRecovery         (debounced RecoveryScanner)
└── BackgroundAdapter          (optional, platform-specific)
    ├── WorkManagerAdapter     (Android - user implements)
    └── BgTaskAdapter          (iOS - user implements)
```

## Components

### DurableWorkflowProvider

InheritedWidget that initializes the engine, registers lifecycle observers, and runs an initial recovery scan.

```dart
DurableWorkflowProvider(
  store: myStore,
  workflowRegistry: {'order': orderWorkflow},
  backgroundAdapter: MyWorkManagerAdapter(),  // optional
  recoveryDebounce: Duration(seconds: 5),
  onResumed: () => print('Resumed'),
  onPaused: () => print('Paused'),
  child: MyApp(),
)
```

### BackgroundAdapter

Abstract interface for platform-specific background execution. Implement this to integrate with WorkManager or BGTaskScheduler:

```dart
class MyWorkManagerAdapter implements BackgroundAdapter {
  @override
  Future<void> initialize() async { /* register callback dispatcher */ }

  @override
  Future<void> scheduleRecovery() async { /* schedule periodic task */ }

  @override
  Future<void> cancelAll() async { /* cancel all tasks */ }

  @override
  Future<void> dispose() async {}
}
```

### ExecutionMonitor

Real-time widget that subscribes to `engine.observe()`:

```dart
ExecutionMonitor(
  workflowExecutionId: myId,
  builder: (context, execution) => Text(execution.status.toString()),
  loading: CircularProgressIndicator(),
)
```

### ExecutionListTile

Material ListTile with status icons and action buttons:

```dart
ExecutionListTile(
  execution: myExecution,
  onCancel: () => engine.cancel(myExecution.workflowExecutionId),
  onRetry: () => engine.run('order', orderWorkflow),
)
```

## Guarantee Model

| Level | Behavior |
|-------|----------|
| **Foreground Durability** | Workflow completes while app is active. Crash recovery on restart. |
| **Best-Effort Background** | WorkManager/BGTask schedules recovery attempts. **Not guaranteed.** |
| **At-Least-Once** | Idempotency keys prevent duplicate side effects. |

> Background execution is best-effort only — iOS ML Scheduler and Android OEM battery optimization can prevent background tasks from running.

## Dependencies

```yaml
dependencies:
  flutter: sdk
  durable_workflow: path ../durable_workflow
```

Platform plugins (workmanager, etc.) are **not** direct dependencies. Users implement `BackgroundAdapter` and add platform plugins to their own project.

## Testing

```bash
cd durable_workflow_flutter
flutter test
```
