/// Represents the lifecycle status of a workflow execution.
///
/// Uses sealed class for exhaustive pattern matching in switch expressions.
sealed class ExecutionStatus {
  const ExecutionStatus();

  /// The database string representation of this status.
  String get name;

  /// Creates an [ExecutionStatus] from its database string representation.
  ///
  /// Throws [ArgumentError] if [value] is not a recognized status.
  factory ExecutionStatus.fromString(String value) {
    return switch (value) {
      'PENDING' => const Pending(),
      'RUNNING' => const Running(),
      'SUSPENDED' => const Suspended(),
      'COMPLETED' => const Completed(),
      'FAILED' => const Failed(),
      'COMPENSATING' => const Compensating(),
      'CANCELLED' => const Cancelled(),
      _ => throw ArgumentError('Unknown ExecutionStatus: $value'),
    };
  }

  @override
  String toString() => 'ExecutionStatus.$name';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionStatus && runtimeType == other.runtimeType;

  @override
  int get hashCode => name.hashCode;
}

/// Workflow execution has been created but not yet started.
class Pending extends ExecutionStatus {
  /// Creates a [Pending] status.
  const Pending();

  @override
  String get name => 'PENDING';
}

/// Workflow execution is currently running.
class Running extends ExecutionStatus {
  /// Creates a [Running] status.
  const Running();

  @override
  String get name => 'RUNNING';
}

/// Workflow execution is suspended (e.g., waiting for a signal or timer).
class Suspended extends ExecutionStatus {
  /// Creates a [Suspended] status.
  const Suspended();

  @override
  String get name => 'SUSPENDED';
}

/// Workflow execution completed successfully.
class Completed extends ExecutionStatus {
  /// Creates a [Completed] status.
  const Completed();

  @override
  String get name => 'COMPLETED';
}

/// Workflow execution failed.
class Failed extends ExecutionStatus {
  /// Creates a [Failed] status.
  const Failed();

  @override
  String get name => 'FAILED';
}

/// Workflow execution is running compensating (saga rollback) steps.
class Compensating extends ExecutionStatus {
  /// Creates a [Compensating] status.
  const Compensating();

  @override
  String get name => 'COMPENSATING';
}

/// Workflow execution was cancelled.
class Cancelled extends ExecutionStatus {
  /// Creates a [Cancelled] status.
  const Cancelled();

  @override
  String get name => 'CANCELLED';
}
