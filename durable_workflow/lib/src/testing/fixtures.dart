import 'package:durable_workflow/durable_workflow.dart';

/// ISO-8601 timestamp for a point in the past.
String pastTimestamp({Duration ago = const Duration(hours: 1)}) {
  return DateTime.now().toUtc().subtract(ago).toIso8601String();
}

/// ISO-8601 timestamp for a point in the future.
String futureTimestamp({Duration ahead = const Duration(hours: 1)}) {
  return DateTime.now().toUtc().add(ahead).toIso8601String();
}

/// Current UTC ISO-8601 timestamp.
String nowTimestamp() => DateTime.now().toUtc().toIso8601String();

/// Creates a [WorkflowExecution] with sensible defaults for testing.
///
/// Only [id] is required; all other fields use minimal defaults.
WorkflowExecution createTestExecution(
  String id, {
  String workflowId = 'wf-test-0',
  ExecutionStatus status = const Running(),
  int currentStep = 0,
  String? inputData,
  String? outputData,
  String? errorMessage,
  String? ttlExpiresAt,
  WorkflowGuarantee guarantee = WorkflowGuarantee.foregroundOnly,
}) {
  final now = nowTimestamp();
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
    createdAt: now,
    updatedAt: now,
  );
}

/// Creates a [StepCheckpoint] with sensible defaults for testing.
StepCheckpoint createTestCheckpoint({
  int? id,
  required String workflowExecutionId,
  required int stepIndex,
  required String stepName,
  StepStatus status = StepStatus.completed,
  String? inputData,
  String? outputData,
  String? errorMessage,
  int attempt = 1,
  String? compensateRef,
}) {
  return StepCheckpoint(
    id: id,
    workflowExecutionId: workflowExecutionId,
    stepIndex: stepIndex,
    stepName: stepName,
    status: status,
    inputData: inputData,
    outputData: outputData,
    errorMessage: errorMessage,
    attempt: attempt,
    compensateRef: compensateRef,
  );
}

/// Creates a [WorkflowTimer] with sensible defaults for testing.
WorkflowTimer createTestTimer(
  String timerId,
  String executionId, {
  String stepName = 'timer-step',
  String? fireAt,
  TimerStatus status = TimerStatus.pending,
}) {
  final now = nowTimestamp();
  return WorkflowTimer(
    workflowTimerId: timerId,
    workflowExecutionId: executionId,
    stepName: stepName,
    fireAt: fireAt ?? pastTimestamp(ago: const Duration(minutes: 1)),
    status: status,
    createdAt: now,
  );
}

/// Creates a [WorkflowSignal] with sensible defaults for testing.
WorkflowSignal createTestSignal(
  String executionId, {
  String signalName = 'test-signal',
  String? payload,
  SignalStatus status = SignalStatus.pending,
}) {
  final now = nowTimestamp();
  return WorkflowSignal(
    workflowExecutionId: executionId,
    signalName: signalName,
    payload: payload ?? '{"data": "test"}',
    status: status,
    createdAt: now,
  );
}
