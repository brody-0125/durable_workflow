@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
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

  group('StepCheckpoint CRUD', () {
    test('round-trip save and load', () async {
      await store.saveCheckpoint(testCheckpoint(
        inputData: '{"order_id":"123"}',
        startedAt: kCreatedAt,
      ));

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(1));
      expect(loaded[0].stepName, equals('validate'));
      expect(loaded[0].status, equals(StepStatus.intent));
      expect(
        loaded[0].inputData,
        equals('{"order_id":"123"}'),
      );
      expect(loaded[0].id, isNotNull);
    });

    test('returns empty list when no checkpoints',
        () async {
      final result =
          await store.loadCheckpoints('exec-1');
      expect(result, isEmpty);
    });

    test('orders by stepIndex ascending', () async {
      await store.saveCheckpoint(testCheckpoint(
        stepIndex: 2,
        stepName: 'ship',
      ));
      await store.saveCheckpoint(testCheckpoint(
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.completed,
      ));
      await store.saveCheckpoint(testCheckpoint(
        stepIndex: 1,
        stepName: 'pay',
        status: StepStatus.completed,
      ));

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(3));
      expect(loaded[0].stepIndex, equals(0));
      expect(loaded[1].stepIndex, equals(1));
      expect(loaded[2].stepIndex, equals(2));
    });

    test('upserts on conflict (same exec+step+attempt)',
        () async {
      await store.saveCheckpoint(testCheckpoint(
        startedAt: kCreatedAt,
      ));

      await store.saveCheckpoint(testCheckpoint(
        status: StepStatus.completed,
        outputData: '{"result":"ok"}',
        startedAt: kCreatedAt,
        completedAt: kLaterAt,
      ));

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(1));
      expect(
        loaded[0].status,
        equals(StepStatus.completed),
      );
      expect(
        loaded[0].outputData,
        equals('{"result":"ok"}'),
      );
    });

    test('all fields populated', () async {
      await store.saveCheckpoint(testCheckpoint(
        stepName: 'pay',
        status: StepStatus.failed,
        inputData: '{"amount":100}',
        errorMessage: 'Payment gateway timeout',
        attempt: 3,
        compensateRef: 'refund_payment',
        startedAt: kCreatedAt,
        completedAt: kLaterAt,
      ));

      final loaded = await store.loadCheckpoints('exec-1');
      expect(
        loaded[0].errorMessage,
        equals('Payment gateway timeout'),
      );
      expect(loaded[0].attempt, equals(3));
      expect(
        loaded[0].compensateRef,
        equals('refund_payment'),
      );
    });

    test('null optional fields persist correctly',
        () async {
      await store.saveCheckpoint(testCheckpoint(
        stepName: 'minimal',
      ));

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded[0].inputData, isNull);
      expect(loaded[0].outputData, isNull);
      expect(loaded[0].errorMessage, isNull);
      expect(loaded[0].compensateRef, isNull);
      expect(loaded[0].startedAt, isNull);
      expect(loaded[0].completedAt, isNull);
    });

    test('multiple attempts for the same step', () async {
      for (var attempt = 1; attempt <= 3; attempt++) {
        await store.saveCheckpoint(testCheckpoint(
          status: attempt < 3
              ? StepStatus.failed
              : StepStatus.completed,
          attempt: attempt,
        ));
      }

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded, hasLength(3));
      expect(loaded[0].attempt, equals(1));
      expect(loaded[1].attempt, equals(2));
      expect(loaded[2].attempt, equals(3));
    });

    test('all StepStatus values round-trip', () async {
      for (final (i, status) in [
        StepStatus.intent,
        StepStatus.completed,
        StepStatus.failed,
        StepStatus.compensated,
      ].indexed) {
        await store.saveCheckpoint(testCheckpoint(
          stepIndex: i,
          stepName: 'step_$i',
          status: status,
        ));
      }

      final loaded = await store.loadCheckpoints('exec-1');
      expect(loaded[0].status, equals(StepStatus.intent));
      expect(
        loaded[1].status,
        equals(StepStatus.completed),
      );
      expect(loaded[2].status, equals(StepStatus.failed));
      expect(
        loaded[3].status,
        equals(StepStatus.compensated),
      );
    });

    test('isolates checkpoints between executions',
        () async {
      await store.saveExecution(testExecution(
        id: 'exec-2',
      ));

      await store.saveCheckpoint(testCheckpoint(
        executionId: 'exec-1',
        stepName: 'step-a',
      ));
      await store.saveCheckpoint(testCheckpoint(
        executionId: 'exec-2',
        stepName: 'step-b',
      ));

      final loaded1 =
          await store.loadCheckpoints('exec-1');
      final loaded2 =
          await store.loadCheckpoints('exec-2');

      expect(loaded1, hasLength(1));
      expect(loaded1[0].stepName, equals('step-a'));
      expect(loaded2, hasLength(1));
      expect(loaded2[0].stepName, equals('step-b'));
    });
  });
}
