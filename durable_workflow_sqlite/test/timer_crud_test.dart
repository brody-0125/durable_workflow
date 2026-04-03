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

  group('WorkflowTimer CRUD', () {
    test('round-trip save and load', () async {
      await store.saveTimer(testTimer());

      final loaded = await store.loadPendingTimers();
      expect(loaded, hasLength(1));
      expect(
        loaded[0].workflowTimerId,
        equals('timer-1'),
      );
      expect(
        loaded[0].stepName,
        equals('await_shipping'),
      );
      expect(
        loaded[0].status,
        equals(TimerStatus.pending),
      );
    });

    test('excludes fired and cancelled timers', () async {
      await store.saveTimer(
        testTimer(id: 'timer-pending'),
      );
      await store.saveTimer(testTimer(
        id: 'timer-fired',
        stepName: 'step2',
        status: TimerStatus.fired,
      ));
      await store.saveTimer(testTimer(
        id: 'timer-cancelled',
        stepName: 'step3',
        status: TimerStatus.cancelled,
      ));

      final loaded = await store.loadPendingTimers();
      expect(loaded, hasLength(1));
      expect(
        loaded[0].workflowTimerId,
        equals('timer-pending'),
      );
    });

    test('includes future timers', () async {
      await store.saveTimer(testTimer(
        id: 'timer-future',
        fireAt: '2099-12-31T23:59:59.000',
      ));

      final loaded = await store.loadPendingTimers();
      expect(loaded, hasLength(1));
      expect(
        loaded[0].workflowTimerId,
        equals('timer-future'),
      );
    });

    test('upserts on conflict', () async {
      await store.saveTimer(testTimer());

      await store.saveTimer(testTimer(
        status: TimerStatus.fired,
      ));

      final loaded = await store.loadPendingTimers();
      expect(loaded, isEmpty);
    });

    test('orders by fireAt ascending', () async {
      await store.saveTimer(testTimer(
        id: 'timer-late',
        fireAt: '2026-01-02T00:00:00.000',
      ));
      await store.saveTimer(testTimer(
        id: 'timer-early',
        fireAt: '2020-01-01T00:00:00.000',
        stepName: 'step2',
      ));

      final loaded = await store.loadPendingTimers();
      expect(loaded, hasLength(2));
      expect(
        loaded[0].workflowTimerId,
        equals('timer-early'),
      );
      expect(
        loaded[1].workflowTimerId,
        equals('timer-late'),
      );
    });

    test('all TimerStatus values round-trip', () async {
      for (final status in TimerStatus.values) {
        await store.saveTimer(testTimer(
          id: 'timer-${status.name}',
          stepName: 'step-${status.name}',
          status: status,
        ));
      }

      final result = store.database.select(
        'SELECT status FROM workflow_timers '
        'ORDER BY workflow_timer_id',
      );
      final statuses = result
          .map((r) => r['status'] as String)
          .toList();
      expect(
        statuses,
        unorderedEquals(['CANCELLED', 'FIRED', 'PENDING']),
      );
    });
  });
}
