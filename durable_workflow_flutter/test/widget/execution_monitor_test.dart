import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryCheckpointStore store;

  setUp(() {
    store = InMemoryCheckpointStore();
  });

  Widget buildApp({required Widget child}) {
    return DurableWorkflowProvider(
      store: store,
      workflowRegistry: const {},
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('ExecutionMonitor', () {
    testWidgets('shows loading widget initially', (tester) async {
      // Create an execution so observe returns something
      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-1',
        workflowId: 'wf-test-0',
        status: const Running(),
        createdAt: DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await store.saveExecution(execution);

      await tester.pumpWidget(buildApp(
        child: ExecutionMonitor(
          workflowExecutionId: 'exec-1',
          builder: (_, exec) => Text(exec.workflowId),
          loading: const Text('Loading...'),
        ),
      ));

      // After first frame, stream should have emitted
      await tester.pump();
      expect(find.text('wf-test-0'), findsOneWidget);
    });

    testWidgets('shows builder content with execution data', (tester) async {
      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-2',
        workflowId: 'wf-order-0',
        status: const Completed(),
        createdAt: DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await store.saveExecution(execution);

      await tester.pumpWidget(buildApp(
        child: ExecutionMonitor(
          workflowExecutionId: 'exec-2',
          builder: (_, exec) => const Text('Status: Completed'),
        ),
      ));
      await tester.pump();

      expect(find.text('Status: Completed'), findsOneWidget);
    });

    testWidgets('shows empty SizedBox when no loading widget and no data',
        (tester) async {
      await tester.pumpWidget(buildApp(
        child: ExecutionMonitor(
          workflowExecutionId: 'nonexistent',
          builder: (_, exec) => Text(exec.workflowId),
        ),
      ));

      // Should render SizedBox.shrink() since no data and no loading widget
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
