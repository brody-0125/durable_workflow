import 'package:durable_workflow/durable_workflow.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Runs the full contract test suite against a [CheckpointStore] implementation.
///
/// [createStore] must return a fresh, empty store for each test.
void runCheckpointStoreContractTests(
  CheckpointStore Function() createStore,
) {
  late CheckpointStore store;

  setUp(() {
    store = createStore();
  });

  group('CheckpointStore contract', () {
    group('Execution', () {
      test('saveExecution then loadExecution returns same data', () async {
        final exec = createTestExecution('exec-1');
        await store.saveExecution(exec);

        final loaded = await store.loadExecution('exec-1');
        expect(loaded, isNotNull);
        expect(loaded!.workflowExecutionId, equals('exec-1'));
        expect(loaded.status, isA<Running>());
        expect(loaded.currentStep, equals(0));
      });

      test('loadExecution returns null for non-existent ID', () async {
        final loaded = await store.loadExecution('non-existent');
        expect(loaded, isNull);
      });

      test('saveExecution updates existing execution', () async {
        final exec = createTestExecution('exec-1');
        await store.saveExecution(exec);

        final updated = exec.copyWith(
          status: const Completed(),
          currentStep: 3,
          updatedAt: nowTimestamp(),
        );
        await store.saveExecution(updated);

        final loaded = await store.loadExecution('exec-1');
        expect(loaded, isNotNull);
        expect(loaded!.status, isA<Completed>());
        expect(loaded.currentStep, equals(3));
      });

      test('loadExecutionsByStatus filters correctly', () async {
        await store.saveExecution(createTestExecution('exec-1',
            status: const Running()));
        await store.saveExecution(createTestExecution('exec-2',
            status: const Completed()));
        await store.saveExecution(createTestExecution('exec-3',
            status: const Running()));
        await store.saveExecution(createTestExecution('exec-4',
            status: const Failed()));

        final running = await store.loadExecutionsByStatus(
          [const Running()],
        );
        expect(running, hasLength(2));
        expect(
          running.map((e) => e.workflowExecutionId).toList()..sort(),
          equals(['exec-1', 'exec-3']),
        );
      });

      test('loadExecutionsByStatus with multiple statuses', () async {
        await store.saveExecution(createTestExecution('exec-1',
            status: const Running()));
        await store.saveExecution(createTestExecution('exec-2',
            status: const Completed()));
        await store.saveExecution(createTestExecution('exec-3',
            status: const Failed()));

        final results = await store.loadExecutionsByStatus(
          [const Running(), const Failed()],
        );
        expect(results, hasLength(2));
      });

      test('loadExecutionsByStatus returns empty for no matches', () async {
        await store.saveExecution(createTestExecution('exec-1',
            status: const Running()));

        final results = await store.loadExecutionsByStatus(
          [const Completed()],
        );
        expect(results, isEmpty);
      });
    });

    group('Checkpoint', () {
      test('saveCheckpoint then loadCheckpoints returns data', () async {
        await store.saveExecution(createTestExecution('exec-1'));

        final cp = createTestCheckpoint(
          workflowExecutionId: 'exec-1',
          stepIndex: 0,
          stepName: 'validate',
        );
        await store.saveCheckpoint(cp);

        final loaded = await store.loadCheckpoints('exec-1');
        expect(loaded, hasLength(1));
        expect(loaded.first.stepName, equals('validate'));
        expect(loaded.first.status, equals(StepStatus.completed));
      });

      test('loadCheckpoints returns ordered by stepIndex', () async {
        await store.saveExecution(createTestExecution('exec-1'));

        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-1', stepIndex: 2, stepName: 'step-2',
        ));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-1', stepIndex: 0, stepName: 'step-0',
        ));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-1', stepIndex: 1, stepName: 'step-1',
        ));

        final loaded = await store.loadCheckpoints('exec-1');
        expect(loaded, hasLength(3));
        expect(loaded[0].stepIndex, equals(0));
        expect(loaded[1].stepIndex, equals(1));
        expect(loaded[2].stepIndex, equals(2));
      });

      test('loadCheckpoints returns empty for non-existent execution',
          () async {
        final loaded = await store.loadCheckpoints('non-existent');
        expect(loaded, isEmpty);
      });

      test('checkpoints are scoped to execution', () async {
        await store.saveExecution(createTestExecution('exec-1'));
        await store.saveExecution(createTestExecution('exec-2'));

        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-1', stepIndex: 0, stepName: 'a',
        ));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-2', stepIndex: 0, stepName: 'b',
        ));

        final loaded1 = await store.loadCheckpoints('exec-1');
        final loaded2 = await store.loadCheckpoints('exec-2');
        expect(loaded1, hasLength(1));
        expect(loaded1.first.stepName, equals('a'));
        expect(loaded2, hasLength(1));
        expect(loaded2.first.stepName, equals('b'));
      });
    });

    group('Timer', () {
      test('saveTimer then loadPendingTimers returns pending timers',
          () async {
        await store.saveExecution(createTestExecution('exec-1'));

        final timer = createTestTimer('timer-1', 'exec-1');
        await store.saveTimer(timer);

        final loaded = await store.loadPendingTimers();
        expect(loaded, isNotEmpty);
        expect(
          loaded.any((t) => t.workflowTimerId == 'timer-1'),
          isTrue,
        );
      });

      test('fired timers are not returned by loadPendingTimers', () async {
        await store.saveExecution(createTestExecution('exec-1'));

        final timer = createTestTimer('timer-1', 'exec-1');
        await store.saveTimer(timer);

        await store.saveTimer(
          timer.copyWith(status: TimerStatus.fired),
        );

        final loaded = await store.loadPendingTimers();
        expect(
          loaded.any((t) => t.workflowTimerId == 'timer-1'),
          isFalse,
        );
      });
    });

    group('Signal', () {
      test('saveSignal then loadPendingSignals returns signals', () async {
        await store.saveExecution(createTestExecution('exec-1'));

        final signal = createTestSignal('exec-1');
        await store.saveSignal(signal);

        final loaded = await store.loadPendingSignals('exec-1');
        expect(loaded, isNotEmpty);
        expect(loaded.first.signalName, equals('test-signal'));
      });

      test('loadPendingSignals filters by signalName', () async {
        await store.saveExecution(createTestExecution('exec-1'));

        await store.saveSignal(
          createTestSignal('exec-1', signalName: 'approve'),
        );
        await store.saveSignal(
          createTestSignal('exec-1', signalName: 'reject'),
        );

        final loaded = await store.loadPendingSignals(
          'exec-1',
          signalName: 'approve',
        );
        expect(loaded, hasLength(1));
        expect(loaded.first.signalName, equals('approve'));
      });

      test('loadPendingSignals returns empty for wrong execution', () async {
        await store.saveExecution(createTestExecution('exec-1'));
        await store.saveSignal(createTestSignal('exec-1'));

        final loaded = await store.loadPendingSignals('exec-other');
        expect(loaded, isEmpty);
      });

      test('delivered signals are not returned by loadPendingSignals',
          () async {
        await store.saveExecution(createTestExecution('exec-1'));

        await store.saveSignal(createTestSignal('exec-1'));

        // Load the saved signal to get its auto-assigned ID
        final pending = await store.loadPendingSignals('exec-1');
        expect(pending, hasLength(1));

        // Update with the assigned ID to trigger upsert
        await store.saveSignal(
          pending.first.copyWith(status: SignalStatus.delivered),
        );

        final loaded = await store.loadPendingSignals('exec-1');
        expect(loaded, isEmpty);
      });
    });

    group('Cleanup', () {
      test('deleteExecution removes execution and associated data', () async {
        await store.saveExecution(createTestExecution('exec-1'));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-1',
          stepIndex: 0,
          stepName: 'step-0',
        ));
        await store.saveTimer(createTestTimer('timer-1', 'exec-1'));
        await store.saveSignal(createTestSignal('exec-1'));

        await store.deleteExecution('exec-1');

        expect(await store.loadExecution('exec-1'), isNull);
        expect(await store.loadCheckpoints('exec-1'), isEmpty);
        expect(
          (await store.loadPendingTimers())
              .where((t) => t.workflowExecutionId == 'exec-1'),
          isEmpty,
        );
        expect(await store.loadPendingSignals('exec-1'), isEmpty);
      });

      test('deleteExecution does not affect other executions', () async {
        await store.saveExecution(createTestExecution('exec-1'));
        await store.saveExecution(createTestExecution('exec-2'));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-1',
          stepIndex: 0,
          stepName: 'a',
        ));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-2',
          stepIndex: 0,
          stepName: 'b',
        ));

        await store.deleteExecution('exec-1');

        expect(await store.loadExecution('exec-1'), isNull);
        expect(await store.loadExecution('exec-2'), isNotNull);
        expect(await store.loadCheckpoints('exec-2'), hasLength(1));
      });

      test('deleteCompletedBefore removes old completed executions', () async {
        final now = DateTime.now().toUtc();
        final old = now.subtract(const Duration(hours: 2));
        final recent = now.subtract(const Duration(minutes: 30));

        await store.saveExecution(createTestExecution(
          'exec-old',
          status: const Completed(),
        ).copyWith(updatedAt: old.toIso8601String()));
        await store.saveExecution(createTestExecution(
          'exec-recent',
          status: const Completed(),
        ).copyWith(updatedAt: recent.toIso8601String()));
        await store.saveExecution(createTestExecution(
          'exec-running',
          status: const Running(),
        ).copyWith(updatedAt: old.toIso8601String()));

        final cutoff = now.subtract(const Duration(hours: 1));
        final deleted = await store.deleteCompletedBefore(cutoff);

        expect(deleted, 1);
        expect(await store.loadExecution('exec-old'), isNull);
        expect(await store.loadExecution('exec-recent'), isNotNull);
        expect(await store.loadExecution('exec-running'), isNotNull);
      });
    });
  });
}
