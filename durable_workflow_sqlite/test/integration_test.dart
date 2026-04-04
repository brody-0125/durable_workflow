@Tags(['integration'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late SqliteCheckpointStore store;

  setUp(() {
    store = SqliteCheckpointStore.inMemory();
  });

  tearDown(() {
    store.close();
  });

  group('integration', () {
    test('full workflow lifecycle', () async {
      // 1. Workflow definition
      await store.saveWorkflow(testWorkflow(
        id: 'wf-order',
        type: 'order_processing',
      ));

      // 2. Start execution
      await store.saveExecution(testExecution(
        id: 'exec-order-1',
        workflowId: 'wf-order',
        status: const Running(),
        inputData: '{"orderId":"O-123","amount":99.99}',
      ));

      // 3. Step 0 INTENT
      await store.saveCheckpoint(testCheckpoint(
        executionId: 'exec-order-1',
        stepIndex: 0,
        stepName: 'validate',
        inputData: '{"orderId":"O-123"}',
        startedAt: kCreatedAt,
      ));

      // 4. Step 0 COMPLETED
      await store.saveCheckpoint(testCheckpoint(
        executionId: 'exec-order-1',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.completed,
        outputData: '{"valid":true}',
        startedAt: kCreatedAt,
        completedAt: kLaterAt,
      ));

      // 5. Step 1 INTENT
      await store.saveCheckpoint(testCheckpoint(
        executionId: 'exec-order-1',
        stepIndex: 1,
        stepName: 'pay',
        compensateRef: 'refund_payment',
        startedAt: kLaterAt,
      ));

      // 6. Durable timer
      await store.saveTimer(testTimer(
        id: 'timer-shipping',
        executionId: 'exec-order-1',
      ));

      // 7. Signal
      await store.saveSignal(testSignal(
        executionId: 'exec-order-1',
        payload: '{"confirmed":true}',
      ));

      // 8. Verify all data
      final exec =
          await store.loadExecution('exec-order-1');
      expect(exec, isNotNull);
      expect(exec!.status, isA<Running>());

      final checkpoints =
          await store.loadCheckpoints('exec-order-1');
      expect(checkpoints, hasLength(2));
      expect(
        checkpoints[0].stepName,
        equals('validate'),
      );
      expect(
        checkpoints[0].status,
        equals(StepStatus.completed),
      );
      expect(checkpoints[1].stepName, equals('pay'));
      expect(
        checkpoints[1].status,
        equals(StepStatus.intent),
      );
      final timers = await store.loadPendingTimers();
      expect(timers, hasLength(1));

      final signals = await store.loadPendingSignals(
        'exec-order-1',
      );
      expect(signals, hasLength(1));

      // 9. Complete execution
      await store.saveExecution(exec.copyWith(
        status: const Completed(),
        outputData: '{"success":true}',
        updatedAt: kLaterAt,
      ));

      final completed =
          await store.loadExecution('exec-order-1');
      expect(completed, isNotNull);
      expect(completed!.status, isA<Completed>());
      expect(
        completed.outputData,
        equals('{"success":true}'),
      );
    });

    test('INTENT -> COMPLETED atomic update', () async {
      await store.saveWorkflow(testWorkflow());
      await store.saveExecution(testExecution(
        status: const Running(),
      ));

      // Save INTENT
      await store.saveCheckpoint(testCheckpoint(
        startedAt: kCreatedAt,
      ));
      var loaded = await store.loadCheckpoints('exec-1');
      expect(
        loaded[0].status,
        equals(StepStatus.intent),
      );

      // Update to COMPLETED
      await store.saveCheckpoint(testCheckpoint(
        status: StepStatus.completed,
        outputData: '{"done":true}',
        startedAt: kCreatedAt,
        completedAt: kLaterAt,
      ));

      loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(1));
      expect(
        loaded[0].status,
        equals(StepStatus.completed),
      );
      expect(
        loaded[0].outputData,
        equals('{"done":true}'),
      );
    });

    test('recovery scenario: find interrupted executions',
        () async {
      await store.saveWorkflow(testWorkflow());

      await store.saveExecution(testExecution(
        id: 'exec-running',
        status: const Running(),
      ));
      await store.saveExecution(testExecution(
        id: 'exec-suspended',
        status: const Suspended(),
        createdAt: kLaterAt,
        updatedAt: kLaterAt,
      ));
      await store.saveExecution(testExecution(
        id: 'exec-done',
        status: const Completed(),
      ));
      await store.saveExecution(testExecution(
        id: 'exec-failed',
        status: const Failed(),
      ));

      final recoverable =
          await store.loadExecutionsByStatus([
        const Running(),
        const Suspended(),
      ]);
      expect(recoverable, hasLength(2));

      final ids = recoverable
          .map((e) => e.workflowExecutionId)
          .toList();
      expect(ids, contains('exec-running'));
      expect(ids, contains('exec-suspended'));
    });

    test('cross-entity consistency', () async {
      await store.saveWorkflow(testWorkflow());
      await store.saveExecution(testExecution(
        status: const Running(),
      ));

      await store.saveCheckpoint(testCheckpoint());
      await store.saveTimer(testTimer());
      await store.saveSignal(testSignal());

      final checkpoints =
          await store.loadCheckpoints('exec-1');
      final timers = await store.loadPendingTimers();
      final signals =
          await store.loadPendingSignals('exec-1');

      expect(checkpoints, hasLength(1));
      expect(timers, hasLength(1));
      expect(signals, hasLength(1));

      // All reference the same execution
      expect(
        checkpoints[0].workflowExecutionId,
        equals('exec-1'),
      );
      expect(
        timers[0].workflowExecutionId,
        equals('exec-1'),
      );
      expect(
        signals[0].workflowExecutionId,
        equals('exec-1'),
      );
    });

    test('batch saveCheckpoints', () async {
      await store.saveWorkflow(testWorkflow());
      await store.saveExecution(testExecution(
        status: const Running(),
      ));

      final checkpoints = List.generate(
        20,
        (i) => testCheckpoint(
          stepIndex: i,
          stepName: 'step_$i',
          status: StepStatus.completed,
        ),
      );

      await store.saveCheckpoints(checkpoints);

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(20));
      expect(loaded.first.stepIndex, equals(0));
      expect(loaded.last.stepIndex, equals(19));
    });

    test('batch saveCheckpoints with empty list', () async {
      await store.saveCheckpoints([]);
      // Should not throw
    });

    test('large step count', () async {
      await store.saveWorkflow(testWorkflow());
      await store.saveExecution(testExecution(
        status: const Running(),
      ));

      for (var i = 0; i < 50; i++) {
        await store.saveCheckpoint(testCheckpoint(
          stepIndex: i,
          stepName: 'step_$i',
          status: StepStatus.completed,
        ));
      }

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(50));
      expect(loaded.first.stepIndex, equals(0));
      expect(loaded.last.stepIndex, equals(49));
    });
  });
}
