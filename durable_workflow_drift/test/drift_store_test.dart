@Tags(['integration'])
library;

import 'package:drift/native.dart';
import 'package:durable_workflow/durable_workflow.dart';
import 'package:test/test.dart';

import 'package:durable_workflow_drift/durable_workflow_drift.dart';

DurableWorkflowDatabase _openInMemory() {
  return DurableWorkflowDatabase(NativeDatabase.memory());
}

final _testWorkflow = Workflow(
  workflowId: 'wf-1',
  workflowType: 'test',
  createdAt: '2026-03-25T10:00:00.000',
);

final _testExecution = WorkflowExecution(
  workflowExecutionId: 'exec-1',
  workflowId: 'wf-1',
  createdAt: '2026-03-25T10:00:00.000',
  updatedAt: '2026-03-25T10:00:00.000',
);

void main() {
  late DurableWorkflowDatabase db;
  late DriftCheckpointStore store;

  setUp(() {
    db = _openInMemory();
    store = DriftCheckpointStore(db);
  });

  tearDown(() async {
    await store.close();
  });

  // -------------------------------------------------------------------------
  // Schema & PRAGMA verification
  // -------------------------------------------------------------------------
  group('schema', () {
    test('creates all 5 tables', () async {
      final result = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      ).get();
      final tables = result.map((r) => r.read<String>('name')).toList();
      expect(tables, containsAll([
        'step_checkpoints',
        'workflow_executions',
        'workflow_signals',
        'workflow_timers',
        'workflows',
      ]));
    });

    test('foreign_keys is ON', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').get();
      expect(result.first.read<int>('foreign_keys'), equals(1));
    });

    test('synchronous is NORMAL (1)', () async {
      final result = await db.customSelect('PRAGMA synchronous').get();
      expect(result.first.read<int>('synchronous'), equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Workflow CRUD
  // -------------------------------------------------------------------------
  group('workflow CRUD', () {
    test('saveWorkflow and loadWorkflow round-trip', () async {
      final workflow = Workflow(
        workflowId: 'wf-1',
        workflowType: 'order_processing',
        version: 1,
        createdAt: '2026-03-25T10:00:00.000',
      );
      await store.saveWorkflow(workflow);

      final loaded = await store.loadWorkflow('wf-1');
      expect(loaded, isNotNull);
      expect(loaded!.workflowId, equals('wf-1'));
      expect(loaded.workflowType, equals('order_processing'));
      expect(loaded.version, equals(1));
    });

    test('loadWorkflow returns null for non-existent ID', () async {
      final result = await store.loadWorkflow('non-existent');
      expect(result, isNull);
    });

    test('saveWorkflow replaces on conflict', () async {
      final workflow = Workflow(
        workflowId: 'wf-1',
        workflowType: 'v1',
        version: 1,
        createdAt: '2026-03-25T10:00:00.000',
      );
      await store.saveWorkflow(workflow);

      final updated = Workflow(
        workflowId: 'wf-1',
        workflowType: 'v2',
        version: 2,
        createdAt: '2026-03-25T10:00:00.000',
      );
      await store.saveWorkflow(updated);

      final loaded = await store.loadWorkflow('wf-1');
      expect(loaded!.workflowType, equals('v2'));
      expect(loaded.version, equals(2));
    });
  });

  // -------------------------------------------------------------------------
  // WorkflowExecution CRUD
  // -------------------------------------------------------------------------
  group('execution CRUD', () {
    setUp(() async {
      await store.saveWorkflow(_testWorkflow);
    });

    test('saveExecution and loadExecution round-trip', () async {
      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-1',
        workflowId: 'wf-1',
        status: const Pending(),
        currentStep: 0,
        inputData: '{"key":"value"}',
        guarantee: WorkflowGuarantee.foregroundOnly,
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      );

      await store.saveExecution(execution);
      final loaded = await store.loadExecution('exec-1');

      expect(loaded, isNotNull);
      expect(loaded!.workflowExecutionId, equals('exec-1'));
      expect(loaded.workflowId, equals('wf-1'));
      expect(loaded.status, isA<Pending>());
      expect(loaded.currentStep, equals(0));
      expect(loaded.inputData, equals('{"key":"value"}'));
      expect(loaded.guarantee, equals(WorkflowGuarantee.foregroundOnly));
    });

    test('loadExecution returns null for non-existent ID', () async {
      final result = await store.loadExecution('non-existent');
      expect(result, isNull);
    });

    test('saveExecution updates on conflict', () async {
      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-1',
        workflowId: 'wf-1',
        status: const Pending(),
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      );
      await store.saveExecution(execution);

      final updated = execution.copyWith(
        status: const Running(),
        currentStep: 2,
        updatedAt: '2026-03-25T11:00:00.000',
      );
      await store.saveExecution(updated);

      final loaded = await store.loadExecution('exec-1');
      expect(loaded!.status, isA<Running>());
      expect(loaded.currentStep, equals(2));
    });

    test('saveExecution preserves all status values', () async {
      for (final status in [
        const Pending(),
        const Running(),
        const Suspended(),
        const Completed(),
        const Failed(),
        const Compensating(),
        const Cancelled(),
      ]) {
        final exec = WorkflowExecution(
          workflowExecutionId: 'exec-status-${status.name}',
          workflowId: 'wf-1',
          status: status,
          createdAt: '2026-03-25T10:00:00.000',
          updatedAt: '2026-03-25T10:00:00.000',
        );
        await store.saveExecution(exec);
        final loaded = await store.loadExecution('exec-status-${status.name}');
        expect(loaded!.status.name, equals(status.name));
      }
    });

    test('saveExecution with all optional fields', () async {
      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-full',
        workflowId: 'wf-1',
        status: const Completed(),
        currentStep: 5,
        inputData: '{"in":"data"}',
        outputData: '{"out":"result"}',
        errorMessage: null,
        ttlExpiresAt: '2026-04-25T10:00:00.000',
        guarantee: WorkflowGuarantee.bestEffortBackground,
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T12:00:00.000',
      );

      await store.saveExecution(execution);
      final loaded = await store.loadExecution('exec-full');

      expect(loaded!.outputData, equals('{"out":"result"}'));
      expect(loaded.ttlExpiresAt, equals('2026-04-25T10:00:00.000'));
      expect(loaded.guarantee, equals(WorkflowGuarantee.bestEffortBackground));
    });

    test('loadExecutionsByStatus returns matching executions', () async {
      await store.saveExecution(WorkflowExecution(
        workflowExecutionId: 'exec-running',
        workflowId: 'wf-1',
        status: const Running(),
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      ));
      await store.saveExecution(WorkflowExecution(
        workflowExecutionId: 'exec-completed',
        workflowId: 'wf-1',
        status: const Completed(),
        createdAt: '2026-03-25T10:01:00.000',
        updatedAt: '2026-03-25T10:01:00.000',
      ));

      final running = await store.loadExecutionsByStatus([const Running()]);
      expect(running, hasLength(1));
      expect(running[0].workflowExecutionId, equals('exec-running'));

      final empty = await store.loadExecutionsByStatus([]);
      expect(empty, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // StepCheckpoint CRUD
  // -------------------------------------------------------------------------
  group('checkpoint CRUD', () {
    setUp(() async {
      await store.saveWorkflow(_testWorkflow);
      await store.saveExecution(_testExecution);
    });

    test('saveCheckpoint and loadCheckpoints round-trip', () async {
      final checkpoint = StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.intent,
        inputData: '{"order_id":"123"}',
        attempt: 1,
        startedAt: '2026-03-25T10:00:00.000',
      );

      await store.saveCheckpoint(checkpoint);
      final loaded = await store.loadCheckpoints('exec-1');

      expect(loaded, hasLength(1));
      expect(loaded[0].stepName, equals('validate'));
      expect(loaded[0].status, equals(StepStatus.intent));
      expect(loaded[0].inputData, equals('{"order_id":"123"}'));
      expect(loaded[0].id, isNotNull);
    });

    test('loadCheckpoints returns empty list for no checkpoints', () async {
      final result = await store.loadCheckpoints('exec-1');
      expect(result, isEmpty);
    });

    test('loadCheckpoints orders by stepIndex', () async {
      await store.saveCheckpoint(StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 2,
        stepName: 'ship',
        status: StepStatus.intent,
      ));
      await store.saveCheckpoint(StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.completed,
      ));
      await store.saveCheckpoint(StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 1,
        stepName: 'pay',
        status: StepStatus.completed,
      ));

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(3));
      expect(loaded[0].stepIndex, equals(0));
      expect(loaded[1].stepIndex, equals(1));
      expect(loaded[2].stepIndex, equals(2));
    });

    test('saveCheckpoint upserts on conflict (same exec+step+attempt)',
        () async {
      final intent = StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.intent,
        attempt: 1,
        startedAt: '2026-03-25T10:00:00.000',
      );
      await store.saveCheckpoint(intent);

      final completed = StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.completed,
        attempt: 1,
        outputData: '{"result":"ok"}',
        startedAt: '2026-03-25T10:00:00.000',
        completedAt: '2026-03-25T10:01:00.000',
      );
      await store.saveCheckpoint(completed);

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(1));
      expect(loaded[0].status, equals(StepStatus.completed));
      expect(loaded[0].outputData, equals('{"result":"ok"}'));
    });

    test('checkpoint with all fields populated', () async {
      final checkpoint = StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 0,
        stepName: 'pay',
        status: StepStatus.failed,
        inputData: '{"amount":100}',
        outputData: null,
        errorMessage: 'Payment gateway timeout',
        attempt: 3,
        compensateRef: 'refund_payment',
        startedAt: '2026-03-25T10:00:00.000',
        completedAt: '2026-03-25T10:00:05.000',
      );
      await store.saveCheckpoint(checkpoint);

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded[0].errorMessage, equals('Payment gateway timeout'));
      expect(loaded[0].attempt, equals(3));
      expect(loaded[0].compensateRef, equals('refund_payment'));
    });

    test('all StepStatus values round-trip', () async {
      for (final (i, status) in [
        StepStatus.intent,
        StepStatus.completed,
        StepStatus.failed,
        StepStatus.compensated,
      ].indexed) {
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-1',
          stepIndex: i,
          stepName: 'step_$i',
          status: status,
        ));
      }

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded[0].status, equals(StepStatus.intent));
      expect(loaded[1].status, equals(StepStatus.completed));
      expect(loaded[2].status, equals(StepStatus.failed));
      expect(loaded[3].status, equals(StepStatus.compensated));
    });
  });

  // -------------------------------------------------------------------------
  // WorkflowTimer CRUD
  // -------------------------------------------------------------------------
  group('timer CRUD', () {
    setUp(() async {
      await store.saveWorkflow(_testWorkflow);
      await store.saveExecution(_testExecution);
    });

    test('saveTimer and loadPendingTimers round-trip', () async {
      final timer = WorkflowTimer(
        workflowTimerId: 'timer-1',
        workflowExecutionId: 'exec-1',
        stepName: 'await_shipping',
        fireAt: '2020-01-01T00:00:00.000',
        status: TimerStatus.pending,
        createdAt: '2020-01-01T00:00:00.000',
      );

      await store.saveTimer(timer);
      final loaded = await store.loadPendingTimers();

      expect(loaded, hasLength(1));
      expect(loaded[0].workflowTimerId, equals('timer-1'));
      expect(loaded[0].stepName, equals('await_shipping'));
      expect(loaded[0].status, equals(TimerStatus.pending));
    });

    test('loadPendingTimers excludes fired and cancelled', () async {
      await store.saveTimer(WorkflowTimer(
        workflowTimerId: 'timer-pending',
        workflowExecutionId: 'exec-1',
        stepName: 'step1',
        fireAt: '2020-01-01T00:00:00.000',
        status: TimerStatus.pending,
        createdAt: '2020-01-01T00:00:00.000',
      ));
      await store.saveTimer(WorkflowTimer(
        workflowTimerId: 'timer-fired',
        workflowExecutionId: 'exec-1',
        stepName: 'step2',
        fireAt: '2020-01-01T00:00:00.000',
        status: TimerStatus.fired,
        createdAt: '2020-01-01T00:00:00.000',
      ));
      await store.saveTimer(WorkflowTimer(
        workflowTimerId: 'timer-cancelled',
        workflowExecutionId: 'exec-1',
        stepName: 'step3',
        fireAt: '2020-01-01T00:00:00.000',
        status: TimerStatus.cancelled,
        createdAt: '2020-01-01T00:00:00.000',
      ));

      final loaded = await store.loadPendingTimers();
      expect(loaded, hasLength(1));
      expect(loaded[0].workflowTimerId, equals('timer-pending'));
    });

    test('saveTimer upserts on conflict', () async {
      await store.saveTimer(WorkflowTimer(
        workflowTimerId: 'timer-1',
        workflowExecutionId: 'exec-1',
        stepName: 'await_shipping',
        fireAt: '2020-01-01T00:00:00.000',
        status: TimerStatus.pending,
        createdAt: '2020-01-01T00:00:00.000',
      ));

      await store.saveTimer(WorkflowTimer(
        workflowTimerId: 'timer-1',
        workflowExecutionId: 'exec-1',
        stepName: 'await_shipping',
        fireAt: '2020-01-01T00:00:00.000',
        status: TimerStatus.fired,
        createdAt: '2020-01-01T00:00:00.000',
      ));

      final loaded = await store.loadPendingTimers();
      expect(loaded, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // WorkflowSignal CRUD
  // -------------------------------------------------------------------------
  group('signal CRUD', () {
    setUp(() async {
      await store.saveWorkflow(_testWorkflow);
      await store.saveExecution(_testExecution);
    });

    test('saveSignal and loadPendingSignals round-trip', () async {
      final signal = WorkflowSignal(
        workflowExecutionId: 'exec-1',
        signalName: 'delivery_confirmed',
        payload: '{"confirmed":true}',
        status: SignalStatus.pending,
        createdAt: '2026-03-25T10:00:00.000',
      );

      await store.saveSignal(signal);
      final loaded = await store.loadPendingSignals('exec-1');

      expect(loaded, hasLength(1));
      expect(loaded[0].signalName, equals('delivery_confirmed'));
      expect(loaded[0].payload, equals('{"confirmed":true}'));
      expect(loaded[0].workflowSignalId, isNotNull);
    });

    test('loadPendingSignals filters by signalName', () async {
      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-1',
        signalName: 'signal_a',
        status: SignalStatus.pending,
        createdAt: '2026-03-25T10:00:00.000',
      ));
      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-1',
        signalName: 'signal_b',
        status: SignalStatus.pending,
        createdAt: '2026-03-25T10:01:00.000',
      ));

      final loaded = await store.loadPendingSignals(
        'exec-1',
        signalName: 'signal_a',
      );
      expect(loaded, hasLength(1));
      expect(loaded[0].signalName, equals('signal_a'));
    });

    test('loadPendingSignals excludes delivered and expired', () async {
      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-1',
        signalName: 'sig_pending',
        status: SignalStatus.pending,
        createdAt: '2026-03-25T10:00:00.000',
      ));
      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-1',
        signalName: 'sig_delivered',
        status: SignalStatus.delivered,
        createdAt: '2026-03-25T10:00:00.000',
      ));
      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-1',
        signalName: 'sig_expired',
        status: SignalStatus.expired,
        createdAt: '2026-03-25T10:00:00.000',
      ));

      final loaded = await store.loadPendingSignals('exec-1');
      expect(loaded, hasLength(1));
      expect(loaded[0].signalName, equals('sig_pending'));
    });

    test('loadPendingSignals returns empty for non-existent execution',
        () async {
      final loaded = await store.loadPendingSignals('non-existent');
      expect(loaded, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Reactive queries (Drift-specific)
  // -------------------------------------------------------------------------
  group('reactive queries', () {
    setUp(() async {
      await store.saveWorkflow(_testWorkflow);
    });

    test('watchExecution emits updates', () async {
      await store.saveExecution(WorkflowExecution(
        workflowExecutionId: 'exec-1',
        workflowId: 'wf-1',
        status: const Pending(),
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      ));

      final stream = store.watchExecution('exec-1');
      final first = await stream.first;
      expect(first, isNotNull);
      expect(first!.status, isA<Pending>());
    });

    test('watchExecution returns null for non-existent', () async {
      final stream = store.watchExecution('non-existent');
      final first = await stream.first;
      expect(first, isNull);
    });

    test('watchExecutionsByStatus filters correctly', () async {
      await store.saveExecution(WorkflowExecution(
        workflowExecutionId: 'exec-running',
        workflowId: 'wf-1',
        status: const Running(),
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      ));
      await store.saveExecution(WorkflowExecution(
        workflowExecutionId: 'exec-done',
        workflowId: 'wf-1',
        status: const Completed(),
        createdAt: '2026-03-25T10:01:00.000',
        updatedAt: '2026-03-25T10:01:00.000',
      ));

      final stream = store.watchExecutionsByStatus([const Running()]);
      final first = await stream.first;
      expect(first, hasLength(1));
      expect(first[0].workflowExecutionId, equals('exec-running'));
    });
  });

  // -------------------------------------------------------------------------
  // Integration: Full lifecycle
  // -------------------------------------------------------------------------
  group('integration', () {
    test('full workflow lifecycle: save -> checkpoint -> load -> verify',
        () async {
      await store.saveWorkflow(Workflow(
        workflowId: 'wf-order',
        workflowType: 'order_processing',
        createdAt: '2026-03-25T10:00:00.000',
      ));

      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-order-1',
        workflowId: 'wf-order',
        status: const Running(),
        inputData: '{"orderId":"O-123","amount":99.99}',
        guarantee: WorkflowGuarantee.foregroundOnly,
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      );
      await store.saveExecution(execution);

      await store.saveCheckpoint(StepCheckpoint(
        workflowExecutionId: 'exec-order-1',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.completed,
        outputData: '{"valid":true}',
        startedAt: '2026-03-25T10:00:01.000',
        completedAt: '2026-03-25T10:00:02.000',
      ));

      await store.saveCheckpoint(StepCheckpoint(
        workflowExecutionId: 'exec-order-1',
        stepIndex: 1,
        stepName: 'pay',
        status: StepStatus.intent,
        compensateRef: 'refund_payment',
        startedAt: '2026-03-25T10:00:03.000',
      ));

      await store.saveTimer(WorkflowTimer(
        workflowTimerId: 'timer-shipping',
        workflowExecutionId: 'exec-order-1',
        stepName: 'await_shipping',
        fireAt: '2020-01-01T00:00:00.000',
        createdAt: '2026-03-25T10:00:04.000',
      ));

      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-order-1',
        signalName: 'delivery_confirmed',
        payload: '{"confirmed":true}',
        createdAt: '2026-03-25T10:00:05.000',
      ));

      // Verify
      final loadedExec = await store.loadExecution('exec-order-1');
      expect(loadedExec, isNotNull);
      expect(loadedExec!.status, isA<Running>());

      final checkpoints = await store.loadCheckpoints('exec-order-1');
      expect(checkpoints, hasLength(2));
      expect(checkpoints[0].stepName, equals('validate'));
      expect(checkpoints[0].status, equals(StepStatus.completed));
      expect(checkpoints[1].stepName, equals('pay'));

      final timers = await store.loadPendingTimers();
      expect(timers, hasLength(1));
      expect(timers[0].stepName, equals('await_shipping'));

      final signals = await store.loadPendingSignals('exec-order-1');
      expect(signals, hasLength(1));
      expect(signals[0].signalName, equals('delivery_confirmed'));

      // Complete the execution
      await store.saveExecution(loadedExec.copyWith(
        status: const Completed(),
        outputData: '{"success":true}',
        updatedAt: '2026-03-25T10:01:00.000',
      ));

      final completedExec = await store.loadExecution('exec-order-1');
      expect(completedExec!.status, isA<Completed>());
      expect(completedExec.outputData, equals('{"success":true}'));
    });
  });

  // -------------------------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------------------------
  group('edge cases', () {
    test('null optional fields persist correctly', () async {
      await store.saveWorkflow(_testWorkflow);
      await store.saveExecution(_testExecution);

      await store.saveCheckpoint(StepCheckpoint(
        workflowExecutionId: 'exec-1',
        stepIndex: 0,
        stepName: 'minimal',
        status: StepStatus.intent,
      ));

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded[0].inputData, isNull);
      expect(loaded[0].outputData, isNull);
      expect(loaded[0].errorMessage, isNull);
      expect(loaded[0].compensateRef, isNull);
      expect(loaded[0].startedAt, isNull);
      expect(loaded[0].completedAt, isNull);
    });

    test('signal with null payload', () async {
      await store.saveWorkflow(_testWorkflow);
      await store.saveExecution(_testExecution);

      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-1',
        signalName: 'no_payload',
        payload: null,
        createdAt: '2026-03-25T10:00:00.000',
      ));

      final loaded = await store.loadPendingSignals('exec-1');
      expect(loaded[0].payload, isNull);
    });
  });
}
