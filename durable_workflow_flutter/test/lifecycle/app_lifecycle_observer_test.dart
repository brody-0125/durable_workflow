import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/tracking_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryCheckpointStore store;
  late DurableEngineImpl engine;
  late ForegroundRecovery recovery;
  late TrackingBackgroundAdapter adapter;

  setUp(() {
    store = InMemoryCheckpointStore();
    engine = DurableEngineImpl(store: store);
    recovery = ForegroundRecovery(
      engine: engine,
      registry: {},
      debounce: Duration.zero,
    );
    adapter = TrackingBackgroundAdapter();
  });

  tearDown(() {
    recovery.dispose();
    engine.dispose();
  });

  group('AppLifecycleObserver', () {
    test('register adds observer to binding', () {
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
      );

      observer.register();
      observer.unregister();
    });

    test('register is idempotent', () {
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
      );

      observer.register();
      observer.register(); // Should not throw
      observer.unregister();
    });

    test('unregister is idempotent', () {
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
      );

      observer.unregister(); // Not registered yet, should not throw
    });

    test('paused state schedules background recovery', () {
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(adapter.calls, contains('scheduleRecovery'));
    });

    test('onPaused callback is invoked', () {
      var paused = false;
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
        onPaused: () => paused = true,
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(paused, isTrue);
    });

    test('onResumed callback is invoked', () {
      var resumed = false;
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
        onResumed: () => resumed = true,
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(resumed, isTrue);
    });

    test('detached state does not self-dispose', () {
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
      );

      observer.register();
      observer.didChangeAppLifecycleState(AppLifecycleState.detached);
      // Should not self-dispose; the owning widget handles disposal.
      expect(adapter.calls, isEmpty);
    });

    test('dispose cancels background tasks and unregisters', () {
      final observer = AppLifecycleObserver(
        recovery: recovery,
        backgroundAdapter: adapter,
      );

      observer.register();
      observer.dispose();
      expect(adapter.calls, contains('cancelAll'));
    });
  });
}
