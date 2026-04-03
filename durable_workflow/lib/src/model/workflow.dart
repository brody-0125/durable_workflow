/// Represents a workflow definition.
///
/// Maps 1:1 to the `workflows` SQLite table.
/// Immutable value object with JSON serialization.
class Workflow {
  /// Unique identifier for the workflow.
  final String workflowId;

  /// The type/name of this workflow (e.g., 'order_processing').
  final String workflowType;

  /// Schema version for migration support.
  final int version;

  /// ISO-8601 timestamp when this workflow was created.
  final String createdAt;

  /// Creates a [Workflow].
  const Workflow({
    required this.workflowId,
    required this.workflowType,
    this.version = 1,
    required this.createdAt,
  });

  /// Creates a [Workflow] from a JSON map.
  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      workflowId: json['workflowId'] as String,
      workflowType: json['workflowType'] as String,
      version: json['version'] as int? ?? 1,
      createdAt: json['createdAt'] as String,
    );
  }

  /// Serializes this workflow to a JSON map.
  Map<String, dynamic> toJson() => {
        'workflowId': workflowId,
        'workflowType': workflowType,
        'version': version,
        'createdAt': createdAt,
      };

  /// Creates a copy with optional field overrides.
  Workflow copyWith({
    String? workflowId,
    String? workflowType,
    int? version,
    String? createdAt,
  }) {
    return Workflow(
      workflowId: workflowId ?? this.workflowId,
      workflowType: workflowType ?? this.workflowType,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workflow &&
          workflowId == other.workflowId &&
          workflowType == other.workflowType &&
          version == other.version &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(workflowId, workflowType, version, createdAt);

  @override
  String toString() =>
      'Workflow(workflowId: $workflowId, workflowType: $workflowType, '
      'version: $version, createdAt: $createdAt)';
}
