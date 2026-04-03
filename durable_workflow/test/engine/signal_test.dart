@Tags(['unit'])
library;

import 'dart:async';

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

  group('SignalManager', () {
    test('waitSignal suspends and sendSignal resumes', () async {
      final future = engine.run<String>(
        'signal_wf',
        (ctx) async {
          final data =
              await ctx.waitSignal<String>('approval');
          return data ?? 'none';
        },
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      final exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Suspended>());

      await engine.sendSignal('exec-0', 'approval', 'approved');

      final result = await future;
      expect(result, 'approved');

      final finalExec = await store.loadExecution('exec-0');
      expect(finalExec!.status, isA<Completed>());
    });

    test('waitSignal with timeout throws WorkflowTimeoutException',
        () async {
      await expectLater(
        engine.run<String>(
          'timeout_wf',
          (ctx) async {
            final data = await ctx.waitSignal<String>(
              'never_comes',
              timeout: const Duration(milliseconds: 100),
            );
            return data ?? 'none';
          },
        ),
        throwsA(isA<WorkflowTimeoutException>()),
      );
    });

    test('signal timeout marks signal as EXPIRED', () async {
      try {
        await engine.run<String>(
          'timeout_wf',
          (ctx) async {
            final data = await ctx.waitSignal<String>(
              'expiring_signal',
              timeout: const Duration(milliseconds: 100),
            );
            return data ?? 'none';
          },
        );
      } catch (_) {
        // Expected timeout
      }

      final signals = await store.loadPendingSignals(
        'exec-0',
        signalName: 'expiring_signal',
      );
      expect(signals, isEmpty);
    });

    test('pre-sent signal is consumed immediately', () async {
      await engine.sendSignal(
        'exec-0',
        'pre_sent',
        'early_data',
      );

      final result = await engine.run<String>(
        'pre_signal_wf',
        (ctx) async {
          final data =
              await ctx.waitSignal<String>('pre_sent');
          return data ?? 'none';
        },
      );

      expect(result, 'early_data');
    });

    test('sendSignal without waiter stores PENDING signal',
        () async {
      await engine.sendSignal(
        'exec-999',
        'orphan_signal',
        'data',
      );

      final signals = await store.loadPendingSignals(
        'exec-999',
        signalName: 'orphan_signal',
      );
      expect(signals, hasLength(1));
      expect(signals[0].status, SignalStatus.pending);
    });

    test('cancel marks pending signals as EXPIRED', () async {
      Object? caughtError;
      final future = engine.run<String>(
        'cancel_signal_wf',
        (ctx) async {
          final data =
              await ctx.waitSignal<String>('my_signal');
          return data ?? 'none';
        },
      ).catchError((Object e) {
        caughtError = e;
        return '';
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      await engine.cancel('exec-0');
      await future;

      expect(caughtError, isA<StateError>());

      final signals = await store.loadPendingSignals(
        'exec-0',
        signalName: 'my_signal',
      );
      expect(signals, isEmpty);
    });

    test('status: RUNNING -> SUSPENDED -> RUNNING -> COMPLETED',
        () async {
      final future = engine.run<String>(
        'status_signal_wf',
        (ctx) async {
          final data =
              await ctx.waitSignal<String>('status_sig');
          return data ?? 'none';
        },
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      var exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Suspended>());

      await engine.sendSignal('exec-0', 'status_sig', 'go');

      await future;

      exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Completed>());
    });

    test('signal with null payload returns null', () async {
      final future = engine.run<String>(
        'null_payload_wf',
        (ctx) async {
          final data =
              await ctx.waitSignal<String>('null_sig');
          return data ?? 'default';
        },
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      await engine.sendSignal('exec-0', 'null_sig');

      final result = await future;
      expect(result, 'default');
    });

    test('recovery: pending signal can be restored and delivered',
        () async {
      await store.saveSignal(WorkflowSignal(
        workflowExecutionId: 'exec-recovered',
        signalName: 'recovery_sig',
        status: SignalStatus.pending,
        createdAt: nowTimestamp(),
      ));

      await engine.signalManager
          .restorePendingSignals('exec-recovered');

      await engine.signalManager.deliverSignal(
        workflowExecutionId: 'exec-recovered',
        signalName: 'recovery_sig',
        payload: 'recovered_data',
      );

      final signals = await store.loadPendingSignals(
        'exec-recovered',
        signalName: 'recovery_sig',
      );
      expect(signals, isEmpty);
    });

    test('multiple signals to different workflows', () async {
      final future1 = engine.run<String>(
        'wf1',
        (ctx) async {
          final data = await ctx.waitSignal<String>('sig');
          return 'wf1:${data ?? "none"}';
        },
      );

      final future2 = engine.run<String>(
        'wf2',
        (ctx) async {
          final data = await ctx.waitSignal<String>('sig');
          return 'wf2:${data ?? "none"}';
        },
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      await engine.sendSignal('exec-0', 'sig', 'a');
      await engine.sendSignal('exec-1', 'sig', 'b');

      final result1 = await future1;
      final result2 = await future2;

      expect(result1, 'wf1:a');
      expect(result2, 'wf2:b');
    });
  });
}
