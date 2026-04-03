import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now().toUtc().toIso8601String();

  WorkflowExecution makeExecution({
    ExecutionStatus status = const Running(),
    String workflowId = 'wf-order-0',
  }) {
    return WorkflowExecution(
      workflowExecutionId: 'exec-1',
      workflowId: workflowId,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget wrapInApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ExecutionListTile', () {
    testWidgets('shows workflow ID', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(execution: makeExecution()),
      ));

      expect(find.text('wf-order-0'), findsOneWidget);
    });

    testWidgets('shows status label for Running', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(
          execution: makeExecution(status: const Running()),
        ),
      ));

      expect(find.textContaining('Running'), findsOneWidget);
    });

    testWidgets('shows status label for Completed', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(
          execution: makeExecution(status: const Completed()),
        ),
      ));

      expect(find.textContaining('Completed'), findsOneWidget);
    });

    testWidgets('shows status label for Failed', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(
          execution: makeExecution(status: const Failed()),
        ),
      ));

      expect(find.textContaining('Failed'), findsOneWidget);
    });

    testWidgets('shows cancel button for Running execution', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(
          execution: makeExecution(status: const Running()),
          onCancel: () => cancelCalled = true,
        ),
      ));

      final cancelButton = find.byIcon(Icons.cancel_outlined);
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      expect(cancelCalled, isTrue);
    });

    testWidgets('hides cancel button for Completed execution', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(
          execution: makeExecution(status: const Completed()),
          onCancel: () {},
        ),
      ));

      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    });

    testWidgets('shows retry button for Failed execution', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(
          execution: makeExecution(status: const Failed()),
          onRetry: () => retryCalled = true,
        ),
      ));

      final retryButton = find.byIcon(Icons.refresh);
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      expect(retryCalled, isTrue);
    });

    testWidgets('hides retry button for Running execution', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ExecutionListTile(
          execution: makeExecution(status: const Running()),
          onRetry: () {},
        ),
      ));

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('shows correct icon for each status', (tester) async {
      final statusIcons = <ExecutionStatus, IconData>{
        const Pending(): Icons.hourglass_empty,
        const Running(): Icons.play_circle_outline,
        const Suspended(): Icons.pause_circle_outline,
        const Completed(): Icons.check_circle_outline,
        const Failed(): Icons.error_outline,
        const Compensating(): Icons.undo,
        const Cancelled(): Icons.cancel_outlined,
      };

      for (final entry in statusIcons.entries) {
        await tester.pumpWidget(wrapInApp(
          ExecutionListTile(
            execution: makeExecution(status: entry.key),
          ),
        ));

        expect(
          find.byIcon(entry.value),
          findsOneWidget,
          reason: 'Expected icon for ${entry.key}',
        );
      }
    });
  });
}
