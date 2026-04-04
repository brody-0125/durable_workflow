/// Status of a step checkpoint.
enum StepStatus {
  /// Step execution has been recorded as intended but not yet executed.
  intent('INTENT'),

  /// Step completed successfully.
  completed('COMPLETED'),

  /// Step failed.
  failed('FAILED'),

  /// Step was compensated (saga rollback).
  compensated('COMPENSATED');

  /// The database string representation.
  final String value;

  const StepStatus(this.value);

  /// Creates a [StepStatus] from its database string representation.
  ///
  /// Throws [ArgumentError] if [value] is not recognized.
  factory StepStatus.fromString(String value) {
    return switch (value) {
      'INTENT' => StepStatus.intent,
      'COMPLETED' => StepStatus.completed,
      'FAILED' => StepStatus.failed,
      'COMPENSATED' => StepStatus.compensated,
      _ => throw ArgumentError('Unknown StepStatus: $value'),
    };
  }
}

/// Represents a checkpoint for a single workflow step.
///
/// Maps 1:1 to the `step_checkpoints` SQLite table.
/// Records intent before execution and result after completion,
/// enabling checkpoint/resume on crash recovery.
class StepCheckpoint {
  /// Auto-incremented primary key, or `null` for unsaved checkpoints.
  final int? id;

  /// Reference to the parent workflow execution.
  final String workflowExecutionId;

  /// Zero-based index of this step within the workflow.
  final int stepIndex;

  /// Human-readable name of this step.
  final String stepName;

  /// Current status of this checkpoint.
  final StepStatus status;

  /// JSON-encoded input data, or `null`.
  final String? inputData;

  /// JSON-encoded output data (used for resume), or `null`.
  final String? outputData;

  /// Error message if the step failed, or `null`.
  final String? errorMessage;

  /// The attempt number (1-based).
  final int attempt;

  /// Reference to the compensation function, or `null`.
  final String? compensateRef;

  /// ISO-8601 timestamp when this step started, or `null`.
  final String? startedAt;

  /// ISO-8601 timestamp when this step completed, or `null`.
  final String? completedAt;

  /// Creates a [StepCheckpoint].
  const StepCheckpoint({
    this.id,
    required this.workflowExecutionId,
    required this.stepIndex,
    required this.stepName,
    required this.status,
    this.inputData,
    this.outputData,
    this.errorMessage,
    this.attempt = 1,
    this.compensateRef,
    this.startedAt,
    this.completedAt,
  });

  /// Creates a [StepCheckpoint] from a JSON map.
  factory StepCheckpoint.fromJson(Map<String, dynamic> json) {
    return StepCheckpoint(
      id: json['id'] as int?,
      workflowExecutionId: json['workflowExecutionId'] as String,
      stepIndex: json['stepIndex'] as int,
      stepName: json['stepName'] as String,
      status: StepStatus.fromString(json['status'] as String),
      inputData: json['inputData'] as String?,
      outputData: json['outputData'] as String?,
      errorMessage: json['errorMessage'] as String?,
      attempt: json['attempt'] as int? ?? 1,
      compensateRef: json['compensateRef'] as String?,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }

  /// Serializes this checkpoint to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'workflowExecutionId': workflowExecutionId,
        'stepIndex': stepIndex,
        'stepName': stepName,
        'status': status.value,
        'inputData': inputData,
        'outputData': outputData,
        'errorMessage': errorMessage,
        'attempt': attempt,
        'compensateRef': compensateRef,
        'startedAt': startedAt,
        'completedAt': completedAt,
      };

  /// Creates a copy with optional field overrides.
  StepCheckpoint copyWith({
    int? id,
    String? workflowExecutionId,
    int? stepIndex,
    String? stepName,
    StepStatus? status,
    String? inputData,
    String? outputData,
    String? errorMessage,
    int? attempt,
    String? compensateRef,
    String? startedAt,
    String? completedAt,
  }) {
    return StepCheckpoint(
      id: id ?? this.id,
      workflowExecutionId:
          workflowExecutionId ?? this.workflowExecutionId,
      stepIndex: stepIndex ?? this.stepIndex,
      stepName: stepName ?? this.stepName,
      status: status ?? this.status,
      inputData: inputData ?? this.inputData,
      outputData: outputData ?? this.outputData,
      errorMessage: errorMessage ?? this.errorMessage,
      attempt: attempt ?? this.attempt,
      compensateRef: compensateRef ?? this.compensateRef,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepCheckpoint &&
          id == other.id &&
          workflowExecutionId == other.workflowExecutionId &&
          stepIndex == other.stepIndex &&
          stepName == other.stepName &&
          status == other.status &&
          inputData == other.inputData &&
          outputData == other.outputData &&
          errorMessage == other.errorMessage &&
          attempt == other.attempt &&
          compensateRef == other.compensateRef &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(
        id,
        workflowExecutionId,
        stepIndex,
        stepName,
        status,
        inputData,
        outputData,
        errorMessage,
        attempt,
        compensateRef,
        startedAt,
        completedAt,
      );

  @override
  String toString() =>
      'StepCheckpoint(id: $id, executionId: $workflowExecutionId, '
      'step: $stepName[$stepIndex], status: $status, '
      'attempt: $attempt)';
}
