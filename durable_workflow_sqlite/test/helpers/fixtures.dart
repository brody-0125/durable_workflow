import 'package:durable_workflow/durable_workflow.dart';

/// ISO-8601 timestamp constants used across test fixtures.
const kCreatedAt = '2026-03-25T10:00:00.000';
const kUpdatedAt = '2026-03-25T10:00:00.000';
const kLaterAt = '2026-03-25T11:00:00.000';

/// Creates a minimal [Workflow] fixture.
Workflow testWorkflow({
  String id = 'wf-1',
  String type = 'test',
  int version = 1,
  String createdAt = kCreatedAt,
}) {
  return Workflow(
    workflowId: id,
    workflowType: type,
    version: version,
    createdAt: createdAt,
  );
}

/// Creates a minimal [WorkflowExecution] fixture.
WorkflowExecution testExecution({
  String id = 'exec-1',
  String workflowId = 'wf-1',
  ExecutionStatus status = const Pending(),
  int currentStep = 0,
  String? inputData,
  String? outputData,
  String? errorMessage,
  String? ttlExpiresAt,
  WorkflowGuarantee guarantee =
      WorkflowGuarantee.foregroundOnly,
  String createdAt = kCreatedAt,
  String updatedAt = kUpdatedAt,
}) {
  return WorkflowExecution(
    workflowExecutionId: id,
    workflowId: workflowId,
    status: status,
    currentStep: currentStep,
    inputData: inputData,
    outputData: outputData,
    errorMessage: errorMessage,
    ttlExpiresAt: ttlExpiresAt,
    guarantee: guarantee,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Creates a minimal [StepCheckpoint] fixture.
StepCheckpoint testCheckpoint({
  int? id,
  String executionId = 'exec-1',
  int stepIndex = 0,
  String stepName = 'validate',
  StepStatus status = StepStatus.intent,
  String? inputData,
  String? outputData,
  String? errorMessage,
  int attempt = 1,
  String? idempotencyKey,
  String? compensateRef,
  String? startedAt,
  String? completedAt,
}) {
  return StepCheckpoint(
    id: id,
    workflowExecutionId: executionId,
    stepIndex: stepIndex,
    stepName: stepName,
    status: status,
    inputData: inputData,
    outputData: outputData,
    errorMessage: errorMessage,
    attempt: attempt,
    idempotencyKey: idempotencyKey,
    compensateRef: compensateRef,
    startedAt: startedAt,
    completedAt: completedAt,
  );
}

/// Creates a minimal [WorkflowTimer] fixture.
WorkflowTimer testTimer({
  String id = 'timer-1',
  String executionId = 'exec-1',
  String stepName = 'await_shipping',
  String fireAt = '2020-01-01T00:00:00.000',
  TimerStatus status = TimerStatus.pending,
  String createdAt = kCreatedAt,
}) {
  return WorkflowTimer(
    workflowTimerId: id,
    workflowExecutionId: executionId,
    stepName: stepName,
    fireAt: fireAt,
    status: status,
    createdAt: createdAt,
  );
}

/// Creates a minimal [WorkflowSignal] fixture.
WorkflowSignal testSignal({
  int? signalId,
  String executionId = 'exec-1',
  String signalName = 'delivery_confirmed',
  String? payload,
  SignalStatus status = SignalStatus.pending,
  String createdAt = kCreatedAt,
}) {
  return WorkflowSignal(
    workflowSignalId: signalId,
    workflowExecutionId: executionId,
    signalName: signalName,
    payload: payload,
    status: status,
    createdAt: createdAt,
  );
}
