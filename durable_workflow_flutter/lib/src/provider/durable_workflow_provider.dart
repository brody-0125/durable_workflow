import 'dart:async';

import 'package:durable_workflow/durable_workflow.dart';
import 'package:flutter/widgets.dart';

import '../adapter/background_adapter.dart';
import '../adapter/noop_background_adapter.dart';
import '../lifecycle/app_lifecycle_observer.dart';
import '../lifecycle/foreground_recovery.dart';

/// Provides a [DurableEngine] to the widget tree and manages its lifecycle.
///
/// Wraps engine creation, lifecycle observation, foreground recovery,
/// and optional background adapter initialization into a single widget.
///
/// Place this near the root of your widget tree:
///
/// ```dart
/// DurableWorkflowProvider(
///   store: SqliteCheckpointStore(path: 'workflows.db'),
///   workflowRegistry: {
///     'order_processing': orderProcessingWorkflow,
///   },
///   child: MyApp(),
/// )
/// ```
///
/// Access the engine from descendant widgets:
///
/// ```dart
/// final engine = DurableWorkflowProvider.of(context);
/// await engine.run('order_processing', orderProcessingWorkflow);
/// ```
class DurableWorkflowProvider extends StatefulWidget {
  /// The checkpoint store for workflow persistence.
  final CheckpointStore store;

  /// Maps workflow type names to their body functions.
  ///
  /// Used by [RecoveryScanner] to resume interrupted workflows.
  /// Every workflow type that should survive app restarts must be
  /// registered here.
  final Map<String, Future<dynamic> Function(WorkflowContext)> workflowRegistry;

  /// Optional platform-specific background adapter.
  ///
  /// If not provided, only foreground recovery is active.
  final BackgroundAdapter? backgroundAdapter;

  /// Minimum interval between recovery scans.
  ///
  /// Prevents redundant scans during rapid lifecycle transitions.
  /// Defaults to 5 seconds.
  final Duration recoveryDebounce;

  /// Called when the app resumes to the foreground.
  final VoidCallback? onResumed;

  /// Called when the app enters the background.
  final VoidCallback? onPaused;

  /// The widget below this provider in the tree.
  final Widget child;

  /// Creates a [DurableWorkflowProvider].
  const DurableWorkflowProvider({
    super.key,
    required this.store,
    required this.workflowRegistry,
    this.backgroundAdapter,
    this.recoveryDebounce = const Duration(seconds: 5),
    this.onResumed,
    this.onPaused,
    required this.child,
  });

  static _DurableWorkflowProviderState _stateOf(
    BuildContext context,
    String methodName,
  ) {
    final state =
        context.findAncestorStateOfType<_DurableWorkflowProviderState>();
    if (state == null) {
      throw FlutterError(
        'DurableWorkflowProvider.$methodName() called with a context that '
        'does not contain a DurableWorkflowProvider.\n'
        'Ensure a DurableWorkflowProvider is an ancestor of this widget.',
      );
    }
    return state;
  }

  /// Returns the [DurableEngine] from the nearest ancestor
  /// [DurableWorkflowProvider].
  ///
  /// Throws if no provider is found in the widget tree.
  static DurableEngine of(BuildContext context) =>
      _stateOf(context, 'of')._engine;

  /// Returns the recovery scan result stream from the nearest ancestor provider.
  ///
  /// Emits a [RecoveryScanResult] after each recovery scan completes.
  /// ```dart
  /// DurableWorkflowProvider.recoveryResults(context).listen(
  ///   (result) => print('${result.resumed.length} workflows resumed'),
  /// );
  /// ```
  static Stream<RecoveryScanResult> recoveryResults(BuildContext context) =>
      _stateOf(context, 'recoveryResults')._recovery.results;

  @override
  State<DurableWorkflowProvider> createState() =>
      _DurableWorkflowProviderState();
}

class _DurableWorkflowProviderState extends State<DurableWorkflowProvider> {
  late final DurableEngineImpl _engine;
  late final ForegroundRecovery _recovery;
  late final AppLifecycleObserver _lifecycleObserver;
  late final BackgroundAdapter _backgroundAdapter;

  @override
  void initState() {
    super.initState();

    _engine = DurableEngineImpl(store: widget.store);
    _backgroundAdapter = widget.backgroundAdapter ?? NoopBackgroundAdapter();

    _recovery = ForegroundRecovery(
      engine: _engine,
      registry: widget.workflowRegistry,
      debounce: widget.recoveryDebounce,
    );

    _lifecycleObserver = AppLifecycleObserver(
      recovery: _recovery,
      backgroundAdapter: _backgroundAdapter,
      onResumed: widget.onResumed,
      onPaused: widget.onPaused,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    _lifecycleObserver.register();
    try {
      await Future.wait([
        _backgroundAdapter.initialize(),
        _recovery.initialScan(),
      ]);
    } catch (e) {
      debugPrint('DurableWorkflowProvider initialization error: $e');
    }
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    _recovery.dispose();
    _backgroundAdapter.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
