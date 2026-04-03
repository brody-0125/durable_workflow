@Tags(['integration'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late SqliteCheckpointStore store;

  setUp(() {
    store = createTestStore();
  });

  tearDown(() {
    store.close();
  });

  group('crash recovery', () {
    test('replays completed steps and executes remaining',
        () async {
      final executionLog = <String>[];
      final executionId = 'exec-0';

      // Phase 1: Run engine, complete steps 1 and 2
      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      Future<String> workflowBody(WorkflowContext ctx) async {
        await ctx.step<bool>('validate', () async {
          executionLog.add('validate');
          return true;
        });
        await ctx.step<String>('pay', () async {
          executionLog.add('pay');
          return 'PAY-001';
        });
        final tracking =
            await ctx.step<String>('ship', () async {
          executionLog.add('ship');
          return 'TRACK-001';
        });
        return tracking;
      }

      // Run modified body that returns early (simulates crash
      // before step 3)
      await engine.run<String>(
        'order_processing',
        (ctx) async {
          await ctx.step<bool>('validate', () async {
            executionLog.add('validate');
            return true;
          });
          await ctx.step<String>('pay', () async {
            executionLog.add('pay');
            return 'PAY-001';
          });
          return 'incomplete';
        },
      );

      await simulateCrash(store, executionId);
      engine.dispose();
      executionLog.clear();

      // Phase 2: New engine instance, recovery scan
      engine = createIntegrationEngine(
        store,
        generateId: () => 'exec-should-not-be-used',
      );

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final scanResult = await scanner.scan(
        workflowRegistry: {
          'order_processing': workflowBody,
        },
      );

      expect(scanResult.resumed, contains(executionId));
      expect(scanResult.expired, isEmpty);

      // Steps 1 and 2 replayed (skipped), only step 3 executes
      expect(executionLog, ['ship']);

      final finalExec =
          await store.loadExecution(executionId);
      expect(finalExec, isNotNull);
      expect(finalExec!.status, isA<Completed>());

      final checkpoints =
          await store.loadCheckpoints(executionId);
      final completedSteps = checkpoints
          .where((cp) => cp.status == StepStatus.completed)
          .toList();
      expect(completedSteps, hasLength(3));

      engine.dispose();
    });

    test('no interrupted executions returns empty result',
        () async {
      final engine = createIntegrationEngine(store);

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result =
          await scanner.scan(workflowRegistry: {});
      expect(result.resumed, isEmpty);
      expect(result.expired, isEmpty);

      engine.dispose();
    });
  });
}
