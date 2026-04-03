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

  group('TTL expiry', () {
    test('recovery marks TTL-expired execution as FAILED',
        () async {
      final executionId = 'exec-0';

      // Phase 1: Run workflow with ttl=Duration.zero
      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      await engine.run<void>(
        'ttl_test',
        (ctx) async {
          await ctx.step<bool>('step1', () async => true);
        },
        ttl: Duration.zero,
      );

      await simulateCrash(store, executionId);
      engine.dispose();

      await Future<void>.delayed(
        const Duration(milliseconds: 10),
      );

      // Phase 2: New engine + recovery scan
      engine = createIntegrationEngine(store);

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );
      final result = await scanner.scan(workflowRegistry: {
        'ttl_test': (ctx) async {
          await ctx.step<bool>('step1', () async => true);
        },
      });

      expect(result.expired, contains(executionId));
      expect(result.resumed, isEmpty);

      final finalExec =
          await store.loadExecution(executionId);
      expect(finalExec!.status, isA<Failed>());
      expect(
        finalExec.errorMessage,
        contains('TTL expired'),
      );

      engine.dispose();
    });
  });
}
