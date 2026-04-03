@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/internals.dart';
import 'package:durable_workflow/testing.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('RetryExecutor', () {
    group('shouldRetry', () {
      test('returns false for RetryPolicy.none', () {
        final executor = RetryExecutor();
        expect(
          executor.shouldRetry(RetryPolicy.none, 1),
          isFalse,
        );
      });

      test('returns true for fixed when under maxAttempts', () {
        final executor = RetryExecutor();
        final policy = RetryPolicy.fixed(
          maxAttempts: 3,
          delay: const Duration(seconds: 1),
        );
        expect(executor.shouldRetry(policy, 1), isTrue);
        expect(executor.shouldRetry(policy, 2), isTrue);
        expect(executor.shouldRetry(policy, 3), isFalse);
      });

      test('returns true for exponential when under maxAttempts',
          () {
        final executor = RetryExecutor();
        final policy = RetryPolicy.exponential(
          maxAttempts: 4,
          initialDelay: const Duration(seconds: 1),
        );
        expect(executor.shouldRetry(policy, 1), isTrue);
        expect(executor.shouldRetry(policy, 3), isTrue);
        expect(executor.shouldRetry(policy, 4), isFalse);
      });
    });

    group('calculateDelay', () {
      test('returns zero for none policy', () {
        final executor = RetryExecutor();
        expect(
          executor.calculateDelay(RetryPolicy.none, 1),
          Duration.zero,
        );
      });

      test('returns constant delay for fixed policy', () {
        final executor = RetryExecutor();
        final policy = RetryPolicy.fixed(
          maxAttempts: 3,
          delay: const Duration(milliseconds: 500),
        );
        expect(
          executor.calculateDelay(policy, 1),
          const Duration(milliseconds: 500),
        );
        expect(
          executor.calculateDelay(policy, 2),
          const Duration(milliseconds: 500),
        );
      });

      test('calculates exponential backoff', () {
        final executor = RetryExecutor();
        final policy = RetryPolicy.exponential(
          maxAttempts: 5,
          initialDelay: const Duration(milliseconds: 100),
          multiplier: 2.0,
          maxDelay: const Duration(seconds: 10),
          jitter: 0.0,
        );

        expect(
          executor.calculateDelay(policy, 1),
          const Duration(milliseconds: 100),
        );
        expect(
          executor.calculateDelay(policy, 2),
          const Duration(milliseconds: 200),
        );
        expect(
          executor.calculateDelay(policy, 3),
          const Duration(milliseconds: 400),
        );
        expect(
          executor.calculateDelay(policy, 4),
          const Duration(milliseconds: 800),
        );
      });

      test('caps delay at maxDelay', () {
        final executor = RetryExecutor();
        final policy = RetryPolicy.exponential(
          maxAttempts: 10,
          initialDelay: const Duration(milliseconds: 100),
          multiplier: 10.0,
          maxDelay: const Duration(milliseconds: 500),
          jitter: 0.0,
        );

        expect(
          executor.calculateDelay(policy, 3),
          const Duration(milliseconds: 500),
        );
      });

      test('jitter stays within expected range', () {
        final executor = RetryExecutor();
        final policy = RetryPolicy.exponential(
          maxAttempts: 5,
          initialDelay: const Duration(milliseconds: 1000),
          multiplier: 1.0,
          maxDelay: const Duration(seconds: 10),
          jitter: 0.1,
        );

        final delays = <int>[];
        for (var i = 0; i < 100; i++) {
          delays.add(
            executor
                .calculateDelay(policy, 1)
                .inMilliseconds,
          );
        }

        for (final d in delays) {
          expect(d, greaterThanOrEqualTo(900));
          expect(d, lessThanOrEqualTo(1100));
        }

        expect(
          delays.toSet().length,
          greaterThan(1),
          reason: 'Jitter should produce varying delays',
        );
      });
    });

    group('executeWithRetry', () {
      test('succeeds on first attempt without retry', () async {
        final executor = RetryExecutor();
        var callCount = 0;

        final result = await executor.executeWithRetry<int>(
          RetryPolicy.none,
          () async {
            callCount++;
            return 42;
          },
        );

        expect(result, 42);
        expect(callCount, 1);
      });

      test('retries and succeeds on second attempt', () async {
        final executor = RetryExecutor();
        var callCount = 0;

        final result = await executor.executeWithRetry<int>(
          RetryPolicy.fixed(
            maxAttempts: 3,
            delay: Duration.zero,
          ),
          () async {
            callCount++;
            if (callCount < 2) throw StateError('fail');
            return 42;
          },
          delayFn: (_) async {},
        );

        expect(result, 42);
        expect(callCount, 2);
      });

      test('throws after maxAttempts exhausted', () async {
        final executor = RetryExecutor();
        var callCount = 0;

        await expectLater(
          executor.executeWithRetry<int>(
            RetryPolicy.fixed(
              maxAttempts: 3,
              delay: Duration.zero,
            ),
            () async {
              callCount++;
              throw StateError('always fails');
            },
            delayFn: (_) async {},
          ),
          throwsStateError,
        );

        expect(callCount, 3);
      });

      test('invokes onAttempt and onRetry callbacks', () async {
        final executor = RetryExecutor();
        final attempts = <int>[];
        final retries = <int>[];
        var callCount = 0;

        await executor.executeWithRetry<int>(
          RetryPolicy.fixed(
            maxAttempts: 3,
            delay: Duration.zero,
          ),
          () async {
            callCount++;
            if (callCount < 3) throw StateError('fail');
            return 42;
          },
          onAttempt: attempts.add,
          onRetry: (a, _) => retries.add(a),
          delayFn: (_) async {},
        );

        expect(attempts, [1, 2, 3]);
        expect(retries, [1, 2]);
      });

      test('does not retry on RetryPolicy.none', () async {
        final executor = RetryExecutor();
        var callCount = 0;

        await expectLater(
          executor.executeWithRetry<int>(
            RetryPolicy.none,
            () async {
              callCount++;
              throw StateError('fail');
            },
          ),
          throwsStateError,
        );

        expect(callCount, 1);
      });

      test('exponential retry succeeds after multiple attempts',
          () async {
        final executor = RetryExecutor();
        var callCount = 0;
        final delays = <Duration>[];

        final result = await executor.executeWithRetry<String>(
          RetryPolicy.exponential(
            maxAttempts: 4,
            initialDelay: const Duration(milliseconds: 100),
            multiplier: 2.0,
            maxDelay: const Duration(seconds: 10),
            jitter: 0.0,
          ),
          () async {
            callCount++;
            if (callCount < 3) throw StateError('not yet');
            return 'done';
          },
          delayFn: (d) async => delays.add(d),
        );

        expect(result, 'done');
        expect(callCount, 3);
        expect(delays, [
          const Duration(milliseconds: 100),
          const Duration(milliseconds: 200),
        ]);
      });
    });
  });

  group('StepExecutor with retry', () {
    late InMemoryCheckpointStore store;

    setUp(() {
      store = InMemoryCheckpointStore();
    });

    test('retries according to policy and succeeds', () async {
      final executor = await createTestExecutor(
        store,
        executionId: 'exec-retry-1',
        delayFn: (_) async {},
      );

      var callCount = 0;
      final result = await executor.executeStep<int>(
        'flaky_step',
        () async {
          callCount++;
          if (callCount < 3) throw StateError('transient');
          return 99;
        },
        retryPolicy: RetryPolicy.fixed(
          maxAttempts: 3,
          delay: const Duration(milliseconds: 10),
        ),
      );

      expect(result, 99);
      expect(callCount, 3);

      final checkpoints =
          await store.loadCheckpoints('exec-retry-1');
      final completed = checkpoints
          .where((cp) => cp.status == StepStatus.completed);
      expect(completed, hasLength(1));
    });

    test('marks step and execution FAILED after maxAttempts',
        () async {
      final executor = await createTestExecutor(
        store,
        executionId: 'exec-retry-2',
        delayFn: (_) async {},
      );

      await expectLater(
        executor.executeStep<int>(
          'always_fails',
          () async => throw StateError('permanent'),
          retryPolicy: RetryPolicy.fixed(
            maxAttempts: 2,
            delay: Duration.zero,
          ),
        ),
        throwsStateError,
      );

      final execution =
          await store.loadExecution('exec-retry-2');
      expect(execution!.status, isA<Failed>());
    });

    test('registers compensate function', () async {
      final executor = await createTestExecutor(
        store,
        executionId: 'exec-comp-1',
      );

      await executor.executeStep<int>(
        'with_compensate',
        () async => 42,
        compensate: (_) async {},
      );

      expect(
        executor.compensateFunctions
            .containsKey('with_compensate'),
        isTrue,
      );
    });

    test('stores compensateRef in checkpoint', () async {
      final executor = await createTestExecutor(
        store,
        executionId: 'exec-comp-2',
      );

      await executor.executeStep<int>(
        'step_with_comp',
        () async => 1,
        compensate: (_) async {},
      );

      final checkpoints =
          await store.loadCheckpoints('exec-comp-2');
      expect(checkpoints[0].compensateRef, 'step_with_comp');
    });
  });
}
