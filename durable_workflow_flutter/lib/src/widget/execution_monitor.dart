import 'package:durable_workflow/durable_workflow.dart';
import 'package:flutter/widgets.dart';

import '../provider/durable_workflow_provider.dart';

/// Displays the real-time state of a single workflow execution.
///
/// Subscribes to [DurableEngine.observe] and rebuilds whenever the
/// execution state changes. Use the [builder] callback to render
/// custom UI for each state.
///
/// ```dart
/// ExecutionMonitor(
///   workflowExecutionId: myExecutionId,
///   builder: (context, execution) => Text(execution.status.toString()),
///   loading: CircularProgressIndicator(),
/// )
/// ```
class ExecutionMonitor extends StatefulWidget {
  /// The ID of the workflow execution to monitor.
  final String workflowExecutionId;

  /// Builds the widget for each execution state update.
  final Widget Function(BuildContext context, WorkflowExecution execution)
      builder;

  /// Widget shown while the initial execution state is loading.
  final Widget? loading;

  /// Builder for error states (e.g., execution not found).
  final Widget Function(BuildContext context, Object error)? error;

  /// Creates an [ExecutionMonitor].
  const ExecutionMonitor({
    super.key,
    required this.workflowExecutionId,
    required this.builder,
    this.loading,
    this.error,
  });

  @override
  State<ExecutionMonitor> createState() => _ExecutionMonitorState();
}

class _ExecutionMonitorState extends State<ExecutionMonitor> {
  late Stream<WorkflowExecution> _stream;

  @override
  void initState() {
    super.initState();
    _stream = DurableWorkflowProvider.of(context)
        .observe(widget.workflowExecutionId);
  }

  @override
  void didUpdateWidget(ExecutionMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workflowExecutionId != widget.workflowExecutionId) {
      _stream = DurableWorkflowProvider.of(context)
          .observe(widget.workflowExecutionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WorkflowExecution>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.error?.call(context, snapshot.error!) ??
              const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return widget.loading ?? const SizedBox.shrink();
        }

        return widget.builder(context, snapshot.data!);
      },
    );
  }
}
