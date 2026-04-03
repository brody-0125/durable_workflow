@Tags(['unit'])
library;

import 'dart:math' as math;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/internals.dart';
import 'package:test/test.dart';

void main() {
  group('ExecutionStatus roundtrip', () {
    for (final status in [
      const Pending(),
      const Running(),
      const Suspended(),
      const Completed(),
      const Failed(),
      const Compensating(),
      const Cancelled(),
    ]) {
      test('fromString(${status.name}) returns same status', () {
        final deserialized = ExecutionStatus.fromString(status.name);
        expect(deserialized, equals(status));
      });
    }
  });

  group('WorkflowExecution JSON roundtrip', () {
    final statuses = <ExecutionStatus>[
      const Pending(),
      const Running(),
      const Completed(),
      const Failed(),
    ];
    final guarantees = WorkflowGuarantee.values;

    for (final status in statuses) {
      for (final guarantee in guarantees) {
        test('status=${status.name} guarantee=${guarantee.value}', () {
          final exec = WorkflowExecution(
            workflowExecutionId: 'exec-rt',
            workflowId: 'wf-rt',
            status: status,
            currentStep: 5,
            guarantee: guarantee,
            createdAt: '2025-06-15T12:00:00.000Z',
            updatedAt: '2025-06-15T12:00:00.000Z',
          );
          final restored = WorkflowExecution.fromJson(exec.toJson());
          expect(restored, equals(exec));
        });
      }
    }
  });

  group('StepCheckpoint JSON roundtrip', () {
    for (final status in StepStatus.values) {
      test('status=${status.value}', () {
        final cp = StepCheckpoint(
          workflowExecutionId: 'exec-rt',
          stepIndex: 3,
          stepName: 'step-rt',
          status: status,
          attempt: 2,
          compensateRef: 'comp-1',
        );
        final restored = StepCheckpoint.fromJson(cp.toJson());
        expect(restored, equals(cp));
      });
    }
  });

  group('WorkflowTimer JSON roundtrip', () {
    for (final status in TimerStatus.values) {
      test('status=${status.value}', () {
        final timer = WorkflowTimer(
          workflowTimerId: 'tmr-rt',
          workflowExecutionId: 'exec-rt',
          stepName: 'wait',
          fireAt: '2025-06-15T12:00:00.000Z',
          status: status,
          createdAt: '2025-06-15T11:00:00.000Z',
        );
        final restored = WorkflowTimer.fromJson(timer.toJson());
        expect(restored, equals(timer));
      });
    }
  });

  group('WorkflowSignal JSON roundtrip', () {
    for (final status in SignalStatus.values) {
      test('status=${status.value}', () {
        final signal = WorkflowSignal(
          workflowExecutionId: 'exec-rt',
          signalName: 'approve',
          status: status,
          createdAt: '2025-06-15T12:00:00.000Z',
        );
        final restored = WorkflowSignal.fromJson(signal.toJson());
        expect(restored, equals(signal));
      });
    }
  });

  group('RetryPolicy JSON roundtrip', () {
    final policies = <RetryPolicy>[
      const RetryPolicyNone(),
      RetryPolicyFixed(maxAttempts: 3, delay: const Duration(seconds: 1)),
      RetryPolicyExponential(
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 500),
        multiplier: 2.0,
        maxDelay: const Duration(minutes: 1),
        jitter: 0.1,
      ),
    ];

    for (final policy in policies) {
      test('${policy.runtimeType}', () {
        final restored = RetryPolicy.fromJson(policy.toJson());
        expect(restored, equals(policy));
      });
    }
  });

  group('RetryPolicyExponential invariants', () {
    test('calculateDelay never exceeds maxDelay (no jitter)', () {
      final executor = RetryExecutor(random: math.Random(42));

      final configs = [
        RetryPolicyExponential(
          maxAttempts: 10,
          initialDelay: const Duration(milliseconds: 100),
          multiplier: 2.0,
          maxDelay: const Duration(seconds: 5),
        ),
        RetryPolicyExponential(
          maxAttempts: 20,
          initialDelay: const Duration(seconds: 1),
          multiplier: 3.0,
          maxDelay: const Duration(seconds: 30),
        ),
      ];

      for (final policy in configs) {
        for (var attempt = 1; attempt <= policy.maxAttempts; attempt++) {
          final delay = executor.calculateDelay(policy, attempt);
          expect(
            delay.inMilliseconds,
            lessThanOrEqualTo(policy.maxDelay.inMilliseconds),
            reason: 'attempt $attempt of ${policy.maxAttempts}',
          );
        }
      }
    });

    test('calculateDelay with jitter stays within jitter bounds', () {
      final executor = RetryExecutor(random: math.Random(42));
      final policy = RetryPolicyExponential(
        maxAttempts: 10,
        initialDelay: const Duration(milliseconds: 100),
        multiplier: 2.0,
        maxDelay: const Duration(seconds: 5),
        jitter: 0.1,
      );

      for (var attempt = 1; attempt <= policy.maxAttempts; attempt++) {
        final delay = executor.calculateDelay(policy, attempt);
        // With 10% jitter, delay can be up to maxDelay * 1.1
        final maxWithJitter =
            (policy.maxDelay.inMilliseconds * (1.0 + policy.jitter)).ceil();
        expect(
          delay.inMilliseconds,
          lessThanOrEqualTo(maxWithJitter),
          reason: 'attempt $attempt with jitter=${policy.jitter}',
        );
      }
    });

    test('delays are non-negative', () {
      final executor = RetryExecutor(random: math.Random(42));
      final policy = RetryPolicyExponential(
        maxAttempts: 10,
        initialDelay: const Duration(milliseconds: 100),
        multiplier: 2.0,
        maxDelay: const Duration(seconds: 30),
        jitter: 0.2,
      );

      for (var attempt = 1; attempt <= policy.maxAttempts; attempt++) {
        final delay = executor.calculateDelay(policy, attempt);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(0));
      }
    });
  });
}
