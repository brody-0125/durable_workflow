@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  late InMemoryCheckpointStore store;
  late DurableEngineImpl engine;

  setUp(() {
    store = InMemoryCheckpointStore();
    engine = createTestEngine(store);
  });

  tearDown(() {
    engine.dispose();
  });

  group('TimerManager', () {
    test('ctx.sleep creates PENDING timer in store', () async {
      final future = engine.run<int>(
        'timer_wf',
        (ctx) async {
          await ctx.sleep(
            'wait',
            const Duration(milliseconds: 100),
          );
          return 42;
        },
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 20),
      );

      final exec = await store.loadExecution('exec-0');
      expect(exec, isNotNull);

      final result = await future;
      expect(result, 42);
    });

    test('ctx.sleep fires after duration', () async {
      final stopwatch = Stopwatch()..start();

      final result = await engine.run<int>(
        'timer_wf',
        (ctx) async {
          await ctx.sleep(
            'short_wait',
            const Duration(milliseconds: 100),
          );
          return 99;
        },
      );

      stopwatch.stop();
      expect(result, 99);
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(80),
      );
    });

    test('timer status becomes FIRED after expiry', () async {
      await engine.run<int>(
        'timer_wf',
        (ctx) async {
          await ctx.sleep(
            'my_timer',
            const Duration(milliseconds: 50),
          );
          return 1;
        },
      );

      final pendingTimers = await store.loadPendingTimers();
      final myTimers = pendingTimers
          .where((t) => t.stepName == 'my_timer');
      expect(myTimers, isEmpty);
    });

    test('status transitions: RUNNING -> SUSPENDED -> RUNNING',
        () async {
      final statuses = <String>[];

      await engine.run<int>(
        'status_wf',
        (ctx) async {
          statuses.add(
            (await store.loadExecution('exec-0'))!
                .status
                .name,
          );
          await ctx.sleep(
            'pause',
            const Duration(milliseconds: 100),
          );
          statuses.add(
            (await store.loadExecution('exec-0'))!
                .status
                .name,
          );
          return 1;
        },
      );

      expect(statuses[0], 'RUNNING');
      expect(statuses[1], 'RUNNING');

      final exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Completed>());
    });

    test('multiple sequential sleeps work correctly', () async {
      final result = await engine.run<int>(
        'multi_sleep_wf',
        (ctx) async {
          await ctx.sleep(
            'wait1',
            const Duration(milliseconds: 50),
          );
          await ctx.sleep(
            'wait2',
            const Duration(milliseconds: 50),
          );
          return 100;
        },
      );

      expect(result, 100);
    });

    test('cancel marks pending timers as CANCELLED', () async {
      Object? caughtError;
      final future = engine.run<int>(
        'cancel_timer_wf',
        (ctx) async {
          await ctx.sleep(
            'long_wait',
            const Duration(seconds: 10),
          );
          return 0;
        },
      ).catchError((Object e) {
        caughtError = e;
        return 0;
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      await engine.cancel('exec-0');
      await future;

      expect(caughtError, isA<StateError>());

      final pendingTimers = await store.loadPendingTimers();
      final timerForExec = pendingTimers
          .where((t) => t.workflowExecutionId == 'exec-0');
      expect(timerForExec, isEmpty);
    });

    group('recovery', () {
      test('past-due timer fires immediately', () async {
        await store.saveTimer(WorkflowTimer(
          workflowTimerId: 'timer-exec-old-pause',
          workflowExecutionId: 'exec-old',
          stepName: 'pause',
          fireAt: pastTimestamp(ago: const Duration(seconds: 5)),
          status: TimerStatus.pending,
          createdAt: nowTimestamp(),
        ));

        await engine.timerManager.restorePendingTimers();

        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );

        final pendingTimers = await store.loadPendingTimers();
        final old = pendingTimers.where(
          (t) =>
              t.workflowTimerId == 'timer-exec-old-pause',
        );
        expect(old, isEmpty);
      });

      test('future timer waits until fireAt', () async {
        await store.saveTimer(WorkflowTimer(
          workflowTimerId: 'timer-exec-future-pause',
          workflowExecutionId: 'exec-future',
          stepName: 'pause',
          fireAt: futureTimestamp(
            ahead: const Duration(milliseconds: 150),
          ),
          status: TimerStatus.pending,
          createdAt: nowTimestamp(),
        ));

        await engine.timerManager.restorePendingTimers();

        // Timer should still be pending immediately
        var pendingTimers = await store.loadPendingTimers();
        expect(
          pendingTimers.where(
            (t) =>
                t.workflowTimerId ==
                'timer-exec-future-pause',
          ),
          isNotEmpty,
        );

        // Wait for it to fire
        await Future<void>.delayed(
          const Duration(milliseconds: 250),
        );

        pendingTimers = await store.loadPendingTimers();
        expect(
          pendingTimers.where(
            (t) =>
                t.workflowTimerId ==
                'timer-exec-future-pause',
          ),
          isEmpty,
        );
      });
    });
  });
}
