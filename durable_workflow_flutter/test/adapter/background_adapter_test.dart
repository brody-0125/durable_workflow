import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/tracking_adapter.dart';

void main() {
  group('NoopBackgroundAdapter', () {
    late NoopBackgroundAdapter adapter;

    setUp(() => adapter = NoopBackgroundAdapter());

    test('initialize completes without error', () async {
      await adapter.initialize();
    });

    test('scheduleRecovery completes without error', () async {
      await adapter.scheduleRecovery();
    });

    test('cancelAll completes without error', () async {
      await adapter.cancelAll();
    });

    test('dispose completes without error', () async {
      await adapter.dispose();
    });
  });

  group('BackgroundAdapter interface', () {
    test('tracking adapter records all calls', () async {
      final adapter = TrackingBackgroundAdapter();

      await adapter.initialize();
      await adapter.scheduleRecovery();
      await adapter.cancelAll();
      await adapter.dispose();

      expect(adapter.calls, [
        'initialize',
        'scheduleRecovery',
        'cancelAll',
        'dispose',
      ]);
    });

    test('tracking adapter implements BackgroundAdapter', () {
      final adapter = TrackingBackgroundAdapter();
      expect(adapter, isA<BackgroundAdapter>());
    });
  });
}
