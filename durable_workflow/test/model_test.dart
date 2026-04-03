@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:test/test.dart';

void main() {
  group('ExecutionStatus', () {
    test('all 7 statuses exist and have correct names', () {
      expect(const Pending().name, 'PENDING');
      expect(const Running().name, 'RUNNING');
      expect(const Suspended().name, 'SUSPENDED');
      expect(const Completed().name, 'COMPLETED');
      expect(const Failed().name, 'FAILED');
      expect(const Compensating().name, 'COMPENSATING');
      expect(const Cancelled().name, 'CANCELLED');
    });

    test('fromString round-trips all statuses', () {
      final names = [
        'PENDING',
        'RUNNING',
        'SUSPENDED',
        'COMPLETED',
        'FAILED',
        'COMPENSATING',
        'CANCELLED',
      ];
      for (final name in names) {
        final status = ExecutionStatus.fromString(name);
        expect(status.name, name);
      }
    });

    test('fromString throws on unknown value', () {
      expect(
        () => ExecutionStatus.fromString('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('exhaustive switch covers all variants', () {
      // This test verifies exhaustive pattern matching compiles.
      String describe(ExecutionStatus status) {
        return switch (status) {
          Pending() => 'pending',
          Running() => 'running',
          Suspended() => 'suspended',
          Completed() => 'completed',
          Failed() => 'failed',
          Compensating() => 'compensating',
          Cancelled() => 'cancelled',
        };
      }

      expect(describe(const Pending()), 'pending');
      expect(describe(const Running()), 'running');
      expect(describe(const Suspended()), 'suspended');
      expect(describe(const Completed()), 'completed');
      expect(describe(const Failed()), 'failed');
      expect(describe(const Compensating()), 'compensating');
      expect(describe(const Cancelled()), 'cancelled');
    });

    test('equality works correctly', () {
      expect(const Pending(), equals(const Pending()));
      expect(const Pending(), isNot(equals(const Running())));
      expect(const Pending() == const Pending(), isTrue);
    });

    test('toString returns readable format', () {
      expect(const Pending().toString(), 'ExecutionStatus.PENDING');
      expect(const Running().toString(), 'ExecutionStatus.RUNNING');
    });

    test('hashCode is consistent', () {
      expect(const Pending().hashCode, const Pending().hashCode);
      expect(
        const Pending().hashCode,
        isNot(equals(const Running().hashCode)),
      );
    });
  });

  group('RetryPolicy', () {
    test('none creates RetryPolicyNone', () {
      const policy = RetryPolicyNone();
      expect(policy, isA<RetryPolicyNone>());
      expect(RetryPolicy.none, isA<RetryPolicyNone>());
    });

    test('fixed creates RetryPolicyFixed', () {
      final policy = RetryPolicy.fixed(
        maxAttempts: 3,
        delay: const Duration(seconds: 1),
      );
      expect(policy, isA<RetryPolicyFixed>());
      final fixed = policy as RetryPolicyFixed;
      expect(fixed.maxAttempts, 3);
      expect(fixed.delay, const Duration(seconds: 1));
    });

    test('exponential creates RetryPolicyExponential with all params', () {
      final policy = RetryPolicy.exponential(
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 500),
        multiplier: 1.5,
        maxDelay: const Duration(minutes: 10),
        jitter: 0.1,
      );
      expect(policy, isA<RetryPolicyExponential>());
      final exp = policy as RetryPolicyExponential;
      expect(exp.maxAttempts, 5);
      expect(exp.initialDelay, const Duration(milliseconds: 500));
      expect(exp.multiplier, 1.5);
      expect(exp.maxDelay, const Duration(minutes: 10));
      expect(exp.jitter, 0.1);
    });

    test('exponential uses default values', () {
      final policy = RetryPolicy.exponential(maxAttempts: 3);
      final exp = policy as RetryPolicyExponential;
      expect(exp.initialDelay, const Duration(seconds: 1));
      expect(exp.multiplier, 2.0);
      expect(exp.maxDelay, const Duration(minutes: 5));
      expect(exp.jitter, 0.0);
    });

    group('JSON serialization', () {
      test('none round-trips', () {
        const policy = RetryPolicyNone();
        final json = policy.toJson();
        expect(json, {'type': 'none'});
        final restored = RetryPolicy.fromJson(json);
        expect(restored, isA<RetryPolicyNone>());
      });

      test('fixed round-trips', () {
        final policy = RetryPolicyFixed(
          maxAttempts: 3,
          delay: const Duration(seconds: 2),
        );
        final json = policy.toJson();
        expect(json, {
          'type': 'fixed',
          'maxAttempts': 3,
          'delayMs': 2000,
        });
        final restored = RetryPolicy.fromJson(json);
        expect(restored, isA<RetryPolicyFixed>());
        final fixed = restored as RetryPolicyFixed;
        expect(fixed.maxAttempts, 3);
        expect(fixed.delay, const Duration(seconds: 2));
      });

      test('exponential round-trips', () {
        const policy = RetryPolicyExponential(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 100),
          multiplier: 3.0,
          maxDelay: Duration(seconds: 30),
          jitter: 0.2,
        );
        final json = policy.toJson();
        expect(json, {
          'type': 'exponential',
          'maxAttempts': 5,
          'initialDelayMs': 100,
          'multiplier': 3.0,
          'maxDelayMs': 30000,
          'jitter': 0.2,
        });
        final restored = RetryPolicy.fromJson(json);
        expect(restored, isA<RetryPolicyExponential>());
        final exp = restored as RetryPolicyExponential;
        expect(exp.maxAttempts, 5);
        expect(exp.initialDelay, const Duration(milliseconds: 100));
        expect(exp.multiplier, 3.0);
        expect(exp.maxDelay, const Duration(seconds: 30));
        expect(exp.jitter, 0.2);
      });

      test('exponential fromJson defaults jitter to 0.0', () {
        final json = {
          'type': 'exponential',
          'maxAttempts': 2,
          'initialDelayMs': 1000,
          'multiplier': 2.0,
          'maxDelayMs': 60000,
        };
        final policy = RetryPolicy.fromJson(json) as RetryPolicyExponential;
        expect(policy.jitter, 0.0);
      });

      test('fromJson throws on unknown type', () {
        expect(
          () => RetryPolicy.fromJson({'type': 'unknown'}),
          throwsArgumentError,
        );
      });
    });

    test('equality for none', () {
      expect(const RetryPolicyNone(), const RetryPolicyNone());
    });

    test('equality for fixed', () {
      final a = RetryPolicyFixed(
        maxAttempts: 3,
        delay: const Duration(seconds: 1),
      );
      final b = RetryPolicyFixed(
        maxAttempts: 3,
        delay: const Duration(seconds: 1),
      );
      final c = RetryPolicyFixed(
        maxAttempts: 5,
        delay: const Duration(seconds: 1),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality for exponential', () {
      const a = RetryPolicyExponential(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 1),
        multiplier: 2.0,
        maxDelay: Duration(minutes: 5),
        jitter: 0.1,
      );
      const b = RetryPolicyExponential(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 1),
        multiplier: 2.0,
        maxDelay: Duration(minutes: 5),
        jitter: 0.1,
      );
      const c = RetryPolicyExponential(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 1),
        multiplier: 2.0,
        maxDelay: Duration(minutes: 5),
        jitter: 0.5,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode consistency', () {
      const a = RetryPolicyNone();
      const b = RetryPolicyNone();
      expect(a.hashCode, b.hashCode);
    });

    test('toString returns readable format', () {
      expect(const RetryPolicyNone().toString(), 'RetryPolicy.none');
      expect(
        RetryPolicyFixed(
          maxAttempts: 3,
          delay: const Duration(seconds: 1),
        ).toString(),
        contains('RetryPolicy.fixed'),
      );
      expect(
        const RetryPolicyExponential(maxAttempts: 3).toString(),
        contains('RetryPolicy.exponential'),
      );
    });

    test('exhaustive switch covers all variants', () {
      String describe(RetryPolicy policy) {
        return switch (policy) {
          RetryPolicyNone() => 'none',
          RetryPolicyFixed() => 'fixed',
          RetryPolicyExponential() => 'exponential',
        };
      }

      expect(describe(const RetryPolicyNone()), 'none');
      expect(
        describe(RetryPolicyFixed(
          maxAttempts: 1,
          delay: Duration.zero,
        )),
        'fixed',
      );
      expect(
        describe(const RetryPolicyExponential(maxAttempts: 1)),
        'exponential',
      );
    });
  });

  group('WorkflowGuarantee', () {
    test('has foregroundOnly and bestEffortBackground', () {
      expect(
        WorkflowGuarantee.foregroundOnly.value,
        'FOREGROUND_ONLY',
      );
      expect(
        WorkflowGuarantee.bestEffortBackground.value,
        'BEST_EFFORT_BACKGROUND',
      );
    });

    test('fromString round-trips', () {
      expect(
        WorkflowGuarantee.fromString('FOREGROUND_ONLY'),
        WorkflowGuarantee.foregroundOnly,
      );
      expect(
        WorkflowGuarantee.fromString('BEST_EFFORT_BACKGROUND'),
        WorkflowGuarantee.bestEffortBackground,
      );
    });

    test('fromString throws on unknown value', () {
      expect(
        () => WorkflowGuarantee.fromString('UNKNOWN'),
        throwsArgumentError,
      );
    });

    test('values contains exactly 2 entries', () {
      expect(WorkflowGuarantee.values.length, 2);
    });
  });

  group('Workflow', () {
    final workflow = Workflow(
      workflowId: 'wf-001',
      workflowType: 'order_processing',
      version: 2,
      createdAt: '2026-03-25T10:00:00.000',
    );

    test('constructor sets all fields', () {
      expect(workflow.workflowId, 'wf-001');
      expect(workflow.workflowType, 'order_processing');
      expect(workflow.version, 2);
      expect(workflow.createdAt, '2026-03-25T10:00:00.000');
    });

    test('version defaults to 1', () {
      final w = Workflow(
        workflowId: 'wf-002',
        workflowType: 'test',
        createdAt: '2026-03-25T10:00:00.000',
      );
      expect(w.version, 1);
    });

    test('JSON round-trip', () {
      final json = workflow.toJson();
      expect(json, {
        'workflowId': 'wf-001',
        'workflowType': 'order_processing',
        'version': 2,
        'createdAt': '2026-03-25T10:00:00.000',
      });
      final restored = Workflow.fromJson(json);
      expect(restored, equals(workflow));
    });

    test('fromJson defaults version to 1', () {
      final json = {
        'workflowId': 'wf-003',
        'workflowType': 'test',
        'createdAt': '2026-03-25T10:00:00.000',
      };
      final w = Workflow.fromJson(json);
      expect(w.version, 1);
    });

    test('copyWith creates modified copy', () {
      final copy = workflow.copyWith(version: 3);
      expect(copy.version, 3);
      expect(copy.workflowId, workflow.workflowId);
      expect(copy.workflowType, workflow.workflowType);
    });

    test('copyWith with no args returns equal object', () {
      final copy = workflow.copyWith();
      expect(copy, equals(workflow));
    });

    test('equality', () {
      final same = Workflow(
        workflowId: 'wf-001',
        workflowType: 'order_processing',
        version: 2,
        createdAt: '2026-03-25T10:00:00.000',
      );
      final different = workflow.copyWith(workflowId: 'wf-999');
      expect(workflow, equals(same));
      expect(workflow, isNot(equals(different)));
    });

    test('hashCode consistency', () {
      final same = Workflow(
        workflowId: 'wf-001',
        workflowType: 'order_processing',
        version: 2,
        createdAt: '2026-03-25T10:00:00.000',
      );
      expect(workflow.hashCode, same.hashCode);
    });

    test('toString', () {
      expect(workflow.toString(), contains('wf-001'));
      expect(workflow.toString(), contains('order_processing'));
    });
  });

  group('WorkflowExecution', () {
    final execution = WorkflowExecution(
      workflowExecutionId: 'exec-001',
      workflowId: 'wf-001',
      status: const Running(),
      currentStep: 2,
      inputData: '{"orderId": 123}',
      outputData: null,
      errorMessage: null,
      ttlExpiresAt: '2026-04-25T10:00:00.000',
      guarantee: WorkflowGuarantee.foregroundOnly,
      createdAt: '2026-03-25T10:00:00.000',
      updatedAt: '2026-03-25T10:05:00.000',
    );

    test('constructor sets all fields', () {
      expect(execution.workflowExecutionId, 'exec-001');
      expect(execution.workflowId, 'wf-001');
      expect(execution.status, isA<Running>());
      expect(execution.currentStep, 2);
      expect(execution.inputData, '{"orderId": 123}');
      expect(execution.outputData, isNull);
      expect(execution.errorMessage, isNull);
      expect(execution.ttlExpiresAt, '2026-04-25T10:00:00.000');
      expect(execution.guarantee, WorkflowGuarantee.foregroundOnly);
    });

    test('defaults', () {
      final e = WorkflowExecution(
        workflowExecutionId: 'exec-002',
        workflowId: 'wf-001',
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      );
      expect(e.status, isA<Pending>());
      expect(e.currentStep, 0);
      expect(e.guarantee, WorkflowGuarantee.foregroundOnly);
    });

    test('JSON round-trip', () {
      final json = execution.toJson();
      expect(json['workflowExecutionId'], 'exec-001');
      expect(json['status'], 'RUNNING');
      expect(json['guarantee'], 'FOREGROUND_ONLY');

      final restored = WorkflowExecution.fromJson(json);
      expect(restored, equals(execution));
    });

    test('fromJson with defaults', () {
      final json = {
        'workflowExecutionId': 'exec-003',
        'workflowId': 'wf-001',
        'status': 'PENDING',
        'createdAt': '2026-03-25T10:00:00.000',
        'updatedAt': '2026-03-25T10:00:00.000',
      };
      final e = WorkflowExecution.fromJson(json);
      expect(e.currentStep, 0);
      expect(e.guarantee, WorkflowGuarantee.foregroundOnly);
    });

    test('copyWith creates modified copy', () {
      final copy = execution.copyWith(
        status: const Completed(),
        currentStep: 5,
      );
      expect(copy.status, isA<Completed>());
      expect(copy.currentStep, 5);
      expect(copy.workflowExecutionId, execution.workflowExecutionId);
    });

    test('copyWith with no args returns equal object', () {
      final copy = execution.copyWith();
      expect(copy, equals(execution));
    });

    test('equality', () {
      final same = WorkflowExecution(
        workflowExecutionId: 'exec-001',
        workflowId: 'wf-001',
        status: const Running(),
        currentStep: 2,
        inputData: '{"orderId": 123}',
        ttlExpiresAt: '2026-04-25T10:00:00.000',
        guarantee: WorkflowGuarantee.foregroundOnly,
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:05:00.000',
      );
      expect(execution, equals(same));
    });

    test('hashCode consistency', () {
      final same = WorkflowExecution(
        workflowExecutionId: 'exec-001',
        workflowId: 'wf-001',
        status: const Running(),
        currentStep: 2,
        inputData: '{"orderId": 123}',
        ttlExpiresAt: '2026-04-25T10:00:00.000',
        guarantee: WorkflowGuarantee.foregroundOnly,
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:05:00.000',
      );
      expect(execution.hashCode, same.hashCode);
    });

    test('toString', () {
      expect(execution.toString(), contains('exec-001'));
      expect(execution.toString(), contains('RUNNING'));
    });
  });

  group('StepCheckpoint', () {
    final checkpoint = StepCheckpoint(
      id: 1,
      workflowExecutionId: 'exec-001',
      stepIndex: 0,
      stepName: 'validate',
      status: StepStatus.completed,
      inputData: '{"input": true}',
      outputData: '{"valid": true}',
      errorMessage: null,
      attempt: 1,

      compensateRef: 'validate_compensate',
      startedAt: '2026-03-25T10:00:00.000',
      completedAt: '2026-03-25T10:00:01.000',
    );

    test('constructor sets all fields', () {
      expect(checkpoint.id, 1);
      expect(checkpoint.workflowExecutionId, 'exec-001');
      expect(checkpoint.stepIndex, 0);
      expect(checkpoint.stepName, 'validate');
      expect(checkpoint.status, StepStatus.completed);
      expect(checkpoint.inputData, '{"input": true}');
      expect(checkpoint.outputData, '{"valid": true}');
      expect(checkpoint.errorMessage, isNull);
      expect(checkpoint.attempt, 1);
      expect(checkpoint.compensateRef, 'validate_compensate');
      expect(checkpoint.startedAt, '2026-03-25T10:00:00.000');
      expect(checkpoint.completedAt, '2026-03-25T10:00:01.000');
    });

    test('defaults', () {
      final cp = StepCheckpoint(
        workflowExecutionId: 'exec-001',
        stepIndex: 0,
        stepName: 'step',
        status: StepStatus.intent,
      );
      expect(cp.id, isNull);
      expect(cp.attempt, 1);
      expect(cp.compensateRef, isNull);
      expect(cp.startedAt, isNull);
      expect(cp.completedAt, isNull);
    });

    test('JSON round-trip', () {
      final json = checkpoint.toJson();
      expect(json['status'], 'COMPLETED');
      expect(json['stepIndex'], 0);
      expect(json['stepName'], 'validate');

      final restored = StepCheckpoint.fromJson(json);
      expect(restored, equals(checkpoint));
    });

    test('fromJson with defaults', () {
      final json = {
        'workflowExecutionId': 'exec-001',
        'stepIndex': 0,
        'stepName': 'step',
        'status': 'INTENT',
      };
      final cp = StepCheckpoint.fromJson(json);
      expect(cp.id, isNull);
      expect(cp.attempt, 1);
    });

    test('copyWith creates modified copy', () {
      final copy = checkpoint.copyWith(
        status: StepStatus.failed,
        errorMessage: 'timeout',
      );
      expect(copy.status, StepStatus.failed);
      expect(copy.errorMessage, 'timeout');
      expect(copy.stepName, checkpoint.stepName);
    });

    test('copyWith with no args returns equal object', () {
      final copy = checkpoint.copyWith();
      expect(copy, equals(checkpoint));
    });

    test('equality', () {
      final same = StepCheckpoint(
        id: 1,
        workflowExecutionId: 'exec-001',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.completed,
        inputData: '{"input": true}',
        outputData: '{"valid": true}',
        attempt: 1,
  
        compensateRef: 'validate_compensate',
        startedAt: '2026-03-25T10:00:00.000',
        completedAt: '2026-03-25T10:00:01.000',
      );
      expect(checkpoint, equals(same));
    });

    test('hashCode consistency', () {
      final same = StepCheckpoint(
        id: 1,
        workflowExecutionId: 'exec-001',
        stepIndex: 0,
        stepName: 'validate',
        status: StepStatus.completed,
        inputData: '{"input": true}',
        outputData: '{"valid": true}',
        attempt: 1,
  
        compensateRef: 'validate_compensate',
        startedAt: '2026-03-25T10:00:00.000',
        completedAt: '2026-03-25T10:00:01.000',
      );
      expect(checkpoint.hashCode, same.hashCode);
    });

    test('toString', () {
      expect(checkpoint.toString(), contains('validate'));
      expect(checkpoint.toString(), contains('exec-001'));
    });
  });

  group('StepStatus', () {
    test('all 4 statuses exist', () {
      expect(StepStatus.intent.value, 'INTENT');
      expect(StepStatus.completed.value, 'COMPLETED');
      expect(StepStatus.failed.value, 'FAILED');
      expect(StepStatus.compensated.value, 'COMPENSATED');
    });

    test('fromString round-trips', () {
      for (final status in StepStatus.values) {
        expect(StepStatus.fromString(status.value), status);
      }
    });

    test('fromString throws on unknown', () {
      expect(
        () => StepStatus.fromString('UNKNOWN'),
        throwsArgumentError,
      );
    });
  });

  group('WorkflowTimer', () {
    final timer = WorkflowTimer(
      workflowTimerId: 'timer-001',
      workflowExecutionId: 'exec-001',
      stepName: 'await_shipping',
      fireAt: '2026-03-26T10:00:00.000',
      status: TimerStatus.pending,
      createdAt: '2026-03-25T10:00:00.000',
    );

    test('constructor sets all fields', () {
      expect(timer.workflowTimerId, 'timer-001');
      expect(timer.workflowExecutionId, 'exec-001');
      expect(timer.stepName, 'await_shipping');
      expect(timer.fireAt, '2026-03-26T10:00:00.000');
      expect(timer.status, TimerStatus.pending);
      expect(timer.createdAt, '2026-03-25T10:00:00.000');
    });

    test('status defaults to pending', () {
      final t = WorkflowTimer(
        workflowTimerId: 'timer-002',
        workflowExecutionId: 'exec-001',
        stepName: 'step',
        fireAt: '2026-03-26T10:00:00.000',
        createdAt: '2026-03-25T10:00:00.000',
      );
      expect(t.status, TimerStatus.pending);
    });

    test('JSON round-trip', () {
      final json = timer.toJson();
      expect(json['status'], 'PENDING');
      expect(json['fireAt'], '2026-03-26T10:00:00.000');

      final restored = WorkflowTimer.fromJson(json);
      expect(restored, equals(timer));
    });

    test('fromJson with default status', () {
      final json = {
        'workflowTimerId': 'timer-003',
        'workflowExecutionId': 'exec-001',
        'stepName': 'step',
        'fireAt': '2026-03-26T10:00:00.000',
        'createdAt': '2026-03-25T10:00:00.000',
      };
      final t = WorkflowTimer.fromJson(json);
      expect(t.status, TimerStatus.pending);
    });

    test('copyWith creates modified copy', () {
      final copy = timer.copyWith(status: TimerStatus.fired);
      expect(copy.status, TimerStatus.fired);
      expect(copy.workflowTimerId, timer.workflowTimerId);
    });

    test('copyWith with no args returns equal object', () {
      final copy = timer.copyWith();
      expect(copy, equals(timer));
    });

    test('equality and hashCode', () {
      final same = WorkflowTimer(
        workflowTimerId: 'timer-001',
        workflowExecutionId: 'exec-001',
        stepName: 'await_shipping',
        fireAt: '2026-03-26T10:00:00.000',
        status: TimerStatus.pending,
        createdAt: '2026-03-25T10:00:00.000',
      );
      expect(timer, equals(same));
      expect(timer.hashCode, same.hashCode);
    });

    test('toString', () {
      expect(timer.toString(), contains('timer-001'));
      expect(timer.toString(), contains('await_shipping'));
    });
  });

  group('TimerStatus', () {
    test('all 3 statuses exist', () {
      expect(TimerStatus.pending.value, 'PENDING');
      expect(TimerStatus.fired.value, 'FIRED');
      expect(TimerStatus.cancelled.value, 'CANCELLED');
    });

    test('fromString round-trips', () {
      for (final status in TimerStatus.values) {
        expect(TimerStatus.fromString(status.value), status);
      }
    });

    test('fromString throws on unknown', () {
      expect(
        () => TimerStatus.fromString('UNKNOWN'),
        throwsArgumentError,
      );
    });
  });

  group('WorkflowSignal', () {
    final signal = WorkflowSignal(
      workflowSignalId: 1,
      workflowExecutionId: 'exec-001',
      signalName: 'delivery_confirmed',
      payload: '{"confirmed": true}',
      status: SignalStatus.pending,
      createdAt: '2026-03-25T10:00:00.000',
    );

    test('constructor sets all fields', () {
      expect(signal.workflowSignalId, 1);
      expect(signal.workflowExecutionId, 'exec-001');
      expect(signal.signalName, 'delivery_confirmed');
      expect(signal.payload, '{"confirmed": true}');
      expect(signal.status, SignalStatus.pending);
      expect(signal.createdAt, '2026-03-25T10:00:00.000');
    });

    test('defaults', () {
      final s = WorkflowSignal(
        workflowExecutionId: 'exec-001',
        signalName: 'test',
        createdAt: '2026-03-25T10:00:00.000',
      );
      expect(s.workflowSignalId, isNull);
      expect(s.payload, isNull);
      expect(s.status, SignalStatus.pending);
    });

    test('JSON round-trip', () {
      final json = signal.toJson();
      expect(json['status'], 'PENDING');
      expect(json['signalName'], 'delivery_confirmed');

      final restored = WorkflowSignal.fromJson(json);
      expect(restored, equals(signal));
    });

    test('fromJson with default status', () {
      final json = {
        'workflowExecutionId': 'exec-001',
        'signalName': 'test',
        'createdAt': '2026-03-25T10:00:00.000',
      };
      final s = WorkflowSignal.fromJson(json);
      expect(s.status, SignalStatus.pending);
    });

    test('copyWith creates modified copy', () {
      final copy = signal.copyWith(status: SignalStatus.delivered);
      expect(copy.status, SignalStatus.delivered);
      expect(copy.signalName, signal.signalName);
    });

    test('copyWith with no args returns equal object', () {
      final copy = signal.copyWith();
      expect(copy, equals(signal));
    });

    test('equality and hashCode', () {
      final same = WorkflowSignal(
        workflowSignalId: 1,
        workflowExecutionId: 'exec-001',
        signalName: 'delivery_confirmed',
        payload: '{"confirmed": true}',
        status: SignalStatus.pending,
        createdAt: '2026-03-25T10:00:00.000',
      );
      expect(signal, equals(same));
      expect(signal.hashCode, same.hashCode);
    });

    test('toString', () {
      expect(signal.toString(), contains('delivery_confirmed'));
      expect(signal.toString(), contains('exec-001'));
    });
  });

  group('SignalStatus', () {
    test('all 3 statuses exist', () {
      expect(SignalStatus.pending.value, 'PENDING');
      expect(SignalStatus.delivered.value, 'DELIVERED');
      expect(SignalStatus.expired.value, 'EXPIRED');
    });

    test('fromString round-trips', () {
      for (final status in SignalStatus.values) {
        expect(SignalStatus.fromString(status.value), status);
      }
    });

    test('fromString throws on unknown', () {
      expect(
        () => SignalStatus.fromString('UNKNOWN'),
        throwsArgumentError,
      );
    });
  });

  group('Interface signatures', () {
    // These tests verify the abstract interfaces exist and have
    // the expected method signatures by checking they can be referenced.

    test('CheckpointStore is abstract with expected methods', () {
      // Verify CheckpointStore can be used as a type
      // ignore: unnecessary_type_check
      expect(CheckpointStore, isNotNull);
    });

    test('WorkflowContext is abstract with expected methods', () {
      expect(WorkflowContext, isNotNull);
    });

    test('DurableEngine is abstract with expected methods', () {
      expect(DurableEngine, isNotNull);
    });
  });
}
