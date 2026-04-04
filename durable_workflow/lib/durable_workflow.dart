/// Local durable execution library for Dart.
///
/// Provides durable checkpoint/resume workflows
/// with zero external dependencies.
library durable_workflow;

// Models
export 'src/model/execution_status.dart';
export 'src/model/retry_policy.dart';
export 'src/model/step_checkpoint.dart';
export 'src/model/workflow.dart';
export 'src/model/workflow_execution.dart';
export 'src/model/workflow_guarantee.dart';
export 'src/model/workflow_signal.dart';
export 'src/model/workflow_timer.dart';

// Interfaces
export 'src/context/workflow_context.dart';
export 'src/engine/durable_engine.dart';
export 'src/persistence/checkpoint_store.dart';

// Public implementations
export 'src/engine/engine_observer.dart';
export 'src/engine/durable_engine_impl.dart';
export 'src/engine/recovery_scanner.dart';
export 'src/engine/types.dart';

// Internal implementations are available via:
//   import 'package:durable_workflow/internals.dart';
// InMemoryCheckpointStore is available via:
//   import 'package:durable_workflow/testing.dart';
