import 'package:durable_workflow/durable_workflow.dart';
import 'package:sqlite3/sqlite3.dart';

/// Maps a SQLite [Row] to a [Workflow].
Workflow workflowFromRow(Row row) {
  return Workflow(
    workflowId: row['workflow_id'] as String,
    workflowType: row['workflow_type'] as String,
    version: row['version'] as int,
    createdAt: row['created_at'] as String,
  );
}

/// Maps a SQLite [Row] to a [WorkflowExecution].
WorkflowExecution executionFromRow(Row row) {
  return WorkflowExecution(
    workflowExecutionId:
        row['workflow_execution_id'] as String,
    workflowId: row['workflow_id'] as String,
    status: ExecutionStatus.fromString(
      row['status'] as String,
    ),
    currentStep: row['current_step'] as int,
    inputData: row['input_data'] as String?,
    outputData: row['output_data'] as String?,
    errorMessage: row['error_message'] as String?,
    ttlExpiresAt: row['ttl_expires_at'] as String?,
    guarantee: WorkflowGuarantee.fromString(
      row['guarantee'] as String,
    ),
    createdAt: row['created_at'] as String,
    updatedAt: row['updated_at'] as String,
  );
}

/// Maps a SQLite [Row] to a [StepCheckpoint].
StepCheckpoint checkpointFromRow(Row row) {
  return StepCheckpoint(
    id: row['id'] as int,
    workflowExecutionId:
        row['workflow_execution_id'] as String,
    stepIndex: row['step_index'] as int,
    stepName: row['step_name'] as String,
    status: StepStatus.fromString(row['status'] as String),
    inputData: row['input_data'] as String?,
    outputData: row['output_data'] as String?,
    errorMessage: row['error_message'] as String?,
    attempt: row['attempt'] as int,
    compensateRef: row['compensate_ref'] as String?,
    startedAt: row['started_at'] as String?,
    completedAt: row['completed_at'] as String?,
  );
}

/// Maps a SQLite [Row] to a [WorkflowTimer].
WorkflowTimer timerFromRow(Row row) {
  return WorkflowTimer(
    workflowTimerId: row['workflow_timer_id'] as String,
    workflowExecutionId:
        row['workflow_execution_id'] as String,
    stepName: row['step_name'] as String,
    fireAt: row['fire_at'] as String,
    status: TimerStatus.fromString(
      row['status'] as String,
    ),
    createdAt: row['created_at'] as String,
  );
}

/// Maps a SQLite [Row] to a [WorkflowSignal].
WorkflowSignal signalFromRow(Row row) {
  return WorkflowSignal(
    workflowSignalId: row['workflow_signal_id'] as int?,
    workflowExecutionId:
        row['workflow_execution_id'] as String,
    signalName: row['signal_name'] as String,
    payload: row['payload'] as String?,
    status: SignalStatus.fromString(
      row['status'] as String,
    ),
    createdAt: row['created_at'] as String,
  );
}
