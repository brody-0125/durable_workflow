@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryCheckpointStore store;

  setUp(() {
    store = InMemoryCheckpointStore();
  });

  group('InMemoryCheckpointStore', () {
    group('saveExecution / loadExecution', () {
      test('saves and loads an execution', () async {
        final exec = WorkflowExecution(
          workflowExecutionId: 'exec-001',
          workflowId: 'wf-001',
          status: const Running(),
          createdAt: '2026-03-25T10:00:00.000',
          updatedAt: '2026-03-25T10:00:00.000',
        );

        await store.saveExecution(exec);
        final loaded = await store.loadExecution('exec-001');

        expect(loaded, isNotNull);
        expect(loaded!.workflowExecutionId, 'exec-001');
        expect(loaded.status, isA<Running>());
      });

      test('returns null for unknown execution', () async {
        final loaded = await store.loadExecution('nonexistent');
        expect(loaded, isNull);
      });

      test('overwrites existing execution on save', () async {
        final exec = WorkflowExecution(
          workflowExecutionId: 'exec-001',
          workflowId: 'wf-001',
          status: const Running(),
          createdAt: '2026-03-25T10:00:00.000',
          updatedAt: '2026-03-25T10:00:00.000',
        );
        await store.saveExecution(exec);

        final updated = exec.copyWith(status: const Completed());
        await store.saveExecution(updated);

        final loaded = await store.loadExecution('exec-001');
        expect(loaded!.status, isA<Completed>());
      });
    });

    group('loadExecutionsByStatus', () {
      test('returns executions matching given statuses', () async {
        final now = '2026-03-25T10:00:00.000';
        await store.saveExecution(WorkflowExecution(
          workflowExecutionId: 'exec-running',
          workflowId: 'wf-001',
          status: const Running(),
          createdAt: now,
          updatedAt: now,
        ));
        await store.saveExecution(WorkflowExecution(
          workflowExecutionId: 'exec-completed',
          workflowId: 'wf-001',
          status: const Completed(),
          createdAt: now,
          updatedAt: now,
        ));
        await store.saveExecution(WorkflowExecution(
          workflowExecutionId: 'exec-suspended',
          workflowId: 'wf-001',
          status: const Suspended(),
          createdAt: now,
          updatedAt: now,
        ));

        final results = await store.loadExecutionsByStatus([
          const Running(),
          const Suspended(),
        ]);

        expect(results.length, 2);
        final ids = results.map((e) => e.workflowExecutionId).toSet();
        expect(ids, contains('exec-running'));
        expect(ids, contains('exec-suspended'));
        expect(ids, isNot(contains('exec-completed')));
      });

      test('returns empty list when no match', () async {
        final results = await store.loadExecutionsByStatus([const Running()]);
        expect(results, isEmpty);
      });
    });

    group('saveCheckpoint / loadCheckpoints', () {
      test('saves and loads checkpoints sorted by stepIndex', () async {
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-001',
          stepIndex: 1,
          stepName: 'step_b',
          status: StepStatus.completed,
        ));
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-001',
          stepIndex: 0,
          stepName: 'step_a',
          status: StepStatus.completed,
        ));

        final checkpoints = await store.loadCheckpoints('exec-001');
        expect(checkpoints.length, 2);
        expect(checkpoints[0].stepIndex, 0);
        expect(checkpoints[1].stepIndex, 1);
      });

      test('assigns auto-incrementing IDs', () async {
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-001',
          stepIndex: 0,
          stepName: 'step_a',
          status: StepStatus.intent,
        ));
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-001',
          stepIndex: 1,
          stepName: 'step_b',
          status: StepStatus.intent,
        ));

        final checkpoints = await store.loadCheckpoints('exec-001');
        expect(checkpoints[0].id, isNotNull);
        expect(checkpoints[1].id, isNotNull);
        expect(checkpoints[0].id, isNot(checkpoints[1].id));
      });

      test('updates existing checkpoint (same stepIndex, attempt)', () async {
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-001',
          stepIndex: 0,
          stepName: 'step_a',
          status: StepStatus.intent,
        ));
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-001',
          stepIndex: 0,
          stepName: 'step_a',
          status: StepStatus.completed,
          outputData: '"done"',
        ));

        final checkpoints = await store.loadCheckpoints('exec-001');
        expect(checkpoints.length, 1);
        expect(checkpoints[0].status, StepStatus.completed);
      });

      test('returns empty list for unknown execution', () async {
        final checkpoints = await store.loadCheckpoints('nonexistent');
        expect(checkpoints, isEmpty);
      });

      test('returned list is unmodifiable', () async {
        await store.saveCheckpoint(StepCheckpoint(
          workflowExecutionId: 'exec-001',
          stepIndex: 0,
          stepName: 'step_a',
          status: StepStatus.completed,
        ));

        final checkpoints = await store.loadCheckpoints('exec-001');
        expect(
          () => checkpoints.add(StepCheckpoint(
            workflowExecutionId: 'exec-001',
            stepIndex: 1,
            stepName: 'step_b',
            status: StepStatus.intent,
          )),
          throwsUnsupportedError,
        );
      });
    });

    group('saveTimer / loadPendingTimers', () {
      test('saves and loads pending timers', () async {
        final timer = WorkflowTimer(
          workflowTimerId: 'timer-001',
          workflowExecutionId: 'exec-001',
          stepName: 'wait',
          fireAt: '2026-03-26T10:00:00.000',
          createdAt: '2026-03-25T10:00:00.000',
        );
        await store.saveTimer(timer);

        final timers = await store.loadPendingTimers();
        expect(timers.length, 1);
        expect(timers[0].workflowTimerId, 'timer-001');
      });

      test('excludes non-pending timers', () async {
        await store.saveTimer(WorkflowTimer(
          workflowTimerId: 'timer-001',
          workflowExecutionId: 'exec-001',
          stepName: 'wait',
          fireAt: '2026-03-26T10:00:00.000',
          status: TimerStatus.fired,
          createdAt: '2026-03-25T10:00:00.000',
        ));

        final timers = await store.loadPendingTimers();
        expect(timers, isEmpty);
      });

      test('updates existing timer', () async {
        final timer = WorkflowTimer(
          workflowTimerId: 'timer-001',
          workflowExecutionId: 'exec-001',
          stepName: 'wait',
          fireAt: '2026-03-26T10:00:00.000',
          createdAt: '2026-03-25T10:00:00.000',
        );
        await store.saveTimer(timer);

        await store.saveTimer(timer.copyWith(status: TimerStatus.fired));

        final timers = await store.loadPendingTimers();
        expect(timers, isEmpty);
      });
    });

    group('saveSignal / loadPendingSignals', () {
      test('saves and loads pending signals', () async {
        final signal = WorkflowSignal(
          workflowExecutionId: 'exec-001',
          signalName: 'delivery',
          payload: 'true',
          createdAt: '2026-03-25T10:00:00.000',
        );
        await store.saveSignal(signal);

        final signals = await store.loadPendingSignals('exec-001');
        expect(signals.length, 1);
        expect(signals[0].signalName, 'delivery');
      });

      test('assigns auto-incrementing signal IDs', () async {
        await store.saveSignal(WorkflowSignal(
          workflowExecutionId: 'exec-001',
          signalName: 'sig_a',
          createdAt: '2026-03-25T10:00:00.000',
        ));
        await store.saveSignal(WorkflowSignal(
          workflowExecutionId: 'exec-001',
          signalName: 'sig_b',
          createdAt: '2026-03-25T10:00:00.000',
        ));

        final signals = await store.loadPendingSignals('exec-001');
        expect(signals[0].workflowSignalId, isNotNull);
        expect(signals[1].workflowSignalId, isNotNull);
      });

      test('filters by signalName', () async {
        await store.saveSignal(WorkflowSignal(
          workflowExecutionId: 'exec-001',
          signalName: 'delivery',
          createdAt: '2026-03-25T10:00:00.000',
        ));
        await store.saveSignal(WorkflowSignal(
          workflowExecutionId: 'exec-001',
          signalName: 'payment',
          createdAt: '2026-03-25T10:00:00.000',
        ));

        final signals = await store.loadPendingSignals(
          'exec-001',
          signalName: 'delivery',
        );
        expect(signals.length, 1);
        expect(signals[0].signalName, 'delivery');
      });

      test('filters by execution ID', () async {
        await store.saveSignal(WorkflowSignal(
          workflowExecutionId: 'exec-001',
          signalName: 'sig',
          createdAt: '2026-03-25T10:00:00.000',
        ));
        await store.saveSignal(WorkflowSignal(
          workflowExecutionId: 'exec-002',
          signalName: 'sig',
          createdAt: '2026-03-25T10:00:00.000',
        ));

        final signals = await store.loadPendingSignals('exec-001');
        expect(signals.length, 1);
      });

      test('excludes non-pending signals', () async {
        await store.saveSignal(WorkflowSignal(
          workflowExecutionId: 'exec-001',
          signalName: 'sig',
          status: SignalStatus.delivered,
          createdAt: '2026-03-25T10:00:00.000',
        ));

        final signals = await store.loadPendingSignals('exec-001');
        expect(signals, isEmpty);
      });
    });
  });
}
