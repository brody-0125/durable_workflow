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

  group('full workflow', () {
    test('3-step happy path: validate -> pay -> ship',
        () async {
      final log = <String>[];

      final result = await engine.run<String>(
        'order_processing',
        (ctx) async {
          final valid = await ctx.step<bool>(
            'validate',
            () async {
              log.add('validate');
              return true;
            },
          );
          expect(valid, isTrue);

          final paymentId = await ctx.step<String>(
            'pay',
            () async {
              log.add('pay');
              return 'PAY-001';
            },
          );
          expect(paymentId, 'PAY-001');

          final trackingId = await ctx.step<String>(
            'ship',
            () async {
              log.add('ship');
              return 'TRACK-001';
            },
          );
          return trackingId;
        },
      );

      expect(result, 'TRACK-001');
      expect(log, ['validate', 'pay', 'ship']);

      final checkpoints =
          await store.loadCheckpoints('exec-0');
      final completedCps = checkpoints
          .where((cp) => cp.status == StepStatus.completed)
          .toList();
      expect(completedCps, hasLength(3));
      expect(completedCps[0].stepName, 'validate');
      expect(completedCps[1].stepName, 'pay');
      expect(completedCps[2].stepName, 'ship');

      final execution =
          await store.loadExecution('exec-0');
      expect(execution, isNotNull);
      expect(execution!.status, isA<Completed>());
    });

    test('step results persist in DB', () async {
      await engine.run<void>(
        'data_pipeline',
        (ctx) async {
          await ctx.step<int>(
            'extract',
            () async => 42,
          );
          await ctx.step<String>(
            'transform',
            () async => 'transformed',
          );
          await ctx.step<bool>(
            'load',
            () async => true,
          );
        },
      );

      final checkpoints =
          await store.loadCheckpoints('exec-0');
      final completed = checkpoints
          .where((cp) => cp.status == StepStatus.completed)
          .toList();
      expect(completed, hasLength(3));
      expect(completed[0].outputData, '42');
      expect(completed[1].outputData, '"transformed"');
      expect(completed[2].outputData, 'true');
    });

    test('observe emits RUNNING then COMPLETED', () async {
      final states = <ExecutionStatus>[];
      final subscription =
          engine.observe('exec-0').listen((exec) {
        states.add(exec.status);
      });

      await engine.run<void>(
        'simple',
        (ctx) async {
          await ctx.step<int>('step1', () async => 1);
        },
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
      await subscription.cancel();

      expect(states, contains(isA<Running>()));
      expect(states, contains(isA<Completed>()));
    });
  });
}
