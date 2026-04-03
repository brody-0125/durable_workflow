@Tags(['integration'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late SqliteCheckpointStore store;
  late DurableEngineImpl engine;

  setUp(() {
    store = createTestStore();
    engine = createIntegrationEngine(store);
  });

  tearDown(() {
    engine.dispose();
    store.close();
  });

  group('saga compensation', () {
    test('step 3 fails after retries -> reverse compensation',
        () async {
      final log = <String>[];
      final compensateLog = <String>[];
      var shipAttempts = 0;

      Object? caughtError;
      try {
        await engine.run<void>(
          'order_saga',
          (ctx) async {
            await ctx.step<bool>(
              'validate',
              () async {
                log.add('validate');
                return true;
              },
              compensate: (_) async {
                compensateLog.add('undo-validate');
              },
            );

            await ctx.step<String>(
              'pay',
              () async {
                log.add('pay');
                return 'PAY-001';
              },
              compensate: (_) async {
                compensateLog.add('undo-pay');
              },
            );

            await ctx.step<String>(
              'ship',
              () async {
                shipAttempts++;
                log.add('ship-attempt-$shipAttempts');
                throw Exception(
                  'Shipping service unavailable',
                );
              },
              retry: RetryPolicy.fixed(
                maxAttempts: 3,
                delay: Duration.zero,
              ),
              compensate: (_) async {
                compensateLog.add('undo-ship');
              },
            );
          },
        );
      } catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<Exception>());

      expect(log, [
        'validate',
        'pay',
        'ship-attempt-1',
        'ship-attempt-2',
        'ship-attempt-3',
      ]);

      // ship never COMPLETED, so only pay and validate
      // get compensated
      expect(
        compensateLog,
        ['undo-pay', 'undo-validate'],
      );

      final exec = await store.loadExecution('exec-0');
      expect(exec, isNotNull);
      expect(exec!.status, isA<Failed>());

      final checkpoints =
          await store.loadCheckpoints('exec-0');
      final compensated = checkpoints
          .where((cp) => cp.status == StepStatus.compensated)
          .toList();
      expect(compensated, hasLength(2));

      final compensatedNames =
          compensated.map((cp) => cp.stepName).toList();
      expect(
        compensatedNames,
        containsAll(
          ['pay:compensate', 'validate:compensate'],
        ),
      );
    });

    test('no compensation without compensate functions',
        () async {
      Object? caughtError;
      try {
        await engine.run<void>(
          'no_compensate',
          (ctx) async {
            await ctx.step<bool>(
              'step1',
              () async => true,
            );
            await ctx.step<String>('step2', () async {
              throw Exception('fail');
            });
          },
        );
      } catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<Exception>());

      final exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Failed>());

      final checkpoints =
          await store.loadCheckpoints('exec-0');
      final compensated = checkpoints
          .where((cp) => cp.status == StepStatus.compensated)
          .toList();
      expect(compensated, isEmpty);
    });
  });
}
