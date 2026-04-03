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

  group('WorkflowSignal CRUD', () {
    test('round-trip save and load', () async {
      await store.saveSignal(testSignal(
        payload: '{"confirmed":true}',
      ));

      final loaded =
          await store.loadPendingSignals('exec-1');
      expect(loaded, hasLength(1));
      expect(
        loaded[0].signalName,
        equals('delivery_confirmed'),
      );
      expect(
        loaded[0].payload,
        equals('{"confirmed":true}'),
      );
      expect(loaded[0].workflowSignalId, isNotNull);
    });

    test('filters by signalName', () async {
      await store.saveSignal(testSignal(
        signalName: 'signal_a',
      ));
      await store.saveSignal(testSignal(
        signalName: 'signal_b',
        createdAt: kLaterAt,
      ));

      final loaded = await store.loadPendingSignals(
        'exec-1',
        signalName: 'signal_a',
      );
      expect(loaded, hasLength(1));
      expect(loaded[0].signalName, equals('signal_a'));
    });

    test('excludes delivered and expired', () async {
      await store.saveSignal(testSignal(
        signalName: 'sig_pending',
      ));
      await store.saveSignal(testSignal(
        signalName: 'sig_delivered',
        status: SignalStatus.delivered,
      ));
      await store.saveSignal(testSignal(
        signalName: 'sig_expired',
        status: SignalStatus.expired,
      ));

      final loaded =
          await store.loadPendingSignals('exec-1');
      expect(loaded, hasLength(1));
      expect(
        loaded[0].signalName,
        equals('sig_pending'),
      );
    });

    test('returns empty for non-existent execution',
        () async {
      final loaded =
          await store.loadPendingSignals('non-existent');
      expect(loaded, isEmpty);
    });

    test('null payload persists correctly', () async {
      await store.saveSignal(testSignal(
        signalName: 'no_payload',
        payload: null,
      ));

      final loaded =
          await store.loadPendingSignals('exec-1');
      expect(loaded[0].payload, isNull);
    });

    test('orders by createdAt ascending', () async {
      await store.saveSignal(testSignal(
        signalName: 'late',
        createdAt: '2026-03-25T12:00:00.000',
      ));
      await store.saveSignal(testSignal(
        signalName: 'early',
        createdAt: '2026-03-25T08:00:00.000',
      ));

      final loaded =
          await store.loadPendingSignals('exec-1');
      expect(loaded, hasLength(2));
      expect(loaded[0].signalName, equals('early'));
      expect(loaded[1].signalName, equals('late'));
    });

    test('all SignalStatus values round-trip', () async {
      for (final status in SignalStatus.values) {
        await store.saveSignal(testSignal(
          signalName: 'sig_${status.name}',
          status: status,
        ));
      }

      final result = store.database.select(
        'SELECT status FROM workflow_signals '
        'ORDER BY signal_name',
      );
      final statuses = result
          .map((r) => r['status'] as String)
          .toList();
      expect(
        statuses,
        unorderedEquals(['DELIVERED', 'EXPIRED', 'PENDING']),
      );
    });

    test('multiple signals with same name coexist',
        () async {
      for (var i = 0; i < 3; i++) {
        await store.saveSignal(testSignal(
          signalName: 'repeat',
          payload: '{"i":$i}',
          createdAt: '2026-03-25T10:0$i:00.000',
        ));
      }

      final loaded = await store.loadPendingSignals(
        'exec-1',
        signalName: 'repeat',
      );
      expect(loaded, hasLength(3));
    });
  });
}
