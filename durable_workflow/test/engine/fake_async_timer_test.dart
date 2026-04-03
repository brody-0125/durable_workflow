@Tags(['unit'])
library;

import 'package:durable_workflow/testing.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

/// Resolves a [Future] synchronously within a [FakeAsync] context.
///
/// Flushes microtasks so the future completes, then returns the value.
/// Throws if the callback never executed (indicating the future didn't resolve).
T resolveSync<T>(FakeAsync async, Future<T> future) {
  late T result;
  var resolved = false;
  future.then((v) {
    result = v;
    resolved = true;
  });
  async.flushMicrotasks();
  if (!resolved) {
    throw StateError('Future did not resolve after flushMicrotasks');
  }
  return result;
}

void main() {
  group('TimerManager with fake_async', () {
    test('past-due timer fires immediately when time advances', () {
      fakeAsync((async) {
        final store = InMemoryCheckpointStore();
        final engine = createTestEngine(store);

        resolveSync(async, store.saveTimer(createTestTimer(
          'timer-past',
          'exec-0',
          stepName: 'pause',
          fireAt: pastTimestamp(ago: const Duration(seconds: 5)),
        )));

        engine.timerManager.restorePendingTimers();
        async.elapse(const Duration(milliseconds: 200));

        final timers = resolveSync(async, store.loadPendingTimers());
        final pastTimer = timers.where(
          (t) => t.workflowTimerId == 'timer-past',
        );
        expect(pastTimer, isEmpty,
            reason: 'Past-due timer should have fired');

        engine.dispose();
      });
    });

    test('periodic poller fires after configured interval', () {
      fakeAsync((async) {
        final store = InMemoryCheckpointStore();
        final engine = createTestEngine(
          store,
          timerPollInterval: const Duration(milliseconds: 100),
        );

        // Save a future timer so it's not fired immediately by restorePendingTimers
        resolveSync(async, store.saveTimer(createTestTimer(
          'timer-poll',
          'exec-0',
          stepName: 'poll-step',
          fireAt: futureTimestamp(ahead: const Duration(milliseconds: 80)),
        )));

        // restorePendingTimers loads from store and registers completers
        resolveSync(async, engine.timerManager.restorePendingTimers());

        // Before fireAt — timer should still be pending
        async.elapse(const Duration(milliseconds: 50));
        var timers = resolveSync(async, store.loadPendingTimers());
        expect(
          timers.any((t) => t.workflowTimerId == 'timer-poll'),
          isTrue,
          reason: 'Timer should be pending before fireAt',
        );

        // After fireAt — poller should have fired it
        async.elapse(const Duration(milliseconds: 100));
        timers = resolveSync(async, store.loadPendingTimers());
        expect(
          timers.any((t) => t.workflowTimerId == 'timer-poll'),
          isFalse,
          reason: 'Timer should have fired after fireAt',
        );

        engine.dispose();
      });
    });

    test('multiple timers fire in order when time elapses', () {
      fakeAsync((async) {
        final store = InMemoryCheckpointStore();
        final engine = createTestEngine(store);
        final now = DateTime.now().toUtc();

        resolveSync(async, store.saveTimer(createTestTimer(
          'timer-100',
          'exec-0',
          stepName: 'short',
          fireAt: now.add(const Duration(milliseconds: 100)).toIso8601String(),
        )));

        resolveSync(async, store.saveTimer(createTestTimer(
          'timer-500',
          'exec-0',
          stepName: 'long',
          fireAt: now.add(const Duration(milliseconds: 500)).toIso8601String(),
        )));

        engine.timerManager.restorePendingTimers();

        async.elapse(const Duration(milliseconds: 200));
        var timers = resolveSync(async, store.loadPendingTimers());
        expect(
          timers.any((t) => t.workflowTimerId == 'timer-100'),
          isFalse,
          reason: 'Short timer should have fired',
        );
        expect(
          timers.any((t) => t.workflowTimerId == 'timer-500'),
          isTrue,
          reason: 'Long timer should still be pending',
        );

        async.elapse(const Duration(milliseconds: 400));
        timers = resolveSync(async, store.loadPendingTimers());
        expect(
          timers.any((t) => t.workflowTimerId == 'timer-500'),
          isFalse,
          reason: 'Long timer should have fired',
        );

        engine.dispose();
      });
    });
  });
}
