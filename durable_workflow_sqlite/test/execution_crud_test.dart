@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';
import 'helpers/store_setup.dart';

void main() {
  late SqliteCheckpointStore store;

  setUp(() async {
    store = await createSeededStore();
  });

  tearDown(() {
    store.close();
  });

  group('WorkflowExecution CRUD', () {
    test('round-trip save and load', () async {
      final execution = testExecution(
        inputData: '{"key":"value"}',
      );
      await store.saveExecution(execution);

      final loaded = await store.loadExecution('exec-1');
      expect(loaded, isNotNull);
      expect(loaded!.workflowExecutionId, equals('exec-1'));
      expect(loaded.workflowId, equals('wf-1'));
      expect(loaded.status, isA<Pending>());
      expect(loaded.currentStep, equals(0));
      expect(loaded.inputData, equals('{"key":"value"}'));
      expect(
        loaded.guarantee,
        equals(WorkflowGuarantee.foregroundOnly),
      );
    });

    test('returns null for non-existent ID', () async {
      final result =
          await store.loadExecution('non-existent');
      expect(result, isNull);
    });

    test('upserts on conflict', () async {
      await store.saveExecution(testExecution());
      await store.saveExecution(testExecution(
        status: const Running(),
        currentStep: 2,
        updatedAt: kLaterAt,
      ));

      final loaded = await store.loadExecution('exec-1');
      expect(loaded, isNotNull);
      expect(loaded!.status, isA<Running>());
      expect(loaded.currentStep, equals(2));
    });

    test('preserves all 7 status values', () async {
      final statuses = <ExecutionStatus>[
        const Pending(),
        const Running(),
        const Suspended(),
        const Completed(),
        const Failed(),
        const Compensating(),
        const Cancelled(),
      ];

      for (final status in statuses) {
        final id = 'exec-${status.name}';
        await store.saveExecution(
          testExecution(id: id, status: status),
        );
        final loaded = await store.loadExecution(id);
        expect(loaded, isNotNull);
        expect(loaded!.status.name, equals(status.name));
      }
    });

    test('all optional fields round-trip', () async {
      final execution = testExecution(
        id: 'exec-full',
        status: const Completed(),
        currentStep: 5,
        inputData: '{"in":"data"}',
        outputData: '{"out":"result"}',
        ttlExpiresAt: '2026-04-25T10:00:00.000',
        guarantee: WorkflowGuarantee.bestEffortBackground,
        updatedAt: kLaterAt,
      );
      await store.saveExecution(execution);

      final loaded = await store.loadExecution('exec-full');
      expect(loaded, isNotNull);
      expect(
        loaded!.outputData,
        equals('{"out":"result"}'),
      );
      expect(
        loaded.ttlExpiresAt,
        equals('2026-04-25T10:00:00.000'),
      );
      expect(
        loaded.guarantee,
        equals(WorkflowGuarantee.bestEffortBackground),
      );
    });

    test('execution with error message', () async {
      await store.saveExecution(testExecution(
        id: 'exec-fail',
        status: const Failed(),
        errorMessage: 'Something went wrong',
      ));

      final loaded = await store.loadExecution('exec-fail');
      expect(loaded, isNotNull);
      expect(loaded!.status, isA<Failed>());
      expect(
        loaded.errorMessage,
        equals('Something went wrong'),
      );
    });

    test('FK constraint rejects orphan execution', () {
      expect(
        () => store.saveExecution(testExecution(
          id: 'orphan',
          workflowId: 'non-existent-wf',
        )),
        throwsA(isA<SqliteException>()),
      );
    });

    test('multiple executions for same workflow', () async {
      for (var i = 0; i < 3; i++) {
        await store.saveExecution(
          testExecution(id: 'exec-multi-$i'),
        );
      }

      for (var i = 0; i < 3; i++) {
        final loaded =
            await store.loadExecution('exec-multi-$i');
        expect(loaded, isNotNull);
      }
    });
  });

  // Use a separate store without a seeded execution so
  // loadExecutionsByStatus tests have full control over data.
  group('loadExecutionsByStatus', () {
    late SqliteCheckpointStore cleanStore;

    setUp(() async {
      cleanStore = SqliteCheckpointStore.inMemory();
      await cleanStore.saveWorkflow(testWorkflow());
    });

    tearDown(() {
      cleanStore.close();
    });

    test('returns empty list for empty statuses', () async {
      final result =
          await cleanStore.loadExecutionsByStatus([]);
      expect(result, isEmpty);
    });

    test('filters by single status', () async {
      await cleanStore.saveExecution(
        testExecution(
          id: 'e-run',
          status: const Running(),
        ),
      );
      await cleanStore.saveExecution(
        testExecution(
          id: 'e-done',
          status: const Completed(),
        ),
      );

      final running =
          await cleanStore.loadExecutionsByStatus(
        [const Running()],
      );
      expect(running, hasLength(1));
      expect(
        running.first.workflowExecutionId,
        equals('e-run'),
      );
    });

    test('filters by multiple statuses', () async {
      await cleanStore.saveExecution(
        testExecution(
          id: 'e-pending',
          status: const Pending(),
        ),
      );
      await cleanStore.saveExecution(
        testExecution(
          id: 'e-running',
          status: const Running(),
          createdAt: kLaterAt,
        ),
      );
      await cleanStore.saveExecution(
        testExecution(
          id: 'e-done',
          status: const Completed(),
        ),
      );

      final recoverable =
          await cleanStore.loadExecutionsByStatus([
        const Pending(),
        const Running(),
      ]);
      expect(recoverable, hasLength(2));
    });

    test('orders by createdAt ascending', () async {
      await cleanStore.saveExecution(testExecution(
        id: 'e-late',
        status: const Running(),
        createdAt: '2026-03-25T12:00:00.000',
      ));
      await cleanStore.saveExecution(testExecution(
        id: 'e-early',
        status: const Running(),
        createdAt: '2026-03-25T08:00:00.000',
      ));

      final results =
          await cleanStore.loadExecutionsByStatus(
        [const Running()],
      );
      expect(results, hasLength(2));
      expect(
        results[0].workflowExecutionId,
        equals('e-early'),
      );
      expect(
        results[1].workflowExecutionId,
        equals('e-late'),
      );
    });

    test('returns empty when no executions match',
        () async {
      await cleanStore.saveExecution(
        testExecution(status: const Completed()),
      );

      final result =
          await cleanStore.loadExecutionsByStatus(
        [const Failed()],
      );
      expect(result, isEmpty);
    });
  });
}
