@Tags(['unit'])
library;

import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late SqliteCheckpointStore store;

  setUp(() {
    store = SqliteCheckpointStore.inMemory();
  });

  tearDown(() {
    store.close();
  });

  group('Workflow CRUD', () {
    test('round-trip save and load', () async {
      final workflow = testWorkflow(
        id: 'wf-1',
        type: 'order_processing',
      );
      await store.saveWorkflow(workflow);

      final loaded = await store.loadWorkflow('wf-1');
      expect(loaded, isNotNull);
      expect(loaded!.workflowId, equals('wf-1'));
      expect(
        loaded.workflowType,
        equals('order_processing'),
      );
      expect(loaded.version, equals(1));
    });

    test('returns null for non-existent ID', () async {
      final result =
          await store.loadWorkflow('non-existent');
      expect(result, isNull);
    });

    test('upserts on conflict (INSERT OR REPLACE)',
        () async {
      await store.saveWorkflow(
        testWorkflow(id: 'wf-1', type: 'v1'),
      );
      await store.saveWorkflow(
        testWorkflow(id: 'wf-1', type: 'v2', version: 2),
      );

      final loaded = await store.loadWorkflow('wf-1');
      expect(loaded, isNotNull);
      expect(loaded!.workflowType, equals('v2'));
      expect(loaded.version, equals(2));
    });

    test('stores multiple distinct workflows', () async {
      for (var i = 0; i < 3; i++) {
        await store.saveWorkflow(
          testWorkflow(id: 'wf-$i', type: 'type-$i'),
        );
      }

      for (var i = 0; i < 3; i++) {
        final loaded = await store.loadWorkflow('wf-$i');
        expect(loaded, isNotNull);
        expect(loaded!.workflowType, equals('type-$i'));
      }
    });
  });
}
