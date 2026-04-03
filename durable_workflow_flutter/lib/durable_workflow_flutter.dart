/// Flutter platform adapters for durable_workflow.
///
/// Provides lifecycle-aware recovery, optional background scheduling,
/// and monitoring widgets for durable workflow executions.
library durable_workflow_flutter;

// Adapter
export 'src/adapter/background_adapter.dart';
export 'src/adapter/noop_background_adapter.dart';

// Lifecycle
export 'src/lifecycle/app_lifecycle_observer.dart';
export 'src/lifecycle/foreground_recovery.dart';

// Provider
export 'src/provider/durable_workflow_provider.dart';

// Widgets
export 'src/widget/execution_monitor.dart';
export 'src/widget/execution_list_tile.dart';
