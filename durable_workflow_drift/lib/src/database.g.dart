// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorkflowsTable extends Workflows
    with TableInfo<$WorkflowsTable, Workflow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkflowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workflowIdMeta =
      const VerificationMeta('workflowId');
  @override
  late final GeneratedColumn<String> workflowId = GeneratedColumn<String>(
      'workflow_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workflowTypeMeta =
      const VerificationMeta('workflowType');
  @override
  late final GeneratedColumn<String> workflowType = GeneratedColumn<String>(
      'workflow_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [workflowId, workflowType, version, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workflows';
  @override
  VerificationContext validateIntegrity(Insertable<Workflow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workflow_id')) {
      context.handle(
          _workflowIdMeta,
          workflowId.isAcceptableOrUnknown(
              data['workflow_id']!, _workflowIdMeta));
    } else if (isInserting) {
      context.missing(_workflowIdMeta);
    }
    if (data.containsKey('workflow_type')) {
      context.handle(
          _workflowTypeMeta,
          workflowType.isAcceptableOrUnknown(
              data['workflow_type']!, _workflowTypeMeta));
    } else if (isInserting) {
      context.missing(_workflowTypeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workflowId};
  @override
  Workflow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workflow(
      workflowId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workflow_id'])!,
      workflowType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workflow_type'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WorkflowsTable createAlias(String alias) {
    return $WorkflowsTable(attachedDatabase, alias);
  }
}

class Workflow extends DataClass implements Insertable<Workflow> {
  final String workflowId;
  final String workflowType;
  final int version;
  final String createdAt;
  const Workflow(
      {required this.workflowId,
      required this.workflowType,
      required this.version,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workflow_id'] = Variable<String>(workflowId);
    map['workflow_type'] = Variable<String>(workflowType);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  WorkflowsCompanion toCompanion(bool nullToAbsent) {
    return WorkflowsCompanion(
      workflowId: Value(workflowId),
      workflowType: Value(workflowType),
      version: Value(version),
      createdAt: Value(createdAt),
    );
  }

  factory Workflow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workflow(
      workflowId: serializer.fromJson<String>(json['workflowId']),
      workflowType: serializer.fromJson<String>(json['workflowType']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workflowId': serializer.toJson<String>(workflowId),
      'workflowType': serializer.toJson<String>(workflowType),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Workflow copyWith(
          {String? workflowId,
          String? workflowType,
          int? version,
          String? createdAt}) =>
      Workflow(
        workflowId: workflowId ?? this.workflowId,
        workflowType: workflowType ?? this.workflowType,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
      );
  Workflow copyWithCompanion(WorkflowsCompanion data) {
    return Workflow(
      workflowId:
          data.workflowId.present ? data.workflowId.value : this.workflowId,
      workflowType: data.workflowType.present
          ? data.workflowType.value
          : this.workflowType,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workflow(')
          ..write('workflowId: $workflowId, ')
          ..write('workflowType: $workflowType, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workflowId, workflowType, version, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workflow &&
          other.workflowId == this.workflowId &&
          other.workflowType == this.workflowType &&
          other.version == this.version &&
          other.createdAt == this.createdAt);
}

class WorkflowsCompanion extends UpdateCompanion<Workflow> {
  final Value<String> workflowId;
  final Value<String> workflowType;
  final Value<int> version;
  final Value<String> createdAt;
  final Value<int> rowid;
  const WorkflowsCompanion({
    this.workflowId = const Value.absent(),
    this.workflowType = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkflowsCompanion.insert({
    required String workflowId,
    required String workflowType,
    this.version = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : workflowId = Value(workflowId),
        workflowType = Value(workflowType),
        createdAt = Value(createdAt);
  static Insertable<Workflow> custom({
    Expression<String>? workflowId,
    Expression<String>? workflowType,
    Expression<int>? version,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workflowId != null) 'workflow_id': workflowId,
      if (workflowType != null) 'workflow_type': workflowType,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkflowsCompanion copyWith(
      {Value<String>? workflowId,
      Value<String>? workflowType,
      Value<int>? version,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return WorkflowsCompanion(
      workflowId: workflowId ?? this.workflowId,
      workflowType: workflowType ?? this.workflowType,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workflowId.present) {
      map['workflow_id'] = Variable<String>(workflowId.value);
    }
    if (workflowType.present) {
      map['workflow_type'] = Variable<String>(workflowType.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowsCompanion(')
          ..write('workflowId: $workflowId, ')
          ..write('workflowType: $workflowType, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkflowExecutionsTable extends WorkflowExecutions
    with TableInfo<$WorkflowExecutionsTable, WorkflowExecution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkflowExecutionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workflowExecutionIdMeta =
      const VerificationMeta('workflowExecutionId');
  @override
  late final GeneratedColumn<String> workflowExecutionId =
      GeneratedColumn<String>('workflow_execution_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workflowIdMeta =
      const VerificationMeta('workflowId');
  @override
  late final GeneratedColumn<String> workflowId = GeneratedColumn<String>(
      'workflow_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workflows (workflow_id)'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  static const VerificationMeta _currentStepMeta =
      const VerificationMeta('currentStep');
  @override
  late final GeneratedColumn<int> currentStep = GeneratedColumn<int>(
      'current_step', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _inputDataMeta =
      const VerificationMeta('inputData');
  @override
  late final GeneratedColumn<String> inputData = GeneratedColumn<String>(
      'input_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _outputDataMeta =
      const VerificationMeta('outputData');
  @override
  late final GeneratedColumn<String> outputData = GeneratedColumn<String>(
      'output_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ttlExpiresAtMeta =
      const VerificationMeta('ttlExpiresAt');
  @override
  late final GeneratedColumn<String> ttlExpiresAt = GeneratedColumn<String>(
      'ttl_expires_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _guaranteeMeta =
      const VerificationMeta('guarantee');
  @override
  late final GeneratedColumn<String> guarantee = GeneratedColumn<String>(
      'guarantee', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('FOREGROUND_ONLY'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
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
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workflow_executions';
  @override
  VerificationContext validateIntegrity(Insertable<WorkflowExecution> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workflow_execution_id')) {
      context.handle(
          _workflowExecutionIdMeta,
          workflowExecutionId.isAcceptableOrUnknown(
              data['workflow_execution_id']!, _workflowExecutionIdMeta));
    } else if (isInserting) {
      context.missing(_workflowExecutionIdMeta);
    }
    if (data.containsKey('workflow_id')) {
      context.handle(
          _workflowIdMeta,
          workflowId.isAcceptableOrUnknown(
              data['workflow_id']!, _workflowIdMeta));
    } else if (isInserting) {
      context.missing(_workflowIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('current_step')) {
      context.handle(
          _currentStepMeta,
          currentStep.isAcceptableOrUnknown(
              data['current_step']!, _currentStepMeta));
    }
    if (data.containsKey('input_data')) {
      context.handle(_inputDataMeta,
          inputData.isAcceptableOrUnknown(data['input_data']!, _inputDataMeta));
    }
    if (data.containsKey('output_data')) {
      context.handle(
          _outputDataMeta,
          outputData.isAcceptableOrUnknown(
              data['output_data']!, _outputDataMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('ttl_expires_at')) {
      context.handle(
          _ttlExpiresAtMeta,
          ttlExpiresAt.isAcceptableOrUnknown(
              data['ttl_expires_at']!, _ttlExpiresAtMeta));
    }
    if (data.containsKey('guarantee')) {
      context.handle(_guaranteeMeta,
          guarantee.isAcceptableOrUnknown(data['guarantee']!, _guaranteeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workflowExecutionId};
  @override
  WorkflowExecution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkflowExecution(
      workflowExecutionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}workflow_execution_id'])!,
      workflowId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workflow_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      currentStep: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_step'])!,
      inputData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}input_data']),
      outputData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}output_data']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      ttlExpiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ttl_expires_at']),
      guarantee: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}guarantee'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorkflowExecutionsTable createAlias(String alias) {
    return $WorkflowExecutionsTable(attachedDatabase, alias);
  }
}

class WorkflowExecution extends DataClass
    implements Insertable<WorkflowExecution> {
  final String workflowExecutionId;
  final String workflowId;
  final String status;
  final int currentStep;
  final String? inputData;
  final String? outputData;
  final String? errorMessage;
  final String? ttlExpiresAt;
  final String guarantee;
  final String createdAt;
  final String updatedAt;
  const WorkflowExecution(
      {required this.workflowExecutionId,
      required this.workflowId,
      required this.status,
      required this.currentStep,
      this.inputData,
      this.outputData,
      this.errorMessage,
      this.ttlExpiresAt,
      required this.guarantee,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workflow_execution_id'] = Variable<String>(workflowExecutionId);
    map['workflow_id'] = Variable<String>(workflowId);
    map['status'] = Variable<String>(status);
    map['current_step'] = Variable<int>(currentStep);
    if (!nullToAbsent || inputData != null) {
      map['input_data'] = Variable<String>(inputData);
    }
    if (!nullToAbsent || outputData != null) {
      map['output_data'] = Variable<String>(outputData);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || ttlExpiresAt != null) {
      map['ttl_expires_at'] = Variable<String>(ttlExpiresAt);
    }
    map['guarantee'] = Variable<String>(guarantee);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WorkflowExecutionsCompanion toCompanion(bool nullToAbsent) {
    return WorkflowExecutionsCompanion(
      workflowExecutionId: Value(workflowExecutionId),
      workflowId: Value(workflowId),
      status: Value(status),
      currentStep: Value(currentStep),
      inputData: inputData == null && nullToAbsent
          ? const Value.absent()
          : Value(inputData),
      outputData: outputData == null && nullToAbsent
          ? const Value.absent()
          : Value(outputData),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      ttlExpiresAt: ttlExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ttlExpiresAt),
      guarantee: Value(guarantee),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkflowExecution.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkflowExecution(
      workflowExecutionId:
          serializer.fromJson<String>(json['workflowExecutionId']),
      workflowId: serializer.fromJson<String>(json['workflowId']),
      status: serializer.fromJson<String>(json['status']),
      currentStep: serializer.fromJson<int>(json['currentStep']),
      inputData: serializer.fromJson<String?>(json['inputData']),
      outputData: serializer.fromJson<String?>(json['outputData']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      ttlExpiresAt: serializer.fromJson<String?>(json['ttlExpiresAt']),
      guarantee: serializer.fromJson<String>(json['guarantee']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workflowExecutionId': serializer.toJson<String>(workflowExecutionId),
      'workflowId': serializer.toJson<String>(workflowId),
      'status': serializer.toJson<String>(status),
      'currentStep': serializer.toJson<int>(currentStep),
      'inputData': serializer.toJson<String?>(inputData),
      'outputData': serializer.toJson<String?>(outputData),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'ttlExpiresAt': serializer.toJson<String?>(ttlExpiresAt),
      'guarantee': serializer.toJson<String>(guarantee),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  WorkflowExecution copyWith(
          {String? workflowExecutionId,
          String? workflowId,
          String? status,
          int? currentStep,
          Value<String?> inputData = const Value.absent(),
          Value<String?> outputData = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          Value<String?> ttlExpiresAt = const Value.absent(),
          String? guarantee,
          String? createdAt,
          String? updatedAt}) =>
      WorkflowExecution(
        workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
        workflowId: workflowId ?? this.workflowId,
        status: status ?? this.status,
        currentStep: currentStep ?? this.currentStep,
        inputData: inputData.present ? inputData.value : this.inputData,
        outputData: outputData.present ? outputData.value : this.outputData,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        ttlExpiresAt:
            ttlExpiresAt.present ? ttlExpiresAt.value : this.ttlExpiresAt,
        guarantee: guarantee ?? this.guarantee,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WorkflowExecution copyWithCompanion(WorkflowExecutionsCompanion data) {
    return WorkflowExecution(
      workflowExecutionId: data.workflowExecutionId.present
          ? data.workflowExecutionId.value
          : this.workflowExecutionId,
      workflowId:
          data.workflowId.present ? data.workflowId.value : this.workflowId,
      status: data.status.present ? data.status.value : this.status,
      currentStep:
          data.currentStep.present ? data.currentStep.value : this.currentStep,
      inputData: data.inputData.present ? data.inputData.value : this.inputData,
      outputData:
          data.outputData.present ? data.outputData.value : this.outputData,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      ttlExpiresAt: data.ttlExpiresAt.present
          ? data.ttlExpiresAt.value
          : this.ttlExpiresAt,
      guarantee: data.guarantee.present ? data.guarantee.value : this.guarantee,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowExecution(')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('workflowId: $workflowId, ')
          ..write('status: $status, ')
          ..write('currentStep: $currentStep, ')
          ..write('inputData: $inputData, ')
          ..write('outputData: $outputData, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('ttlExpiresAt: $ttlExpiresAt, ')
          ..write('guarantee: $guarantee, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

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
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkflowExecution &&
          other.workflowExecutionId == this.workflowExecutionId &&
          other.workflowId == this.workflowId &&
          other.status == this.status &&
          other.currentStep == this.currentStep &&
          other.inputData == this.inputData &&
          other.outputData == this.outputData &&
          other.errorMessage == this.errorMessage &&
          other.ttlExpiresAt == this.ttlExpiresAt &&
          other.guarantee == this.guarantee &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkflowExecutionsCompanion extends UpdateCompanion<WorkflowExecution> {
  final Value<String> workflowExecutionId;
  final Value<String> workflowId;
  final Value<String> status;
  final Value<int> currentStep;
  final Value<String?> inputData;
  final Value<String?> outputData;
  final Value<String?> errorMessage;
  final Value<String?> ttlExpiresAt;
  final Value<String> guarantee;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const WorkflowExecutionsCompanion({
    this.workflowExecutionId = const Value.absent(),
    this.workflowId = const Value.absent(),
    this.status = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.inputData = const Value.absent(),
    this.outputData = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.ttlExpiresAt = const Value.absent(),
    this.guarantee = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkflowExecutionsCompanion.insert({
    required String workflowExecutionId,
    required String workflowId,
    this.status = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.inputData = const Value.absent(),
    this.outputData = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.ttlExpiresAt = const Value.absent(),
    this.guarantee = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : workflowExecutionId = Value(workflowExecutionId),
        workflowId = Value(workflowId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<WorkflowExecution> custom({
    Expression<String>? workflowExecutionId,
    Expression<String>? workflowId,
    Expression<String>? status,
    Expression<int>? currentStep,
    Expression<String>? inputData,
    Expression<String>? outputData,
    Expression<String>? errorMessage,
    Expression<String>? ttlExpiresAt,
    Expression<String>? guarantee,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workflowExecutionId != null)
        'workflow_execution_id': workflowExecutionId,
      if (workflowId != null) 'workflow_id': workflowId,
      if (status != null) 'status': status,
      if (currentStep != null) 'current_step': currentStep,
      if (inputData != null) 'input_data': inputData,
      if (outputData != null) 'output_data': outputData,
      if (errorMessage != null) 'error_message': errorMessage,
      if (ttlExpiresAt != null) 'ttl_expires_at': ttlExpiresAt,
      if (guarantee != null) 'guarantee': guarantee,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkflowExecutionsCompanion copyWith(
      {Value<String>? workflowExecutionId,
      Value<String>? workflowId,
      Value<String>? status,
      Value<int>? currentStep,
      Value<String?>? inputData,
      Value<String?>? outputData,
      Value<String?>? errorMessage,
      Value<String?>? ttlExpiresAt,
      Value<String>? guarantee,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return WorkflowExecutionsCompanion(
      workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workflowExecutionId.present) {
      map['workflow_execution_id'] =
          Variable<String>(workflowExecutionId.value);
    }
    if (workflowId.present) {
      map['workflow_id'] = Variable<String>(workflowId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currentStep.present) {
      map['current_step'] = Variable<int>(currentStep.value);
    }
    if (inputData.present) {
      map['input_data'] = Variable<String>(inputData.value);
    }
    if (outputData.present) {
      map['output_data'] = Variable<String>(outputData.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (ttlExpiresAt.present) {
      map['ttl_expires_at'] = Variable<String>(ttlExpiresAt.value);
    }
    if (guarantee.present) {
      map['guarantee'] = Variable<String>(guarantee.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowExecutionsCompanion(')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('workflowId: $workflowId, ')
          ..write('status: $status, ')
          ..write('currentStep: $currentStep, ')
          ..write('inputData: $inputData, ')
          ..write('outputData: $outputData, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('ttlExpiresAt: $ttlExpiresAt, ')
          ..write('guarantee: $guarantee, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StepCheckpointsTable extends StepCheckpoints
    with TableInfo<$StepCheckpointsTable, StepCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _workflowExecutionIdMeta =
      const VerificationMeta('workflowExecutionId');
  @override
  late final GeneratedColumn<String> workflowExecutionId =
      GeneratedColumn<String>('workflow_execution_id', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES workflow_executions (workflow_execution_id)'));
  static const VerificationMeta _stepIndexMeta =
      const VerificationMeta('stepIndex');
  @override
  late final GeneratedColumn<int> stepIndex = GeneratedColumn<int>(
      'step_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stepNameMeta =
      const VerificationMeta('stepName');
  @override
  late final GeneratedColumn<String> stepName = GeneratedColumn<String>(
      'step_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inputDataMeta =
      const VerificationMeta('inputData');
  @override
  late final GeneratedColumn<String> inputData = GeneratedColumn<String>(
      'input_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _outputDataMeta =
      const VerificationMeta('outputData');
  @override
  late final GeneratedColumn<String> outputData = GeneratedColumn<String>(
      'output_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attemptMeta =
      const VerificationMeta('attempt');
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
      'attempt', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _compensateRefMeta =
      const VerificationMeta('compensateRef');
  @override
  late final GeneratedColumn<String> compensateRef = GeneratedColumn<String>(
      'compensate_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
      'started_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workflowExecutionId,
        stepIndex,
        stepName,
        status,
        inputData,
        outputData,
        errorMessage,
        attempt,
        idempotencyKey,
        compensateRef,
        startedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_checkpoints';
  @override
  VerificationContext validateIntegrity(Insertable<StepCheckpoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workflow_execution_id')) {
      context.handle(
          _workflowExecutionIdMeta,
          workflowExecutionId.isAcceptableOrUnknown(
              data['workflow_execution_id']!, _workflowExecutionIdMeta));
    } else if (isInserting) {
      context.missing(_workflowExecutionIdMeta);
    }
    if (data.containsKey('step_index')) {
      context.handle(_stepIndexMeta,
          stepIndex.isAcceptableOrUnknown(data['step_index']!, _stepIndexMeta));
    } else if (isInserting) {
      context.missing(_stepIndexMeta);
    }
    if (data.containsKey('step_name')) {
      context.handle(_stepNameMeta,
          stepName.isAcceptableOrUnknown(data['step_name']!, _stepNameMeta));
    } else if (isInserting) {
      context.missing(_stepNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('input_data')) {
      context.handle(_inputDataMeta,
          inputData.isAcceptableOrUnknown(data['input_data']!, _inputDataMeta));
    }
    if (data.containsKey('output_data')) {
      context.handle(
          _outputDataMeta,
          outputData.isAcceptableOrUnknown(
              data['output_data']!, _outputDataMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('attempt')) {
      context.handle(_attemptMeta,
          attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta));
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    }
    if (data.containsKey('compensate_ref')) {
      context.handle(
          _compensateRefMeta,
          compensateRef.isAcceptableOrUnknown(
              data['compensate_ref']!, _compensateRefMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {workflowExecutionId, stepIndex, attempt},
      ];
  @override
  StepCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepCheckpoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      workflowExecutionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}workflow_execution_id'])!,
      stepIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step_index'])!,
      stepName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}step_name'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      inputData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}input_data']),
      outputData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}output_data']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      attempt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt'])!,
      idempotencyKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}idempotency_key']),
      compensateRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}compensate_ref']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}started_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $StepCheckpointsTable createAlias(String alias) {
    return $StepCheckpointsTable(attachedDatabase, alias);
  }
}

class StepCheckpoint extends DataClass implements Insertable<StepCheckpoint> {
  final int id;
  final String workflowExecutionId;
  final int stepIndex;
  final String stepName;
  final String status;
  final String? inputData;
  final String? outputData;
  final String? errorMessage;
  final int attempt;
  final String? idempotencyKey;
  final String? compensateRef;
  final String? startedAt;
  final String? completedAt;
  const StepCheckpoint(
      {required this.id,
      required this.workflowExecutionId,
      required this.stepIndex,
      required this.stepName,
      required this.status,
      this.inputData,
      this.outputData,
      this.errorMessage,
      required this.attempt,
      this.idempotencyKey,
      this.compensateRef,
      this.startedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workflow_execution_id'] = Variable<String>(workflowExecutionId);
    map['step_index'] = Variable<int>(stepIndex);
    map['step_name'] = Variable<String>(stepName);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || inputData != null) {
      map['input_data'] = Variable<String>(inputData);
    }
    if (!nullToAbsent || outputData != null) {
      map['output_data'] = Variable<String>(outputData);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['attempt'] = Variable<int>(attempt);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || compensateRef != null) {
      map['compensate_ref'] = Variable<String>(compensateRef);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<String>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    return map;
  }

  StepCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return StepCheckpointsCompanion(
      id: Value(id),
      workflowExecutionId: Value(workflowExecutionId),
      stepIndex: Value(stepIndex),
      stepName: Value(stepName),
      status: Value(status),
      inputData: inputData == null && nullToAbsent
          ? const Value.absent()
          : Value(inputData),
      outputData: outputData == null && nullToAbsent
          ? const Value.absent()
          : Value(outputData),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      attempt: Value(attempt),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      compensateRef: compensateRef == null && nullToAbsent
          ? const Value.absent()
          : Value(compensateRef),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory StepCheckpoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepCheckpoint(
      id: serializer.fromJson<int>(json['id']),
      workflowExecutionId:
          serializer.fromJson<String>(json['workflowExecutionId']),
      stepIndex: serializer.fromJson<int>(json['stepIndex']),
      stepName: serializer.fromJson<String>(json['stepName']),
      status: serializer.fromJson<String>(json['status']),
      inputData: serializer.fromJson<String?>(json['inputData']),
      outputData: serializer.fromJson<String?>(json['outputData']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      attempt: serializer.fromJson<int>(json['attempt']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      compensateRef: serializer.fromJson<String?>(json['compensateRef']),
      startedAt: serializer.fromJson<String?>(json['startedAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workflowExecutionId': serializer.toJson<String>(workflowExecutionId),
      'stepIndex': serializer.toJson<int>(stepIndex),
      'stepName': serializer.toJson<String>(stepName),
      'status': serializer.toJson<String>(status),
      'inputData': serializer.toJson<String?>(inputData),
      'outputData': serializer.toJson<String?>(outputData),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'attempt': serializer.toJson<int>(attempt),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'compensateRef': serializer.toJson<String?>(compensateRef),
      'startedAt': serializer.toJson<String?>(startedAt),
      'completedAt': serializer.toJson<String?>(completedAt),
    };
  }

  StepCheckpoint copyWith(
          {int? id,
          String? workflowExecutionId,
          int? stepIndex,
          String? stepName,
          String? status,
          Value<String?> inputData = const Value.absent(),
          Value<String?> outputData = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          int? attempt,
          Value<String?> idempotencyKey = const Value.absent(),
          Value<String?> compensateRef = const Value.absent(),
          Value<String?> startedAt = const Value.absent(),
          Value<String?> completedAt = const Value.absent()}) =>
      StepCheckpoint(
        id: id ?? this.id,
        workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
        stepIndex: stepIndex ?? this.stepIndex,
        stepName: stepName ?? this.stepName,
        status: status ?? this.status,
        inputData: inputData.present ? inputData.value : this.inputData,
        outputData: outputData.present ? outputData.value : this.outputData,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        attempt: attempt ?? this.attempt,
        idempotencyKey:
            idempotencyKey.present ? idempotencyKey.value : this.idempotencyKey,
        compensateRef:
            compensateRef.present ? compensateRef.value : this.compensateRef,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  StepCheckpoint copyWithCompanion(StepCheckpointsCompanion data) {
    return StepCheckpoint(
      id: data.id.present ? data.id.value : this.id,
      workflowExecutionId: data.workflowExecutionId.present
          ? data.workflowExecutionId.value
          : this.workflowExecutionId,
      stepIndex: data.stepIndex.present ? data.stepIndex.value : this.stepIndex,
      stepName: data.stepName.present ? data.stepName.value : this.stepName,
      status: data.status.present ? data.status.value : this.status,
      inputData: data.inputData.present ? data.inputData.value : this.inputData,
      outputData:
          data.outputData.present ? data.outputData.value : this.outputData,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      compensateRef: data.compensateRef.present
          ? data.compensateRef.value
          : this.compensateRef,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepCheckpoint(')
          ..write('id: $id, ')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('stepName: $stepName, ')
          ..write('status: $status, ')
          ..write('inputData: $inputData, ')
          ..write('outputData: $outputData, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('attempt: $attempt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('compensateRef: $compensateRef, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

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
      idempotencyKey,
      compensateRef,
      startedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepCheckpoint &&
          other.id == this.id &&
          other.workflowExecutionId == this.workflowExecutionId &&
          other.stepIndex == this.stepIndex &&
          other.stepName == this.stepName &&
          other.status == this.status &&
          other.inputData == this.inputData &&
          other.outputData == this.outputData &&
          other.errorMessage == this.errorMessage &&
          other.attempt == this.attempt &&
          other.idempotencyKey == this.idempotencyKey &&
          other.compensateRef == this.compensateRef &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class StepCheckpointsCompanion extends UpdateCompanion<StepCheckpoint> {
  final Value<int> id;
  final Value<String> workflowExecutionId;
  final Value<int> stepIndex;
  final Value<String> stepName;
  final Value<String> status;
  final Value<String?> inputData;
  final Value<String?> outputData;
  final Value<String?> errorMessage;
  final Value<int> attempt;
  final Value<String?> idempotencyKey;
  final Value<String?> compensateRef;
  final Value<String?> startedAt;
  final Value<String?> completedAt;
  const StepCheckpointsCompanion({
    this.id = const Value.absent(),
    this.workflowExecutionId = const Value.absent(),
    this.stepIndex = const Value.absent(),
    this.stepName = const Value.absent(),
    this.status = const Value.absent(),
    this.inputData = const Value.absent(),
    this.outputData = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.attempt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.compensateRef = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  StepCheckpointsCompanion.insert({
    this.id = const Value.absent(),
    required String workflowExecutionId,
    required int stepIndex,
    required String stepName,
    required String status,
    this.inputData = const Value.absent(),
    this.outputData = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.attempt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.compensateRef = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  })  : workflowExecutionId = Value(workflowExecutionId),
        stepIndex = Value(stepIndex),
        stepName = Value(stepName),
        status = Value(status);
  static Insertable<StepCheckpoint> custom({
    Expression<int>? id,
    Expression<String>? workflowExecutionId,
    Expression<int>? stepIndex,
    Expression<String>? stepName,
    Expression<String>? status,
    Expression<String>? inputData,
    Expression<String>? outputData,
    Expression<String>? errorMessage,
    Expression<int>? attempt,
    Expression<String>? idempotencyKey,
    Expression<String>? compensateRef,
    Expression<String>? startedAt,
    Expression<String>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workflowExecutionId != null)
        'workflow_execution_id': workflowExecutionId,
      if (stepIndex != null) 'step_index': stepIndex,
      if (stepName != null) 'step_name': stepName,
      if (status != null) 'status': status,
      if (inputData != null) 'input_data': inputData,
      if (outputData != null) 'output_data': outputData,
      if (errorMessage != null) 'error_message': errorMessage,
      if (attempt != null) 'attempt': attempt,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (compensateRef != null) 'compensate_ref': compensateRef,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  StepCheckpointsCompanion copyWith(
      {Value<int>? id,
      Value<String>? workflowExecutionId,
      Value<int>? stepIndex,
      Value<String>? stepName,
      Value<String>? status,
      Value<String?>? inputData,
      Value<String?>? outputData,
      Value<String?>? errorMessage,
      Value<int>? attempt,
      Value<String?>? idempotencyKey,
      Value<String?>? compensateRef,
      Value<String?>? startedAt,
      Value<String?>? completedAt}) {
    return StepCheckpointsCompanion(
      id: id ?? this.id,
      workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
      stepIndex: stepIndex ?? this.stepIndex,
      stepName: stepName ?? this.stepName,
      status: status ?? this.status,
      inputData: inputData ?? this.inputData,
      outputData: outputData ?? this.outputData,
      errorMessage: errorMessage ?? this.errorMessage,
      attempt: attempt ?? this.attempt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      compensateRef: compensateRef ?? this.compensateRef,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workflowExecutionId.present) {
      map['workflow_execution_id'] =
          Variable<String>(workflowExecutionId.value);
    }
    if (stepIndex.present) {
      map['step_index'] = Variable<int>(stepIndex.value);
    }
    if (stepName.present) {
      map['step_name'] = Variable<String>(stepName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (inputData.present) {
      map['input_data'] = Variable<String>(inputData.value);
    }
    if (outputData.present) {
      map['output_data'] = Variable<String>(outputData.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (compensateRef.present) {
      map['compensate_ref'] = Variable<String>(compensateRef.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepCheckpointsCompanion(')
          ..write('id: $id, ')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('stepName: $stepName, ')
          ..write('status: $status, ')
          ..write('inputData: $inputData, ')
          ..write('outputData: $outputData, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('attempt: $attempt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('compensateRef: $compensateRef, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $WorkflowTimersTable extends WorkflowTimers
    with TableInfo<$WorkflowTimersTable, WorkflowTimer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkflowTimersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workflowTimerIdMeta =
      const VerificationMeta('workflowTimerId');
  @override
  late final GeneratedColumn<String> workflowTimerId = GeneratedColumn<String>(
      'workflow_timer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workflowExecutionIdMeta =
      const VerificationMeta('workflowExecutionId');
  @override
  late final GeneratedColumn<String> workflowExecutionId =
      GeneratedColumn<String>('workflow_execution_id', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES workflow_executions (workflow_execution_id)'));
  static const VerificationMeta _stepNameMeta =
      const VerificationMeta('stepName');
  @override
  late final GeneratedColumn<String> stepName = GeneratedColumn<String>(
      'step_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fireAtMeta = const VerificationMeta('fireAt');
  @override
  late final GeneratedColumn<String> fireAt = GeneratedColumn<String>(
      'fire_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        workflowTimerId,
        workflowExecutionId,
        stepName,
        fireAt,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workflow_timers';
  @override
  VerificationContext validateIntegrity(Insertable<WorkflowTimer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workflow_timer_id')) {
      context.handle(
          _workflowTimerIdMeta,
          workflowTimerId.isAcceptableOrUnknown(
              data['workflow_timer_id']!, _workflowTimerIdMeta));
    } else if (isInserting) {
      context.missing(_workflowTimerIdMeta);
    }
    if (data.containsKey('workflow_execution_id')) {
      context.handle(
          _workflowExecutionIdMeta,
          workflowExecutionId.isAcceptableOrUnknown(
              data['workflow_execution_id']!, _workflowExecutionIdMeta));
    } else if (isInserting) {
      context.missing(_workflowExecutionIdMeta);
    }
    if (data.containsKey('step_name')) {
      context.handle(_stepNameMeta,
          stepName.isAcceptableOrUnknown(data['step_name']!, _stepNameMeta));
    } else if (isInserting) {
      context.missing(_stepNameMeta);
    }
    if (data.containsKey('fire_at')) {
      context.handle(_fireAtMeta,
          fireAt.isAcceptableOrUnknown(data['fire_at']!, _fireAtMeta));
    } else if (isInserting) {
      context.missing(_fireAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workflowTimerId};
  @override
  WorkflowTimer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkflowTimer(
      workflowTimerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}workflow_timer_id'])!,
      workflowExecutionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}workflow_execution_id'])!,
      stepName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}step_name'])!,
      fireAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fire_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WorkflowTimersTable createAlias(String alias) {
    return $WorkflowTimersTable(attachedDatabase, alias);
  }
}

class WorkflowTimer extends DataClass implements Insertable<WorkflowTimer> {
  final String workflowTimerId;
  final String workflowExecutionId;
  final String stepName;
  final String fireAt;
  final String status;
  final String createdAt;
  const WorkflowTimer(
      {required this.workflowTimerId,
      required this.workflowExecutionId,
      required this.stepName,
      required this.fireAt,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workflow_timer_id'] = Variable<String>(workflowTimerId);
    map['workflow_execution_id'] = Variable<String>(workflowExecutionId);
    map['step_name'] = Variable<String>(stepName);
    map['fire_at'] = Variable<String>(fireAt);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  WorkflowTimersCompanion toCompanion(bool nullToAbsent) {
    return WorkflowTimersCompanion(
      workflowTimerId: Value(workflowTimerId),
      workflowExecutionId: Value(workflowExecutionId),
      stepName: Value(stepName),
      fireAt: Value(fireAt),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory WorkflowTimer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkflowTimer(
      workflowTimerId: serializer.fromJson<String>(json['workflowTimerId']),
      workflowExecutionId:
          serializer.fromJson<String>(json['workflowExecutionId']),
      stepName: serializer.fromJson<String>(json['stepName']),
      fireAt: serializer.fromJson<String>(json['fireAt']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workflowTimerId': serializer.toJson<String>(workflowTimerId),
      'workflowExecutionId': serializer.toJson<String>(workflowExecutionId),
      'stepName': serializer.toJson<String>(stepName),
      'fireAt': serializer.toJson<String>(fireAt),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  WorkflowTimer copyWith(
          {String? workflowTimerId,
          String? workflowExecutionId,
          String? stepName,
          String? fireAt,
          String? status,
          String? createdAt}) =>
      WorkflowTimer(
        workflowTimerId: workflowTimerId ?? this.workflowTimerId,
        workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
        stepName: stepName ?? this.stepName,
        fireAt: fireAt ?? this.fireAt,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  WorkflowTimer copyWithCompanion(WorkflowTimersCompanion data) {
    return WorkflowTimer(
      workflowTimerId: data.workflowTimerId.present
          ? data.workflowTimerId.value
          : this.workflowTimerId,
      workflowExecutionId: data.workflowExecutionId.present
          ? data.workflowExecutionId.value
          : this.workflowExecutionId,
      stepName: data.stepName.present ? data.stepName.value : this.stepName,
      fireAt: data.fireAt.present ? data.fireAt.value : this.fireAt,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowTimer(')
          ..write('workflowTimerId: $workflowTimerId, ')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('stepName: $stepName, ')
          ..write('fireAt: $fireAt, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workflowTimerId, workflowExecutionId,
      stepName, fireAt, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkflowTimer &&
          other.workflowTimerId == this.workflowTimerId &&
          other.workflowExecutionId == this.workflowExecutionId &&
          other.stepName == this.stepName &&
          other.fireAt == this.fireAt &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class WorkflowTimersCompanion extends UpdateCompanion<WorkflowTimer> {
  final Value<String> workflowTimerId;
  final Value<String> workflowExecutionId;
  final Value<String> stepName;
  final Value<String> fireAt;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<int> rowid;
  const WorkflowTimersCompanion({
    this.workflowTimerId = const Value.absent(),
    this.workflowExecutionId = const Value.absent(),
    this.stepName = const Value.absent(),
    this.fireAt = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkflowTimersCompanion.insert({
    required String workflowTimerId,
    required String workflowExecutionId,
    required String stepName,
    required String fireAt,
    this.status = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : workflowTimerId = Value(workflowTimerId),
        workflowExecutionId = Value(workflowExecutionId),
        stepName = Value(stepName),
        fireAt = Value(fireAt),
        createdAt = Value(createdAt);
  static Insertable<WorkflowTimer> custom({
    Expression<String>? workflowTimerId,
    Expression<String>? workflowExecutionId,
    Expression<String>? stepName,
    Expression<String>? fireAt,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workflowTimerId != null) 'workflow_timer_id': workflowTimerId,
      if (workflowExecutionId != null)
        'workflow_execution_id': workflowExecutionId,
      if (stepName != null) 'step_name': stepName,
      if (fireAt != null) 'fire_at': fireAt,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkflowTimersCompanion copyWith(
      {Value<String>? workflowTimerId,
      Value<String>? workflowExecutionId,
      Value<String>? stepName,
      Value<String>? fireAt,
      Value<String>? status,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return WorkflowTimersCompanion(
      workflowTimerId: workflowTimerId ?? this.workflowTimerId,
      workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
      stepName: stepName ?? this.stepName,
      fireAt: fireAt ?? this.fireAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workflowTimerId.present) {
      map['workflow_timer_id'] = Variable<String>(workflowTimerId.value);
    }
    if (workflowExecutionId.present) {
      map['workflow_execution_id'] =
          Variable<String>(workflowExecutionId.value);
    }
    if (stepName.present) {
      map['step_name'] = Variable<String>(stepName.value);
    }
    if (fireAt.present) {
      map['fire_at'] = Variable<String>(fireAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowTimersCompanion(')
          ..write('workflowTimerId: $workflowTimerId, ')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('stepName: $stepName, ')
          ..write('fireAt: $fireAt, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkflowSignalsTable extends WorkflowSignals
    with TableInfo<$WorkflowSignalsTable, WorkflowSignal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkflowSignalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workflowSignalIdMeta =
      const VerificationMeta('workflowSignalId');
  @override
  late final GeneratedColumn<int> workflowSignalId = GeneratedColumn<int>(
      'workflow_signal_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _workflowExecutionIdMeta =
      const VerificationMeta('workflowExecutionId');
  @override
  late final GeneratedColumn<String> workflowExecutionId =
      GeneratedColumn<String>('workflow_execution_id', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES workflow_executions (workflow_execution_id)'));
  static const VerificationMeta _signalNameMeta =
      const VerificationMeta('signalName');
  @override
  late final GeneratedColumn<String> signalName = GeneratedColumn<String>(
      'signal_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        workflowSignalId,
        workflowExecutionId,
        signalName,
        payload,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workflow_signals';
  @override
  VerificationContext validateIntegrity(Insertable<WorkflowSignal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workflow_signal_id')) {
      context.handle(
          _workflowSignalIdMeta,
          workflowSignalId.isAcceptableOrUnknown(
              data['workflow_signal_id']!, _workflowSignalIdMeta));
    }
    if (data.containsKey('workflow_execution_id')) {
      context.handle(
          _workflowExecutionIdMeta,
          workflowExecutionId.isAcceptableOrUnknown(
              data['workflow_execution_id']!, _workflowExecutionIdMeta));
    } else if (isInserting) {
      context.missing(_workflowExecutionIdMeta);
    }
    if (data.containsKey('signal_name')) {
      context.handle(
          _signalNameMeta,
          signalName.isAcceptableOrUnknown(
              data['signal_name']!, _signalNameMeta));
    } else if (isInserting) {
      context.missing(_signalNameMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workflowSignalId};
  @override
  WorkflowSignal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkflowSignal(
      workflowSignalId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}workflow_signal_id'])!,
      workflowExecutionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}workflow_execution_id'])!,
      signalName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signal_name'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WorkflowSignalsTable createAlias(String alias) {
    return $WorkflowSignalsTable(attachedDatabase, alias);
  }
}

class WorkflowSignal extends DataClass implements Insertable<WorkflowSignal> {
  final int workflowSignalId;
  final String workflowExecutionId;
  final String signalName;
  final String? payload;
  final String status;
  final String createdAt;
  const WorkflowSignal(
      {required this.workflowSignalId,
      required this.workflowExecutionId,
      required this.signalName,
      this.payload,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workflow_signal_id'] = Variable<int>(workflowSignalId);
    map['workflow_execution_id'] = Variable<String>(workflowExecutionId);
    map['signal_name'] = Variable<String>(signalName);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  WorkflowSignalsCompanion toCompanion(bool nullToAbsent) {
    return WorkflowSignalsCompanion(
      workflowSignalId: Value(workflowSignalId),
      workflowExecutionId: Value(workflowExecutionId),
      signalName: Value(signalName),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory WorkflowSignal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkflowSignal(
      workflowSignalId: serializer.fromJson<int>(json['workflowSignalId']),
      workflowExecutionId:
          serializer.fromJson<String>(json['workflowExecutionId']),
      signalName: serializer.fromJson<String>(json['signalName']),
      payload: serializer.fromJson<String?>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workflowSignalId': serializer.toJson<int>(workflowSignalId),
      'workflowExecutionId': serializer.toJson<String>(workflowExecutionId),
      'signalName': serializer.toJson<String>(signalName),
      'payload': serializer.toJson<String?>(payload),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  WorkflowSignal copyWith(
          {int? workflowSignalId,
          String? workflowExecutionId,
          String? signalName,
          Value<String?> payload = const Value.absent(),
          String? status,
          String? createdAt}) =>
      WorkflowSignal(
        workflowSignalId: workflowSignalId ?? this.workflowSignalId,
        workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
        signalName: signalName ?? this.signalName,
        payload: payload.present ? payload.value : this.payload,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  WorkflowSignal copyWithCompanion(WorkflowSignalsCompanion data) {
    return WorkflowSignal(
      workflowSignalId: data.workflowSignalId.present
          ? data.workflowSignalId.value
          : this.workflowSignalId,
      workflowExecutionId: data.workflowExecutionId.present
          ? data.workflowExecutionId.value
          : this.workflowExecutionId,
      signalName:
          data.signalName.present ? data.signalName.value : this.signalName,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowSignal(')
          ..write('workflowSignalId: $workflowSignalId, ')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('signalName: $signalName, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workflowSignalId, workflowExecutionId,
      signalName, payload, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkflowSignal &&
          other.workflowSignalId == this.workflowSignalId &&
          other.workflowExecutionId == this.workflowExecutionId &&
          other.signalName == this.signalName &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class WorkflowSignalsCompanion extends UpdateCompanion<WorkflowSignal> {
  final Value<int> workflowSignalId;
  final Value<String> workflowExecutionId;
  final Value<String> signalName;
  final Value<String?> payload;
  final Value<String> status;
  final Value<String> createdAt;
  const WorkflowSignalsCompanion({
    this.workflowSignalId = const Value.absent(),
    this.workflowExecutionId = const Value.absent(),
    this.signalName = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkflowSignalsCompanion.insert({
    this.workflowSignalId = const Value.absent(),
    required String workflowExecutionId,
    required String signalName,
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    required String createdAt,
  })  : workflowExecutionId = Value(workflowExecutionId),
        signalName = Value(signalName),
        createdAt = Value(createdAt);
  static Insertable<WorkflowSignal> custom({
    Expression<int>? workflowSignalId,
    Expression<String>? workflowExecutionId,
    Expression<String>? signalName,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (workflowSignalId != null) 'workflow_signal_id': workflowSignalId,
      if (workflowExecutionId != null)
        'workflow_execution_id': workflowExecutionId,
      if (signalName != null) 'signal_name': signalName,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkflowSignalsCompanion copyWith(
      {Value<int>? workflowSignalId,
      Value<String>? workflowExecutionId,
      Value<String>? signalName,
      Value<String?>? payload,
      Value<String>? status,
      Value<String>? createdAt}) {
    return WorkflowSignalsCompanion(
      workflowSignalId: workflowSignalId ?? this.workflowSignalId,
      workflowExecutionId: workflowExecutionId ?? this.workflowExecutionId,
      signalName: signalName ?? this.signalName,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workflowSignalId.present) {
      map['workflow_signal_id'] = Variable<int>(workflowSignalId.value);
    }
    if (workflowExecutionId.present) {
      map['workflow_execution_id'] =
          Variable<String>(workflowExecutionId.value);
    }
    if (signalName.present) {
      map['signal_name'] = Variable<String>(signalName.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowSignalsCompanion(')
          ..write('workflowSignalId: $workflowSignalId, ')
          ..write('workflowExecutionId: $workflowExecutionId, ')
          ..write('signalName: $signalName, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$DurableWorkflowDatabase extends GeneratedDatabase {
  _$DurableWorkflowDatabase(QueryExecutor e) : super(e);
  $DurableWorkflowDatabaseManager get managers =>
      $DurableWorkflowDatabaseManager(this);
  late final $WorkflowsTable workflows = $WorkflowsTable(this);
  late final $WorkflowExecutionsTable workflowExecutions =
      $WorkflowExecutionsTable(this);
  late final $StepCheckpointsTable stepCheckpoints =
      $StepCheckpointsTable(this);
  late final $WorkflowTimersTable workflowTimers = $WorkflowTimersTable(this);
  late final $WorkflowSignalsTable workflowSignals =
      $WorkflowSignalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        workflows,
        workflowExecutions,
        stepCheckpoints,
        workflowTimers,
        workflowSignals
      ];
}

typedef $$WorkflowsTableCreateCompanionBuilder = WorkflowsCompanion Function({
  required String workflowId,
  required String workflowType,
  Value<int> version,
  required String createdAt,
  Value<int> rowid,
});
typedef $$WorkflowsTableUpdateCompanionBuilder = WorkflowsCompanion Function({
  Value<String> workflowId,
  Value<String> workflowType,
  Value<int> version,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$WorkflowsTableReferences extends BaseReferences<
    _$DurableWorkflowDatabase, $WorkflowsTable, Workflow> {
  $$WorkflowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkflowExecutionsTable, List<WorkflowExecution>>
      _workflowExecutionsRefsTable(_$DurableWorkflowDatabase db) =>
          MultiTypedResultKey.fromTable(db.workflowExecutions,
              aliasName: $_aliasNameGenerator(
                  db.workflows.workflowId, db.workflowExecutions.workflowId));

  $$WorkflowExecutionsTableProcessedTableManager get workflowExecutionsRefs {
    final manager =
        $$WorkflowExecutionsTableTableManager($_db, $_db.workflowExecutions)
            .filter((f) => f.workflowId.workflowId
                .sqlEquals($_itemColumn<String>('workflow_id')!));

    final cache =
        $_typedResult.readTableOrNull(_workflowExecutionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkflowsTableFilterComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowsTable> {
  $$WorkflowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workflowId => $composableBuilder(
      column: $table.workflowId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workflowType => $composableBuilder(
      column: $table.workflowType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> workflowExecutionsRefs(
      Expression<bool> Function($$WorkflowExecutionsTableFilterComposer f) f) {
    final $$WorkflowExecutionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowId,
        referencedTable: $db.workflowExecutions,
        getReferencedColumn: (t) => t.workflowId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowExecutionsTableFilterComposer(
              $db: $db,
              $table: $db.workflowExecutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkflowsTableOrderingComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowsTable> {
  $$WorkflowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workflowId => $composableBuilder(
      column: $table.workflowId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workflowType => $composableBuilder(
      column: $table.workflowType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkflowsTableAnnotationComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowsTable> {
  $$WorkflowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workflowId => $composableBuilder(
      column: $table.workflowId, builder: (column) => column);

  GeneratedColumn<String> get workflowType => $composableBuilder(
      column: $table.workflowType, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> workflowExecutionsRefs<T extends Object>(
      Expression<T> Function($$WorkflowExecutionsTableAnnotationComposer a) f) {
    final $$WorkflowExecutionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.workflowId,
            referencedTable: $db.workflowExecutions,
            getReferencedColumn: (t) => t.workflowId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$WorkflowExecutionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.workflowExecutions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$WorkflowsTableTableManager extends RootTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowsTable,
    Workflow,
    $$WorkflowsTableFilterComposer,
    $$WorkflowsTableOrderingComposer,
    $$WorkflowsTableAnnotationComposer,
    $$WorkflowsTableCreateCompanionBuilder,
    $$WorkflowsTableUpdateCompanionBuilder,
    (Workflow, $$WorkflowsTableReferences),
    Workflow,
    PrefetchHooks Function({bool workflowExecutionsRefs})> {
  $$WorkflowsTableTableManager(
      _$DurableWorkflowDatabase db, $WorkflowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkflowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkflowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkflowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> workflowId = const Value.absent(),
            Value<String> workflowType = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkflowsCompanion(
            workflowId: workflowId,
            workflowType: workflowType,
            version: version,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String workflowId,
            required String workflowType,
            Value<int> version = const Value.absent(),
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkflowsCompanion.insert(
            workflowId: workflowId,
            workflowType: workflowType,
            version: version,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkflowsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workflowExecutionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workflowExecutionsRefs) db.workflowExecutions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workflowExecutionsRefs)
                    await $_getPrefetchedData<Workflow, $WorkflowsTable,
                            WorkflowExecution>(
                        currentTable: table,
                        referencedTable: $$WorkflowsTableReferences
                            ._workflowExecutionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkflowsTableReferences(db, table, p0)
                                .workflowExecutionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workflowId == item.workflowId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkflowsTableProcessedTableManager = ProcessedTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowsTable,
    Workflow,
    $$WorkflowsTableFilterComposer,
    $$WorkflowsTableOrderingComposer,
    $$WorkflowsTableAnnotationComposer,
    $$WorkflowsTableCreateCompanionBuilder,
    $$WorkflowsTableUpdateCompanionBuilder,
    (Workflow, $$WorkflowsTableReferences),
    Workflow,
    PrefetchHooks Function({bool workflowExecutionsRefs})>;
typedef $$WorkflowExecutionsTableCreateCompanionBuilder
    = WorkflowExecutionsCompanion Function({
  required String workflowExecutionId,
  required String workflowId,
  Value<String> status,
  Value<int> currentStep,
  Value<String?> inputData,
  Value<String?> outputData,
  Value<String?> errorMessage,
  Value<String?> ttlExpiresAt,
  Value<String> guarantee,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$WorkflowExecutionsTableUpdateCompanionBuilder
    = WorkflowExecutionsCompanion Function({
  Value<String> workflowExecutionId,
  Value<String> workflowId,
  Value<String> status,
  Value<int> currentStep,
  Value<String?> inputData,
  Value<String?> outputData,
  Value<String?> errorMessage,
  Value<String?> ttlExpiresAt,
  Value<String> guarantee,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$WorkflowExecutionsTableReferences extends BaseReferences<
    _$DurableWorkflowDatabase, $WorkflowExecutionsTable, WorkflowExecution> {
  $$WorkflowExecutionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkflowsTable _workflowIdTable(_$DurableWorkflowDatabase db) =>
      db.workflows.createAlias($_aliasNameGenerator(
          db.workflowExecutions.workflowId, db.workflows.workflowId));

  $$WorkflowsTableProcessedTableManager get workflowId {
    final $_column = $_itemColumn<String>('workflow_id')!;

    final manager = $$WorkflowsTableTableManager($_db, $_db.workflows)
        .filter((f) => f.workflowId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workflowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$StepCheckpointsTable, List<StepCheckpoint>>
      _stepCheckpointsRefsTable(_$DurableWorkflowDatabase db) =>
          MultiTypedResultKey.fromTable(db.stepCheckpoints,
              aliasName: $_aliasNameGenerator(
                  db.workflowExecutions.workflowExecutionId,
                  db.stepCheckpoints.workflowExecutionId));

  $$StepCheckpointsTableProcessedTableManager get stepCheckpointsRefs {
    final manager =
        $$StepCheckpointsTableTableManager($_db, $_db.stepCheckpoints).filter(
            (f) => f.workflowExecutionId.workflowExecutionId
                .sqlEquals($_itemColumn<String>('workflow_execution_id')!));

    final cache =
        $_typedResult.readTableOrNull(_stepCheckpointsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkflowTimersTable, List<WorkflowTimer>>
      _workflowTimersRefsTable(_$DurableWorkflowDatabase db) =>
          MultiTypedResultKey.fromTable(db.workflowTimers,
              aliasName: $_aliasNameGenerator(
                  db.workflowExecutions.workflowExecutionId,
                  db.workflowTimers.workflowExecutionId));

  $$WorkflowTimersTableProcessedTableManager get workflowTimersRefs {
    final manager = $$WorkflowTimersTableTableManager($_db, $_db.workflowTimers)
        .filter((f) => f.workflowExecutionId.workflowExecutionId
            .sqlEquals($_itemColumn<String>('workflow_execution_id')!));

    final cache = $_typedResult.readTableOrNull(_workflowTimersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkflowSignalsTable, List<WorkflowSignal>>
      _workflowSignalsRefsTable(_$DurableWorkflowDatabase db) =>
          MultiTypedResultKey.fromTable(db.workflowSignals,
              aliasName: $_aliasNameGenerator(
                  db.workflowExecutions.workflowExecutionId,
                  db.workflowSignals.workflowExecutionId));

  $$WorkflowSignalsTableProcessedTableManager get workflowSignalsRefs {
    final manager =
        $$WorkflowSignalsTableTableManager($_db, $_db.workflowSignals).filter(
            (f) => f.workflowExecutionId.workflowExecutionId
                .sqlEquals($_itemColumn<String>('workflow_execution_id')!));

    final cache =
        $_typedResult.readTableOrNull(_workflowSignalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkflowExecutionsTableFilterComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowExecutionsTable> {
  $$WorkflowExecutionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workflowExecutionId => $composableBuilder(
      column: $table.workflowExecutionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStep => $composableBuilder(
      column: $table.currentStep, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inputData => $composableBuilder(
      column: $table.inputData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outputData => $composableBuilder(
      column: $table.outputData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ttlExpiresAt => $composableBuilder(
      column: $table.ttlExpiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get guarantee => $composableBuilder(
      column: $table.guarantee, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$WorkflowsTableFilterComposer get workflowId {
    final $$WorkflowsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowId,
        referencedTable: $db.workflows,
        getReferencedColumn: (t) => t.workflowId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowsTableFilterComposer(
              $db: $db,
              $table: $db.workflows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> stepCheckpointsRefs(
      Expression<bool> Function($$StepCheckpointsTableFilterComposer f) f) {
    final $$StepCheckpointsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.stepCheckpoints,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StepCheckpointsTableFilterComposer(
              $db: $db,
              $table: $db.stepCheckpoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workflowTimersRefs(
      Expression<bool> Function($$WorkflowTimersTableFilterComposer f) f) {
    final $$WorkflowTimersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowTimers,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowTimersTableFilterComposer(
              $db: $db,
              $table: $db.workflowTimers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workflowSignalsRefs(
      Expression<bool> Function($$WorkflowSignalsTableFilterComposer f) f) {
    final $$WorkflowSignalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowSignals,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowSignalsTableFilterComposer(
              $db: $db,
              $table: $db.workflowSignals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkflowExecutionsTableOrderingComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowExecutionsTable> {
  $$WorkflowExecutionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workflowExecutionId => $composableBuilder(
      column: $table.workflowExecutionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStep => $composableBuilder(
      column: $table.currentStep, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inputData => $composableBuilder(
      column: $table.inputData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outputData => $composableBuilder(
      column: $table.outputData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ttlExpiresAt => $composableBuilder(
      column: $table.ttlExpiresAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get guarantee => $composableBuilder(
      column: $table.guarantee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$WorkflowsTableOrderingComposer get workflowId {
    final $$WorkflowsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowId,
        referencedTable: $db.workflows,
        getReferencedColumn: (t) => t.workflowId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowsTableOrderingComposer(
              $db: $db,
              $table: $db.workflows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkflowExecutionsTableAnnotationComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowExecutionsTable> {
  $$WorkflowExecutionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workflowExecutionId => $composableBuilder(
      column: $table.workflowExecutionId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get currentStep => $composableBuilder(
      column: $table.currentStep, builder: (column) => column);

  GeneratedColumn<String> get inputData =>
      $composableBuilder(column: $table.inputData, builder: (column) => column);

  GeneratedColumn<String> get outputData => $composableBuilder(
      column: $table.outputData, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<String> get ttlExpiresAt => $composableBuilder(
      column: $table.ttlExpiresAt, builder: (column) => column);

  GeneratedColumn<String> get guarantee =>
      $composableBuilder(column: $table.guarantee, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkflowsTableAnnotationComposer get workflowId {
    final $$WorkflowsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowId,
        referencedTable: $db.workflows,
        getReferencedColumn: (t) => t.workflowId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowsTableAnnotationComposer(
              $db: $db,
              $table: $db.workflows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> stepCheckpointsRefs<T extends Object>(
      Expression<T> Function($$StepCheckpointsTableAnnotationComposer a) f) {
    final $$StepCheckpointsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.stepCheckpoints,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StepCheckpointsTableAnnotationComposer(
              $db: $db,
              $table: $db.stepCheckpoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workflowTimersRefs<T extends Object>(
      Expression<T> Function($$WorkflowTimersTableAnnotationComposer a) f) {
    final $$WorkflowTimersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowTimers,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowTimersTableAnnotationComposer(
              $db: $db,
              $table: $db.workflowTimers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workflowSignalsRefs<T extends Object>(
      Expression<T> Function($$WorkflowSignalsTableAnnotationComposer a) f) {
    final $$WorkflowSignalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowSignals,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowSignalsTableAnnotationComposer(
              $db: $db,
              $table: $db.workflowSignals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkflowExecutionsTableTableManager extends RootTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowExecutionsTable,
    WorkflowExecution,
    $$WorkflowExecutionsTableFilterComposer,
    $$WorkflowExecutionsTableOrderingComposer,
    $$WorkflowExecutionsTableAnnotationComposer,
    $$WorkflowExecutionsTableCreateCompanionBuilder,
    $$WorkflowExecutionsTableUpdateCompanionBuilder,
    (WorkflowExecution, $$WorkflowExecutionsTableReferences),
    WorkflowExecution,
    PrefetchHooks Function(
        {bool workflowId,
        bool stepCheckpointsRefs,
        bool workflowTimersRefs,
        bool workflowSignalsRefs})> {
  $$WorkflowExecutionsTableTableManager(
      _$DurableWorkflowDatabase db, $WorkflowExecutionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkflowExecutionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkflowExecutionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkflowExecutionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> workflowExecutionId = const Value.absent(),
            Value<String> workflowId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> currentStep = const Value.absent(),
            Value<String?> inputData = const Value.absent(),
            Value<String?> outputData = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> ttlExpiresAt = const Value.absent(),
            Value<String> guarantee = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkflowExecutionsCompanion(
            workflowExecutionId: workflowExecutionId,
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
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String workflowExecutionId,
            required String workflowId,
            Value<String> status = const Value.absent(),
            Value<int> currentStep = const Value.absent(),
            Value<String?> inputData = const Value.absent(),
            Value<String?> outputData = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> ttlExpiresAt = const Value.absent(),
            Value<String> guarantee = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkflowExecutionsCompanion.insert(
            workflowExecutionId: workflowExecutionId,
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
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkflowExecutionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {workflowId = false,
              stepCheckpointsRefs = false,
              workflowTimersRefs = false,
              workflowSignalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stepCheckpointsRefs) db.stepCheckpoints,
                if (workflowTimersRefs) db.workflowTimers,
                if (workflowSignalsRefs) db.workflowSignals
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workflowId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workflowId,
                    referencedTable: $$WorkflowExecutionsTableReferences
                        ._workflowIdTable(db),
                    referencedColumn: $$WorkflowExecutionsTableReferences
                        ._workflowIdTable(db)
                        .workflowId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stepCheckpointsRefs)
                    await $_getPrefetchedData<WorkflowExecution,
                            $WorkflowExecutionsTable, StepCheckpoint>(
                        currentTable: table,
                        referencedTable: $$WorkflowExecutionsTableReferences
                            ._stepCheckpointsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkflowExecutionsTableReferences(db, table, p0)
                                .stepCheckpointsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.workflowExecutionId ==
                                    item.workflowExecutionId),
                        typedResults: items),
                  if (workflowTimersRefs)
                    await $_getPrefetchedData<WorkflowExecution,
                            $WorkflowExecutionsTable, WorkflowTimer>(
                        currentTable: table,
                        referencedTable: $$WorkflowExecutionsTableReferences
                            ._workflowTimersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkflowExecutionsTableReferences(db, table, p0)
                                .workflowTimersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.workflowExecutionId ==
                                    item.workflowExecutionId),
                        typedResults: items),
                  if (workflowSignalsRefs)
                    await $_getPrefetchedData<WorkflowExecution,
                            $WorkflowExecutionsTable, WorkflowSignal>(
                        currentTable: table,
                        referencedTable: $$WorkflowExecutionsTableReferences
                            ._workflowSignalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkflowExecutionsTableReferences(db, table, p0)
                                .workflowSignalsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.workflowExecutionId ==
                                    item.workflowExecutionId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkflowExecutionsTableProcessedTableManager = ProcessedTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowExecutionsTable,
    WorkflowExecution,
    $$WorkflowExecutionsTableFilterComposer,
    $$WorkflowExecutionsTableOrderingComposer,
    $$WorkflowExecutionsTableAnnotationComposer,
    $$WorkflowExecutionsTableCreateCompanionBuilder,
    $$WorkflowExecutionsTableUpdateCompanionBuilder,
    (WorkflowExecution, $$WorkflowExecutionsTableReferences),
    WorkflowExecution,
    PrefetchHooks Function(
        {bool workflowId,
        bool stepCheckpointsRefs,
        bool workflowTimersRefs,
        bool workflowSignalsRefs})>;
typedef $$StepCheckpointsTableCreateCompanionBuilder = StepCheckpointsCompanion
    Function({
  Value<int> id,
  required String workflowExecutionId,
  required int stepIndex,
  required String stepName,
  required String status,
  Value<String?> inputData,
  Value<String?> outputData,
  Value<String?> errorMessage,
  Value<int> attempt,
  Value<String?> idempotencyKey,
  Value<String?> compensateRef,
  Value<String?> startedAt,
  Value<String?> completedAt,
});
typedef $$StepCheckpointsTableUpdateCompanionBuilder = StepCheckpointsCompanion
    Function({
  Value<int> id,
  Value<String> workflowExecutionId,
  Value<int> stepIndex,
  Value<String> stepName,
  Value<String> status,
  Value<String?> inputData,
  Value<String?> outputData,
  Value<String?> errorMessage,
  Value<int> attempt,
  Value<String?> idempotencyKey,
  Value<String?> compensateRef,
  Value<String?> startedAt,
  Value<String?> completedAt,
});

final class $$StepCheckpointsTableReferences extends BaseReferences<
    _$DurableWorkflowDatabase, $StepCheckpointsTable, StepCheckpoint> {
  $$StepCheckpointsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkflowExecutionsTable _workflowExecutionIdTable(
          _$DurableWorkflowDatabase db) =>
      db.workflowExecutions.createAlias($_aliasNameGenerator(
          db.stepCheckpoints.workflowExecutionId,
          db.workflowExecutions.workflowExecutionId));

  $$WorkflowExecutionsTableProcessedTableManager get workflowExecutionId {
    final $_column = $_itemColumn<String>('workflow_execution_id')!;

    final manager =
        $$WorkflowExecutionsTableTableManager($_db, $_db.workflowExecutions)
            .filter((f) => f.workflowExecutionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workflowExecutionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StepCheckpointsTableFilterComposer
    extends Composer<_$DurableWorkflowDatabase, $StepCheckpointsTable> {
  $$StepCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepIndex => $composableBuilder(
      column: $table.stepIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stepName => $composableBuilder(
      column: $table.stepName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inputData => $composableBuilder(
      column: $table.inputData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outputData => $composableBuilder(
      column: $table.outputData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempt => $composableBuilder(
      column: $table.attempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get compensateRef => $composableBuilder(
      column: $table.compensateRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  $$WorkflowExecutionsTableFilterComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowExecutions,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowExecutionsTableFilterComposer(
              $db: $db,
              $table: $db.workflowExecutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StepCheckpointsTableOrderingComposer
    extends Composer<_$DurableWorkflowDatabase, $StepCheckpointsTable> {
  $$StepCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepIndex => $composableBuilder(
      column: $table.stepIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stepName => $composableBuilder(
      column: $table.stepName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inputData => $composableBuilder(
      column: $table.inputData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outputData => $composableBuilder(
      column: $table.outputData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempt => $composableBuilder(
      column: $table.attempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get compensateRef => $composableBuilder(
      column: $table.compensateRef,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  $$WorkflowExecutionsTableOrderingComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowExecutions,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowExecutionsTableOrderingComposer(
              $db: $db,
              $table: $db.workflowExecutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StepCheckpointsTableAnnotationComposer
    extends Composer<_$DurableWorkflowDatabase, $StepCheckpointsTable> {
  $$StepCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get stepIndex =>
      $composableBuilder(column: $table.stepIndex, builder: (column) => column);

  GeneratedColumn<String> get stepName =>
      $composableBuilder(column: $table.stepName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get inputData =>
      $composableBuilder(column: $table.inputData, builder: (column) => column);

  GeneratedColumn<String> get outputData => $composableBuilder(
      column: $table.outputData, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get compensateRef => $composableBuilder(
      column: $table.compensateRef, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  $$WorkflowExecutionsTableAnnotationComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.workflowExecutionId,
            referencedTable: $db.workflowExecutions,
            getReferencedColumn: (t) => t.workflowExecutionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$WorkflowExecutionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.workflowExecutions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$StepCheckpointsTableTableManager extends RootTableManager<
    _$DurableWorkflowDatabase,
    $StepCheckpointsTable,
    StepCheckpoint,
    $$StepCheckpointsTableFilterComposer,
    $$StepCheckpointsTableOrderingComposer,
    $$StepCheckpointsTableAnnotationComposer,
    $$StepCheckpointsTableCreateCompanionBuilder,
    $$StepCheckpointsTableUpdateCompanionBuilder,
    (StepCheckpoint, $$StepCheckpointsTableReferences),
    StepCheckpoint,
    PrefetchHooks Function({bool workflowExecutionId})> {
  $$StepCheckpointsTableTableManager(
      _$DurableWorkflowDatabase db, $StepCheckpointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> workflowExecutionId = const Value.absent(),
            Value<int> stepIndex = const Value.absent(),
            Value<String> stepName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> inputData = const Value.absent(),
            Value<String?> outputData = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> attempt = const Value.absent(),
            Value<String?> idempotencyKey = const Value.absent(),
            Value<String?> compensateRef = const Value.absent(),
            Value<String?> startedAt = const Value.absent(),
            Value<String?> completedAt = const Value.absent(),
          }) =>
              StepCheckpointsCompanion(
            id: id,
            workflowExecutionId: workflowExecutionId,
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
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String workflowExecutionId,
            required int stepIndex,
            required String stepName,
            required String status,
            Value<String?> inputData = const Value.absent(),
            Value<String?> outputData = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> attempt = const Value.absent(),
            Value<String?> idempotencyKey = const Value.absent(),
            Value<String?> compensateRef = const Value.absent(),
            Value<String?> startedAt = const Value.absent(),
            Value<String?> completedAt = const Value.absent(),
          }) =>
              StepCheckpointsCompanion.insert(
            id: id,
            workflowExecutionId: workflowExecutionId,
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
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StepCheckpointsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workflowExecutionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workflowExecutionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workflowExecutionId,
                    referencedTable: $$StepCheckpointsTableReferences
                        ._workflowExecutionIdTable(db),
                    referencedColumn: $$StepCheckpointsTableReferences
                        ._workflowExecutionIdTable(db)
                        .workflowExecutionId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StepCheckpointsTableProcessedTableManager = ProcessedTableManager<
    _$DurableWorkflowDatabase,
    $StepCheckpointsTable,
    StepCheckpoint,
    $$StepCheckpointsTableFilterComposer,
    $$StepCheckpointsTableOrderingComposer,
    $$StepCheckpointsTableAnnotationComposer,
    $$StepCheckpointsTableCreateCompanionBuilder,
    $$StepCheckpointsTableUpdateCompanionBuilder,
    (StepCheckpoint, $$StepCheckpointsTableReferences),
    StepCheckpoint,
    PrefetchHooks Function({bool workflowExecutionId})>;
typedef $$WorkflowTimersTableCreateCompanionBuilder = WorkflowTimersCompanion
    Function({
  required String workflowTimerId,
  required String workflowExecutionId,
  required String stepName,
  required String fireAt,
  Value<String> status,
  required String createdAt,
  Value<int> rowid,
});
typedef $$WorkflowTimersTableUpdateCompanionBuilder = WorkflowTimersCompanion
    Function({
  Value<String> workflowTimerId,
  Value<String> workflowExecutionId,
  Value<String> stepName,
  Value<String> fireAt,
  Value<String> status,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$WorkflowTimersTableReferences extends BaseReferences<
    _$DurableWorkflowDatabase, $WorkflowTimersTable, WorkflowTimer> {
  $$WorkflowTimersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkflowExecutionsTable _workflowExecutionIdTable(
          _$DurableWorkflowDatabase db) =>
      db.workflowExecutions.createAlias($_aliasNameGenerator(
          db.workflowTimers.workflowExecutionId,
          db.workflowExecutions.workflowExecutionId));

  $$WorkflowExecutionsTableProcessedTableManager get workflowExecutionId {
    final $_column = $_itemColumn<String>('workflow_execution_id')!;

    final manager =
        $$WorkflowExecutionsTableTableManager($_db, $_db.workflowExecutions)
            .filter((f) => f.workflowExecutionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workflowExecutionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkflowTimersTableFilterComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowTimersTable> {
  $$WorkflowTimersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workflowTimerId => $composableBuilder(
      column: $table.workflowTimerId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stepName => $composableBuilder(
      column: $table.stepName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fireAt => $composableBuilder(
      column: $table.fireAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$WorkflowExecutionsTableFilterComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowExecutions,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowExecutionsTableFilterComposer(
              $db: $db,
              $table: $db.workflowExecutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkflowTimersTableOrderingComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowTimersTable> {
  $$WorkflowTimersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workflowTimerId => $composableBuilder(
      column: $table.workflowTimerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stepName => $composableBuilder(
      column: $table.stepName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fireAt => $composableBuilder(
      column: $table.fireAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$WorkflowExecutionsTableOrderingComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowExecutions,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowExecutionsTableOrderingComposer(
              $db: $db,
              $table: $db.workflowExecutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkflowTimersTableAnnotationComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowTimersTable> {
  $$WorkflowTimersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workflowTimerId => $composableBuilder(
      column: $table.workflowTimerId, builder: (column) => column);

  GeneratedColumn<String> get stepName =>
      $composableBuilder(column: $table.stepName, builder: (column) => column);

  GeneratedColumn<String> get fireAt =>
      $composableBuilder(column: $table.fireAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkflowExecutionsTableAnnotationComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.workflowExecutionId,
            referencedTable: $db.workflowExecutions,
            getReferencedColumn: (t) => t.workflowExecutionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$WorkflowExecutionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.workflowExecutions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$WorkflowTimersTableTableManager extends RootTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowTimersTable,
    WorkflowTimer,
    $$WorkflowTimersTableFilterComposer,
    $$WorkflowTimersTableOrderingComposer,
    $$WorkflowTimersTableAnnotationComposer,
    $$WorkflowTimersTableCreateCompanionBuilder,
    $$WorkflowTimersTableUpdateCompanionBuilder,
    (WorkflowTimer, $$WorkflowTimersTableReferences),
    WorkflowTimer,
    PrefetchHooks Function({bool workflowExecutionId})> {
  $$WorkflowTimersTableTableManager(
      _$DurableWorkflowDatabase db, $WorkflowTimersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkflowTimersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkflowTimersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkflowTimersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> workflowTimerId = const Value.absent(),
            Value<String> workflowExecutionId = const Value.absent(),
            Value<String> stepName = const Value.absent(),
            Value<String> fireAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkflowTimersCompanion(
            workflowTimerId: workflowTimerId,
            workflowExecutionId: workflowExecutionId,
            stepName: stepName,
            fireAt: fireAt,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String workflowTimerId,
            required String workflowExecutionId,
            required String stepName,
            required String fireAt,
            Value<String> status = const Value.absent(),
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkflowTimersCompanion.insert(
            workflowTimerId: workflowTimerId,
            workflowExecutionId: workflowExecutionId,
            stepName: stepName,
            fireAt: fireAt,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkflowTimersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workflowExecutionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workflowExecutionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workflowExecutionId,
                    referencedTable: $$WorkflowTimersTableReferences
                        ._workflowExecutionIdTable(db),
                    referencedColumn: $$WorkflowTimersTableReferences
                        ._workflowExecutionIdTable(db)
                        .workflowExecutionId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkflowTimersTableProcessedTableManager = ProcessedTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowTimersTable,
    WorkflowTimer,
    $$WorkflowTimersTableFilterComposer,
    $$WorkflowTimersTableOrderingComposer,
    $$WorkflowTimersTableAnnotationComposer,
    $$WorkflowTimersTableCreateCompanionBuilder,
    $$WorkflowTimersTableUpdateCompanionBuilder,
    (WorkflowTimer, $$WorkflowTimersTableReferences),
    WorkflowTimer,
    PrefetchHooks Function({bool workflowExecutionId})>;
typedef $$WorkflowSignalsTableCreateCompanionBuilder = WorkflowSignalsCompanion
    Function({
  Value<int> workflowSignalId,
  required String workflowExecutionId,
  required String signalName,
  Value<String?> payload,
  Value<String> status,
  required String createdAt,
});
typedef $$WorkflowSignalsTableUpdateCompanionBuilder = WorkflowSignalsCompanion
    Function({
  Value<int> workflowSignalId,
  Value<String> workflowExecutionId,
  Value<String> signalName,
  Value<String?> payload,
  Value<String> status,
  Value<String> createdAt,
});

final class $$WorkflowSignalsTableReferences extends BaseReferences<
    _$DurableWorkflowDatabase, $WorkflowSignalsTable, WorkflowSignal> {
  $$WorkflowSignalsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkflowExecutionsTable _workflowExecutionIdTable(
          _$DurableWorkflowDatabase db) =>
      db.workflowExecutions.createAlias($_aliasNameGenerator(
          db.workflowSignals.workflowExecutionId,
          db.workflowExecutions.workflowExecutionId));

  $$WorkflowExecutionsTableProcessedTableManager get workflowExecutionId {
    final $_column = $_itemColumn<String>('workflow_execution_id')!;

    final manager =
        $$WorkflowExecutionsTableTableManager($_db, $_db.workflowExecutions)
            .filter((f) => f.workflowExecutionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workflowExecutionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkflowSignalsTableFilterComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowSignalsTable> {
  $$WorkflowSignalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get workflowSignalId => $composableBuilder(
      column: $table.workflowSignalId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signalName => $composableBuilder(
      column: $table.signalName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$WorkflowExecutionsTableFilterComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowExecutions,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowExecutionsTableFilterComposer(
              $db: $db,
              $table: $db.workflowExecutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkflowSignalsTableOrderingComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowSignalsTable> {
  $$WorkflowSignalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get workflowSignalId => $composableBuilder(
      column: $table.workflowSignalId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signalName => $composableBuilder(
      column: $table.signalName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$WorkflowExecutionsTableOrderingComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workflowExecutionId,
        referencedTable: $db.workflowExecutions,
        getReferencedColumn: (t) => t.workflowExecutionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkflowExecutionsTableOrderingComposer(
              $db: $db,
              $table: $db.workflowExecutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkflowSignalsTableAnnotationComposer
    extends Composer<_$DurableWorkflowDatabase, $WorkflowSignalsTable> {
  $$WorkflowSignalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get workflowSignalId => $composableBuilder(
      column: $table.workflowSignalId, builder: (column) => column);

  GeneratedColumn<String> get signalName => $composableBuilder(
      column: $table.signalName, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkflowExecutionsTableAnnotationComposer get workflowExecutionId {
    final $$WorkflowExecutionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.workflowExecutionId,
            referencedTable: $db.workflowExecutions,
            getReferencedColumn: (t) => t.workflowExecutionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$WorkflowExecutionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.workflowExecutions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$WorkflowSignalsTableTableManager extends RootTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowSignalsTable,
    WorkflowSignal,
    $$WorkflowSignalsTableFilterComposer,
    $$WorkflowSignalsTableOrderingComposer,
    $$WorkflowSignalsTableAnnotationComposer,
    $$WorkflowSignalsTableCreateCompanionBuilder,
    $$WorkflowSignalsTableUpdateCompanionBuilder,
    (WorkflowSignal, $$WorkflowSignalsTableReferences),
    WorkflowSignal,
    PrefetchHooks Function({bool workflowExecutionId})> {
  $$WorkflowSignalsTableTableManager(
      _$DurableWorkflowDatabase db, $WorkflowSignalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkflowSignalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkflowSignalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkflowSignalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> workflowSignalId = const Value.absent(),
            Value<String> workflowExecutionId = const Value.absent(),
            Value<String> signalName = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              WorkflowSignalsCompanion(
            workflowSignalId: workflowSignalId,
            workflowExecutionId: workflowExecutionId,
            signalName: signalName,
            payload: payload,
            status: status,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> workflowSignalId = const Value.absent(),
            required String workflowExecutionId,
            required String signalName,
            Value<String?> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            required String createdAt,
          }) =>
              WorkflowSignalsCompanion.insert(
            workflowSignalId: workflowSignalId,
            workflowExecutionId: workflowExecutionId,
            signalName: signalName,
            payload: payload,
            status: status,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkflowSignalsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workflowExecutionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workflowExecutionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workflowExecutionId,
                    referencedTable: $$WorkflowSignalsTableReferences
                        ._workflowExecutionIdTable(db),
                    referencedColumn: $$WorkflowSignalsTableReferences
                        ._workflowExecutionIdTable(db)
                        .workflowExecutionId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkflowSignalsTableProcessedTableManager = ProcessedTableManager<
    _$DurableWorkflowDatabase,
    $WorkflowSignalsTable,
    WorkflowSignal,
    $$WorkflowSignalsTableFilterComposer,
    $$WorkflowSignalsTableOrderingComposer,
    $$WorkflowSignalsTableAnnotationComposer,
    $$WorkflowSignalsTableCreateCompanionBuilder,
    $$WorkflowSignalsTableUpdateCompanionBuilder,
    (WorkflowSignal, $$WorkflowSignalsTableReferences),
    WorkflowSignal,
    PrefetchHooks Function({bool workflowExecutionId})>;

class $DurableWorkflowDatabaseManager {
  final _$DurableWorkflowDatabase _db;
  $DurableWorkflowDatabaseManager(this._db);
  $$WorkflowsTableTableManager get workflows =>
      $$WorkflowsTableTableManager(_db, _db.workflows);
  $$WorkflowExecutionsTableTableManager get workflowExecutions =>
      $$WorkflowExecutionsTableTableManager(_db, _db.workflowExecutions);
  $$StepCheckpointsTableTableManager get stepCheckpoints =>
      $$StepCheckpointsTableTableManager(_db, _db.stepCheckpoints);
  $$WorkflowTimersTableTableManager get workflowTimers =>
      $$WorkflowTimersTableTableManager(_db, _db.workflowTimers);
  $$WorkflowSignalsTableTableManager get workflowSignals =>
      $$WorkflowSignalsTableTableManager(_db, _db.workflowSignals);
}
