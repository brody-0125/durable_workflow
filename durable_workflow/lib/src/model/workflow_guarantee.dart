/// Defines the execution guarantee level for a workflow.
///
/// Determines how the workflow engine handles background execution
/// and process lifecycle events.
enum WorkflowGuarantee {
  /// Workflow runs only while the app is in the foreground.
  ///
  /// Steps complete while the process is alive; on crash/restart,
  /// the workflow resumes from the last checkpoint.
  foregroundOnly('FOREGROUND_ONLY'),

  /// Workflow attempts to continue in the background using platform
  /// adapters (WorkManager on Android, BGTask on iOS).
  ///
  /// Background execution is not guaranteed due to OS restrictions.
  bestEffortBackground('BEST_EFFORT_BACKGROUND');

  /// The database string representation.
  final String value;

  const WorkflowGuarantee(this.value);

  /// Creates a [WorkflowGuarantee] from its database string representation.
  ///
  /// Throws [ArgumentError] if [value] is not recognized.
  factory WorkflowGuarantee.fromString(String value) {
    return switch (value) {
      'FOREGROUND_ONLY' => WorkflowGuarantee.foregroundOnly,
      'BEST_EFFORT_BACKGROUND' => WorkflowGuarantee.bestEffortBackground,
      _ => throw ArgumentError('Unknown WorkflowGuarantee: $value'),
    };
  }
}
