@Tags(['integration'])
library;

import 'dart:async';

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late SqliteCheckpointStore store;
  late DurableEngineImpl engine;

  setUp(() {
    store = createTestStore();
    engine = createIntegrationEngine(
      store,
      timerPollInterval: const Duration(milliseconds: 20),
    );
  });

  tearDown(() {
    engine.dispose();
    store.close();
  });

  group('timer (sleep)', () {
    test('ctx.sleep suspends then resumes after duration',
        () async {
      final log = <String>[];

      final result = await engine.run<String>(
        'timer_workflow',
        (ctx) async {
          log.add('before-sleep');
          await ctx.sleep(
            'wait',
            const Duration(milliseconds: 100),
          );
          log.add('after-sleep');
          return 'done';
        },
      );

      expect(result, 'done');
      expect(log, ['before-sleep', 'after-sleep']);

      final exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Completed>());
    });
  });

  group('signal (waitSignal + sendSignal)', () {
    test('waitSignal suspends, sendSignal resumes', () async {
      final log = <String>[];

      final workflowFuture = engine.run<String>(
        'signal_workflow',
        (ctx) async {
          log.add('before-wait');
          final payload =
              await ctx.waitSignal<String>('approval');
          log.add('after-wait: $payload');
          return 'approved';
        },
      );

      await waitForStatus<Suspended>(store, 'exec-0');

      var exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Suspended>());

      await engine.sendSignal(
        'exec-0',
        'approval',
        'manager-ok',
      );

      final result = await workflowFuture;
      expect(result, 'approved');
      expect(log, ['before-wait', 'after-wait: manager-ok']);

      exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Completed>());
    });

    test('waitSignal timeout throws TimeoutException',
        () async {
      expect(
        () => engine.run<void>(
          'timeout_workflow',
          (ctx) async {
            await ctx.waitSignal<String>(
              'never_arrives',
              timeout: const Duration(milliseconds: 100),
            );
          },
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
