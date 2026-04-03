import 'package:durable_workflow/durable_workflow.dart';
import 'package:flutter/material.dart';

/// Displays a workflow execution as a Material [ListTile].
///
/// Shows the execution's workflow ID, status, and timestamps.
/// Optionally provides cancel and retry action buttons.
///
/// ```dart
/// ExecutionListTile(
///   execution: myExecution,
///   onCancel: () => engine.cancel(myExecution.workflowExecutionId),
/// )
/// ```
class ExecutionListTile extends StatelessWidget {
  /// The workflow execution to display.
  final WorkflowExecution execution;

  /// Called when the cancel button is tapped.
  /// If null, no cancel button is shown.
  final VoidCallback? onCancel;

  /// Called when the retry button is tapped.
  /// If null, no retry button is shown.
  final VoidCallback? onRetry;

  /// Creates an [ExecutionListTile].
  const ExecutionListTile({
    super.key,
    required this.execution,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _StatusIcon(status: execution.status),
      title: Text(execution.workflowId),
      subtitle: Text(
        '${_statusLabel(execution.status)} · ${execution.updatedAt}',
      ),
      trailing: _buildActions(),
    );
  }

  Widget? _buildActions() {
    final actions = <Widget>[];

    if (onCancel != null && _isCancellable(execution.status)) {
      actions.add(IconButton(
        icon: const Icon(Icons.cancel_outlined),
        tooltip: 'Cancel',
        onPressed: onCancel,
      ));
    }

    if (onRetry != null && execution.status is Failed) {
      actions.add(IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Retry',
        onPressed: onRetry,
      ));
    }

    if (actions.isEmpty) return null;
    if (actions.length == 1) return actions.first;
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  static bool _isCancellable(ExecutionStatus status) {
    return status is Running || status is Suspended || status is Pending;
  }

  static String _statusLabel(ExecutionStatus status) => switch (status) {
        Pending() => 'Pending',
        Running() => 'Running',
        Suspended() => 'Suspended',
        Completed() => 'Completed',
        Failed() => 'Failed',
        Compensating() => 'Compensating',
        Cancelled() => 'Cancelled',
      };
}

class _StatusIcon extends StatelessWidget {
  final ExecutionStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      Pending() => (Icons.hourglass_empty, Colors.grey),
      Running() => (Icons.play_circle_outline, Colors.blue),
      Suspended() => (Icons.pause_circle_outline, Colors.orange),
      Completed() => (Icons.check_circle_outline, Colors.green),
      Failed() => (Icons.error_outline, Colors.red),
      Compensating() => (Icons.undo, Colors.amber),
      Cancelled() => (Icons.cancel_outlined, Colors.grey),
    };

    return Icon(icon, color: color);
  }
}
