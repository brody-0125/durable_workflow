import 'package:drift/drift.dart';

/// Drift table definition for workflow definitions.
class Workflows extends Table {
  TextColumn get workflowId => text()();
  TextColumn get workflowType => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {workflowId};
}

/// Drift table definition for workflow execution instances.
class WorkflowExecutions extends Table {
  TextColumn get workflowExecutionId => text()();
  TextColumn get workflowId => text().references(Workflows, #workflowId)();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))();
  IntColumn get currentStep => integer().withDefault(const Constant(0))();
  TextColumn get inputData => text().nullable()();
  TextColumn get outputData => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get ttlExpiresAt => text().nullable()();
  TextColumn get guarantee =>
      text().withDefault(const Constant('FOREGROUND_ONLY'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {workflowExecutionId};
}

/// Drift table definition for step checkpoints.
class StepCheckpoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workflowExecutionId =>
      text().references(WorkflowExecutions, #workflowExecutionId)();
  IntColumn get stepIndex => integer()();
  TextColumn get stepName => text()();
  TextColumn get status => text()();
  TextColumn get inputData => text().nullable()();
  TextColumn get outputData => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get attempt => integer().withDefault(const Constant(1))();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get compensateRef => text().nullable()();
  TextColumn get startedAt => text().nullable()();
  TextColumn get completedAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {workflowExecutionId, stepIndex, attempt},
      ];
}

/// Drift table definition for workflow timers.
class WorkflowTimers extends Table {
  TextColumn get workflowTimerId => text()();
  TextColumn get workflowExecutionId =>
      text().references(WorkflowExecutions, #workflowExecutionId)();
  TextColumn get stepName => text()();
  TextColumn get fireAt => text()();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {workflowTimerId};
}

/// Drift table definition for workflow signals.
class WorkflowSignals extends Table {
  IntColumn get workflowSignalId => integer().autoIncrement()();
  TextColumn get workflowExecutionId =>
      text().references(WorkflowExecutions, #workflowExecutionId)();
  TextColumn get signalName => text()();
  TextColumn get payload => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))();
  TextColumn get createdAt => text()();
}
