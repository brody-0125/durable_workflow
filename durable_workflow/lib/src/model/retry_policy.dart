/// Defines the retry strategy for a workflow step.
///
/// Uses sealed class for exhaustive pattern matching.
sealed class RetryPolicy {
  const RetryPolicy();

  /// Creates a [RetryPolicy] from a JSON map.
  ///
  /// Throws [ArgumentError] if the type is not recognized.
  factory RetryPolicy.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'none' => const RetryPolicyNone(),
      'fixed' => RetryPolicyFixed(
          maxAttempts: json['maxAttempts'] as int,
          delay: Duration(milliseconds: json['delayMs'] as int),
        ),
      'exponential' => RetryPolicyExponential(
          maxAttempts: json['maxAttempts'] as int,
          initialDelay:
              Duration(milliseconds: json['initialDelayMs'] as int),
          multiplier: (json['multiplier'] as num).toDouble(),
          maxDelay: Duration(milliseconds: json['maxDelayMs'] as int),
          jitter: (json['jitter'] as num?)?.toDouble() ?? 0.0,
        ),
      _ => throw ArgumentError('Unknown RetryPolicy type: $type'),
    };
  }

  /// Convenience constructor for no retry.
  static const RetryPolicy none = RetryPolicyNone();

  /// Convenience constructor for fixed-interval retry.
  static RetryPolicy fixed({
    required int maxAttempts,
    required Duration delay,
  }) =>
      RetryPolicyFixed(maxAttempts: maxAttempts, delay: delay);

  /// Convenience constructor for exponential backoff retry.
  static RetryPolicy exponential({
    required int maxAttempts,
    Duration initialDelay = const Duration(seconds: 1),
    double multiplier = 2.0,
    Duration maxDelay = const Duration(minutes: 5),
    double jitter = 0.0,
  }) =>
      RetryPolicyExponential(
        maxAttempts: maxAttempts,
        initialDelay: initialDelay,
        multiplier: multiplier,
        maxDelay: maxDelay,
        jitter: jitter,
      );

  /// Serializes this retry policy to a JSON map.
  Map<String, dynamic> toJson();
}

/// No retry — the step fails immediately on error.
class RetryPolicyNone extends RetryPolicy {
  /// Creates a [RetryPolicyNone].
  const RetryPolicyNone();

  @override
  Map<String, dynamic> toJson() => {'type': 'none'};

  @override
  String toString() => 'RetryPolicy.none';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RetryPolicyNone;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Fixed-interval retry strategy.
class RetryPolicyFixed extends RetryPolicy {
  /// Maximum number of attempts (including the first).
  final int maxAttempts;

  /// Fixed delay between retries.
  final Duration delay;

  /// Creates a [RetryPolicyFixed].
  const RetryPolicyFixed({
    required this.maxAttempts,
    required this.delay,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'fixed',
        'maxAttempts': maxAttempts,
        'delayMs': delay.inMilliseconds,
      };

  @override
  String toString() =>
      'RetryPolicy.fixed(maxAttempts: $maxAttempts, delay: $delay)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetryPolicyFixed &&
          maxAttempts == other.maxAttempts &&
          delay == other.delay;

  @override
  int get hashCode => Object.hash(maxAttempts, delay);
}

/// Exponential backoff retry strategy.
class RetryPolicyExponential extends RetryPolicy {
  /// Maximum number of attempts (including the first).
  final int maxAttempts;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Multiplier applied to the delay after each attempt.
  final double multiplier;

  /// Maximum delay cap.
  final Duration maxDelay;

  /// Jitter factor (0.0 to 1.0). Adds randomness to avoid thundering herd.
  final double jitter;

  /// Creates a [RetryPolicyExponential].
  const RetryPolicyExponential({
    required this.maxAttempts,
    this.initialDelay = const Duration(seconds: 1),
    this.multiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
    this.jitter = 0.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'exponential',
        'maxAttempts': maxAttempts,
        'initialDelayMs': initialDelay.inMilliseconds,
        'multiplier': multiplier,
        'maxDelayMs': maxDelay.inMilliseconds,
        'jitter': jitter,
      };

  @override
  String toString() =>
      'RetryPolicy.exponential(maxAttempts: $maxAttempts, '
      'initialDelay: $initialDelay, multiplier: $multiplier, '
      'maxDelay: $maxDelay, jitter: $jitter)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetryPolicyExponential &&
          maxAttempts == other.maxAttempts &&
          initialDelay == other.initialDelay &&
          multiplier == other.multiplier &&
          maxDelay == other.maxDelay &&
          jitter == other.jitter;

  @override
  int get hashCode =>
      Object.hash(maxAttempts, initialDelay, multiplier, maxDelay, jitter);
}
