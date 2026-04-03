import 'execution_status.dart';
import 'workflow_guarantee.dart';

/// Represents a running instance of a workflow.
///
/// Maps 1:1 to the `workflow_executions` SQLite table.
/// Immutable value object with JSON serialization.
class WorkflowExecution {
  /// Unique identifier for this execution instance.
  final String workflowExecutionId;

  /// Reference to the parent workflow definition.
  final String workflowId;

  /// Current execution status.
  final ExecutionStatus status;

  /// Index of the current step being executed.
  final int currentStep;

  /// JSON-encoded input data, or `null`.
  final String? inputData;

  /// JSON-encoded output data, or `null`.
  final String? outputData;

  /// Error message if the execution failed, or `null`.
  final String? errorMessage;

  /// ISO-8601 timestamp when this execution expires, or `null`.
  final String? ttlExpiresAt;

  /// The execution guarantee level.
  final WorkflowGuarantee guarantee;

  /// ISO-8601 timestamp when this execution was created.
  final String createdAt;

  /// ISO-8601 timestamp when this execution was last updated.
  final String updatedAt;

  /// Creates a [WorkflowExecution].
  const WorkflowExecution({
    required this.workflowExecutionId,
    required this.workflowId,
    this.status = const Pending(),
    this.currentStep = 0,
    this.inputData,
    this.outputData,
    this.errorMessage,
    this.ttlExpiresAt,
    this.guarantee = WorkflowGuarantee.foregroundOnly,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [WorkflowExecution] from a JSON map.
  factory WorkflowExecution.fromJson(Map<String, dynamic> json) {
    return WorkflowExecution(
      workflowExecutionId: json['workflowExecutionId'] as String,
      workflowId: json['workflowId'] as String,
      status: ExecutionStatus.fromString(json['status'] as String),
      currentStep: json['currentStep'] as int? ?? 0,
      inputData: json['inputData'] as String?,
      outputData: json['outputData'] as String?,
      errorMessage: json['errorMessage'] as String?,
      ttlExpiresAt: json['ttlExpiresAt'] as String?,
      guarantee: WorkflowGuarantee.fromString(
        json['guarantee'] as String? ?? 'FOREGROUND_ONLY',
      ),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  /// Serializes this execution to a JSON map.
  Map<String, dynamic> toJson() => {
        'workflowExecutionId': workflowExecutionId,
        'workflowId': workflowId,
        'status': status.name,
        'currentStep': currentStep,
        'inputData': inputData,
        'outputData': outputData,
        'errorMessage': errorMessage,
        'ttlExpiresAt': ttlExpiresAt,
        'guarantee': guarantee.value,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  /// Creates a copy with optional field overrides.
  WorkflowExecution copyWith({
    String? workflowExecutionId,
    String? workflowId,
    ExecutionStatus? status,
    int? currentStep,
    String? inputData,
    String? outputData,
    String? errorMessage,
    String? ttlExpiresAt,
    WorkflowGuarantee? guarantee,
    String? createdAt,
    String? updatedAt,
  }) {
    return WorkflowExecution(
      workflowExecutionId:
          workflowExecutionId ?? this.workflowExecutionId,
      workflowId: workflowId ?? this.workflowId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      inputData: inputData ?? this.inputData,
      outputData: outputData ?? this.outputData,
      errorMessage: errorMessage ?? this.errorMessage,
      ttlExpiresAt: ttlExpiresAt ?? this.ttlExpiresAt,
      guarantee: guarantee ?? this.guarantee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowExecution &&
          workflowExecutionId == other.workflowExecutionId &&
          workflowId == other.workflowId &&
          status == other.status &&
          currentStep == other.currentStep &&
          inputData == other.inputData &&
          outputData == other.outputData &&
          errorMessage == other.errorMessage &&
          ttlExpiresAt == other.ttlExpiresAt &&
          guarantee == other.guarantee &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        workflowExecutionId,
        workflowId,
        status,
        currentStep,
        inputData,
        outputData,
        errorMessage,
        ttlExpiresAt,
        guarantee,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'WorkflowExecution(id: $workflowExecutionId, '
      'workflowId: $workflowId, status: $status, '
      'currentStep: $currentStep)';
}
