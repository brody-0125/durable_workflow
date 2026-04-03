/// Status of a workflow timer.
enum TimerStatus {
  /// Timer is waiting to fire.
  pending('PENDING'),

  /// Timer has fired.
  fired('FIRED'),

  /// Timer was cancelled.
  cancelled('CANCELLED');

  /// The database string representation.
  final String value;

  const TimerStatus(this.value);

  /// Creates a [TimerStatus] from its database string representation.
  ///
  /// Throws [ArgumentError] if [value] is not recognized.
  factory TimerStatus.fromString(String value) {
    return switch (value) {
      'PENDING' => TimerStatus.pending,
      'FIRED' => TimerStatus.fired,
      'CANCELLED' => TimerStatus.cancelled,
      _ => throw ArgumentError('Unknown TimerStatus: $value'),
    };
  }
}

/// Represents a durable timer associated with a workflow execution.
///
/// Maps 1:1 to the `workflow_timers` SQLite table.
/// Timers survive process restarts via database persistence.
class WorkflowTimer {
  /// Unique identifier for this timer.
  final String workflowTimerId;

  /// Reference to the parent workflow execution.
  final String workflowExecutionId;

  /// Name of the step that created this timer.
  final String stepName;

  /// ISO-8601 timestamp when this timer should fire.
  final String fireAt;

  /// Current status of this timer.
  final TimerStatus status;

  /// ISO-8601 timestamp when this timer was created.
  final String createdAt;

  /// Creates a [WorkflowTimer].
  const WorkflowTimer({
    required this.workflowTimerId,
    required this.workflowExecutionId,
    required this.stepName,
    required this.fireAt,
    this.status = TimerStatus.pending,
    required this.createdAt,
  });

  /// Creates a [WorkflowTimer] from a JSON map.
  factory WorkflowTimer.fromJson(Map<String, dynamic> json) {
    return WorkflowTimer(
      workflowTimerId: json['workflowTimerId'] as String,
      workflowExecutionId: json['workflowExecutionId'] as String,
      stepName: json['stepName'] as String,
      fireAt: json['fireAt'] as String,
      status: TimerStatus.fromString(
        json['status'] as String? ?? 'PENDING',
      ),
      createdAt: json['createdAt'] as String,
    );
  }

  /// Serializes this timer to a JSON map.
  Map<String, dynamic> toJson() => {
        'workflowTimerId': workflowTimerId,
        'workflowExecutionId': workflowExecutionId,
        'stepName': stepName,
        'fireAt': fireAt,
        'status': status.value,
        'createdAt': createdAt,
      };

  /// Creates a copy with optional field overrides.
  WorkflowTimer copyWith({
    String? workflowTimerId,
    String? workflowExecutionId,
    String? stepName,
    String? fireAt,
    TimerStatus? status,
    String? createdAt,
  }) {
    return WorkflowTimer(
      workflowTimerId: workflowTimerId ?? this.workflowTimerId,
      workflowExecutionId:
          workflowExecutionId ?? this.workflowExecutionId,
      stepName: stepName ?? this.stepName,
      fireAt: fireAt ?? this.fireAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowTimer &&
          workflowTimerId == other.workflowTimerId &&
          workflowExecutionId == other.workflowExecutionId &&
          stepName == other.stepName &&
          fireAt == other.fireAt &&
          status == other.status &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        workflowTimerId,
        workflowExecutionId,
        stepName,
        fireAt,
        status,
        createdAt,
      );

  @override
  String toString() =>
      'WorkflowTimer(id: $workflowTimerId, '
      'executionId: $workflowExecutionId, '
      'step: $stepName, fireAt: $fireAt, status: $status)';
}
