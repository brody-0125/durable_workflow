import 'dart:async';
import 'dart:math';

import '../model/retry_policy.dart';

/// Handles retry logic for workflow steps based on [RetryPolicy].
///
/// Calculates backoff delays and determines whether a step should be retried.
/// Supports fixed-interval and exponential backoff with optional jitter.
class RetryExecutor {
  final Random _random;

  /// Creates a [RetryExecutor].
  ///
  /// [random] is injectable for deterministic testing.
  RetryExecutor({Random? random}) : _random = random ?? Random();

  /// Returns `true` if the step should be retried given the current [attempt].
  ///
  /// [attempt] is 1-based (the first execution is attempt 1).
  bool shouldRetry(RetryPolicy policy, int attempt) {
    return switch (policy) {
      RetryPolicyNone() => false,
      RetryPolicyFixed(maxAttempts: final max) => attempt < max,
      RetryPolicyExponential(maxAttempts: final max) => attempt < max,
    };
  }

  /// Calculates the delay before the next retry attempt.
  ///
  /// [attempt] is 1-based: attempt 1 just failed, so this returns the delay
  /// before attempt 2.
  ///
  /// For fixed: always returns [RetryPolicyFixed.delay].
  /// For exponential: `min(initial * multiplier^(attempt-1), maxDelay)` with
  /// optional jitter of +/-10%.
  Duration calculateDelay(RetryPolicy policy, int attempt) {
    return switch (policy) {
      RetryPolicyNone() => Duration.zero,
      RetryPolicyFixed(delay: final d) => d,
      RetryPolicyExponential() => _exponentialDelay(policy, attempt),
    };
  }

  Duration _exponentialDelay(RetryPolicyExponential policy, int attempt) {
    // delay = min(initial * multiplier^(attempt-1), maxDelay)
    final baseMs = policy.initialDelay.inMilliseconds *
        pow(policy.multiplier, attempt - 1);
    final cappedMs = min(baseMs.toDouble(), policy.maxDelay.inMilliseconds.toDouble());

    if (policy.jitter > 0) {
      // jitter: ±(jitter * 100)% random variation
      // For jitter=0.1, this is ±10%
      final jitterFactor = 1.0 + ((_random.nextDouble() * 2 - 1) * policy.jitter);
      final jitteredMs = (cappedMs * jitterFactor).round();
      return Duration(milliseconds: max(0, jitteredMs));
    }

    return Duration(milliseconds: cappedMs.round());
  }

  /// Executes [action] with retry logic according to [policy].
  ///
  /// Returns the result on success. Throws the last exception if all
  /// attempts are exhausted.
  ///
  /// [onAttempt] is called before each attempt with the 1-based attempt number.
  /// [onRetry] is called before each retry delay with the attempt number and error.
  /// [delayFn] is injectable for testing (avoids real waits).
  Future<T> executeWithRetry<T>(
    RetryPolicy policy,
    Future<T> Function() action, {
    void Function(int attempt)? onAttempt,
    FutureOr<void> Function(int attempt, Object error)? onRetry,
    Future<void> Function(Duration delay)? delayFn,
  }) async {
    final effectiveDelay = delayFn ?? (Duration d) => Future<void>.delayed(d);
    var attempt = 1;

    while (true) {
      onAttempt?.call(attempt);
      try {
        return await action();
      } catch (e) {
        if (!shouldRetry(policy, attempt)) {
          rethrow;
        }
        await onRetry?.call(attempt, e);
        final delay = calculateDelay(policy, attempt);
        await effectiveDelay(delay);
        attempt++;
      }
    }
  }
}
