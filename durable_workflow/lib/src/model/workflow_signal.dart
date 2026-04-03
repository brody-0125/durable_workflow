/// Status of a workflow signal.
enum SignalStatus {
  /// Signal is waiting to be delivered.
  pending('PENDING'),

  /// Signal has been delivered to the workflow.
  delivered('DELIVERED'),

  /// Signal expired before delivery.
  expired('EXPIRED');

  /// The database string representation.
  final String value;

  const SignalStatus(this.value);

  /// Creates a [SignalStatus] from its database string representation.
  ///
  /// Throws [ArgumentError] if [value] is not recognized.
  factory SignalStatus.fromString(String value) {
    return switch (value) {
      'PENDING' => SignalStatus.pending,
      'DELIVERED' => SignalStatus.delivered,
      'EXPIRED' => SignalStatus.expired,
      _ => throw ArgumentError('Unknown SignalStatus: $value'),
    };
  }
}

/// Represents a signal sent to a workflow execution.
///
/// Maps 1:1 to the `workflow_signals` SQLite table.
/// Signals enable external event communication with running workflows.
class WorkflowSignal {
  /// Auto-incremented primary key, or `null` for unsaved signals.
  final int? workflowSignalId;

  /// Reference to the target workflow execution.
  final String workflowExecutionId;

  /// Name of the signal (used for matching with `waitSignal`).
  final String signalName;

  /// JSON-encoded payload, or `null`.
  final String? payload;

  /// Current status of this signal.
  final SignalStatus status;

  /// ISO-8601 timestamp when this signal was created.
  final String createdAt;

  /// Creates a [WorkflowSignal].
  const WorkflowSignal({
    this.workflowSignalId,
    required this.workflowExecutionId,
    required this.signalName,
    this.payload,
    this.status = SignalStatus.pending,
    required this.createdAt,
  });

  /// Creates a [WorkflowSignal] from a JSON map.
  factory WorkflowSignal.fromJson(Map<String, dynamic> json) {
    return WorkflowSignal(
      workflowSignalId: json['workflowSignalId'] as int?,
      workflowExecutionId: json['workflowExecutionId'] as String,
      signalName: json['signalName'] as String,
      payload: json['payload'] as String?,
      status: SignalStatus.fromString(
        json['status'] as String? ?? 'PENDING',
      ),
      createdAt: json['createdAt'] as String,
    );
  }

  /// Serializes this signal to a JSON map.
  Map<String, dynamic> toJson() => {
        'workflowSignalId': workflowSignalId,
        'workflowExecutionId': workflowExecutionId,
        'signalName': signalName,
        'payload': payload,
        'status': status.value,
        'createdAt': createdAt,
      };

  /// Creates a copy with optional field overrides.
  WorkflowSignal copyWith({
    int? workflowSignalId,
    String? workflowExecutionId,
    String? signalName,
    String? payload,
    SignalStatus? status,
    String? createdAt,
  }) {
    return WorkflowSignal(
      workflowSignalId: workflowSignalId ?? this.workflowSignalId,
      workflowExecutionId:
          workflowExecutionId ?? this.workflowExecutionId,
      signalName: signalName ?? this.signalName,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowSignal &&
          workflowSignalId == other.workflowSignalId &&
          workflowExecutionId == other.workflowExecutionId &&
          signalName == other.signalName &&
          payload == other.payload &&
          status == other.status &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        workflowSignalId,
        workflowExecutionId,
        signalName,
        payload,
        status,
        createdAt,
      );

  @override
  String toString() =>
      'WorkflowSignal(id: $workflowSignalId, '
      'executionId: $workflowExecutionId, '
      'signal: $signalName, status: $status)';
}
