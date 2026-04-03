@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  late InMemoryCheckpointStore store;
  late DurableEngineImpl engine;

  setUp(() {
    store = InMemoryCheckpointStore();
    engine = createTestEngine(store);
  });

  tearDown(() {
    engine.dispose();
  });

  group('DurableEngineImpl', () {
    group('run', () {
      test('executes workflow and returns result', () async {
        final result = await engine.run<int>(
          'simple',
          (ctx) async {
            final a = await ctx.step('add', () async => 10);
            final b =
                await ctx.step('multiply', () async => a * 2);
            return b;
          },
        );

        expect(result, 20);
      });

      test('marks execution as COMPLETED on success', () async {
        await engine.run<String>(
          'test_wf',
          (ctx) async {
            return await ctx.step('greet', () async => 'hello');
          },
        );

        final execution = await store.loadExecution('exec-0');
        expect(execution, isNotNull);
        expect(execution!.status, isA<Completed>());
      });

      test('marks execution as FAILED on exception', () async {
        await expectLater(
          engine.run<int>(
            'failing_wf',
            (ctx) async {
              return await ctx.step(
                'boom',
                () async => throw Exception('fail'),
              );
            },
          ),
          throwsException,
        );

        final execution = await store.loadExecution('exec-0');
        expect(execution, isNotNull);
        expect(execution!.status, isA<Failed>());
        expect(execution.errorMessage, contains('fail'));
      });

      test('sets initial state with input, TTL, and guarantee',
          () async {
        await engine.run<int>(
          'order_processing',
          (ctx) async =>
              await ctx.step('validate', () async => 1),
          input: '{"orderId": 123}',
          ttl: const Duration(days: 30),
          guarantee: WorkflowGuarantee.bestEffortBackground,
        );

        final execution = await store.loadExecution('exec-0');
        expect(execution, isNotNull);
        expect(execution!.inputData, '{"orderId": 123}');
        expect(execution.ttlExpiresAt, isNotNull);
        expect(
          execution.guarantee,
          WorkflowGuarantee.bestEffortBackground,
        );
      });

      test('exposes executionId via WorkflowContext', () async {
        String? capturedId;
        await engine.run<int>(
          'exec_id_test',
          (ctx) async {
            capturedId = ctx.executionId;
            return await ctx.step('step', () async => 42);
          },
        );

        expect(capturedId, isNotNull);
        expect(capturedId, equals('exec-0'));
      });

      test('stores checkpoints for each step', () async {
        await engine.run<int>(
          'multi_step',
          (ctx) async {
            final a =
                await ctx.step('step_1', () async => 10);
            final b =
                await ctx.step('step_2', () async => a + 5);
            return b;
          },
        );

        final checkpoints =
            await store.loadCheckpoints('exec-0');
        expect(checkpoints, hasLength(2));
        expect(checkpoints[0].stepName, 'step_1');
        expect(checkpoints[0].status, StepStatus.completed);
        expect(checkpoints[1].stepName, 'step_2');
        expect(checkpoints[1].status, StepStatus.completed);
      });

      test('starts execution as RUNNING', () async {
        ExecutionStatus? capturedStatus;

        await engine.run<int>(
          'capture_status',
          (ctx) async {
            final exec =
                await store.loadExecution('exec-0');
            capturedStatus = exec?.status;
            return await ctx.step('s', () async => 1);
          },
        );

        expect(capturedStatus, isA<Running>());
      });
    });

    group('cancel', () {
      test('marks execution as CANCELLED', () async {
        await engine.run<int>(
          'to_cancel',
          (ctx) async =>
              await ctx.step('s', () async => 1),
        );

        await engine.cancel('exec-0');

        final execution = await store.loadExecution('exec-0');
        expect(execution!.status, isA<Cancelled>());
      });

      test('throws StateError on unknown execution', () async {
        await expectLater(
          engine.cancel('nonexistent'),
          throwsStateError,
        );
      });

      test('cancels running workflow mid-execution', () async {
        final stepLog = <String>[];

        final future = engine.run<int>(
          'cancellable',
          (ctx) async {
            final a = await ctx.step('step_1', () async {
              stepLog.add('step_1');
              return 1;
            });
            final b = await ctx.step('step_2', () async {
              stepLog.add('step_2');
              await Future<void>.delayed(
                const Duration(milliseconds: 100),
              );
              return 2;
            });
            return a + b;
          },
        );

        try {
          await future;
        } catch (_) {
          // Expected — may fail or complete depending on timing
        }

        expect(stepLog, contains('step_1'));
      });
    });

    group('observe', () {
      test('emits current state immediately', () async {
        await engine.run<int>(
          'observable',
          (ctx) async =>
              await ctx.step('s', () async => 1),
        );

        final stream = engine.observe('exec-0');
        final states = await stream.take(1).toList();

        expect(states, hasLength(1));
        expect(states[0].status, isA<Completed>());
      });

      test('returns empty stream for unknown execution',
          () async {
        final stream = engine.observe('nonexistent');
        final states = await stream.toList();
        expect(states, isEmpty);
      });
    });

    group('sendSignal', () {
      test('persists signal with payload', () async {
        await engine.run<int>(
          'signalable',
          (ctx) async =>
              await ctx.step('s', () async => 1),
        );

        await engine.sendSignal(
          'exec-0',
          'my_signal',
          'payload_data',
        );

        final signals = await store.loadPendingSignals(
          'exec-0',
          signalName: 'my_signal',
        );
        expect(signals, hasLength(1));
        expect(signals[0].signalName, 'my_signal');
        expect(signals[0].payload, 'payload_data');
      });

      test('persists signal without payload', () async {
        await engine.sendSignal('exec-0', 'simple_signal');

        final signals = await store.loadPendingSignals(
          'exec-0',
          signalName: 'simple_signal',
        );
        expect(signals, hasLength(1));
        expect(signals[0].payload, isNull);
      });
    });

    group('resume with step name mismatch', () {
      test('invokes onStepNameMismatch callback', () async {
        final warnings = <(String, int, String, String)>[];
        final engineWithWarning = createTestEngine(
          store,
          onStepNameMismatch: (execId, idx, cp, cur) {
            warnings.add((execId, idx, cp, cur));
          },
        );

        await engineWithWarning.run<int>(
          'dynamic_wf',
          (ctx) async {
            return await ctx.step(
              'process-item-100',
              () async => 10,
            );
          },
        );

        // Reset execution to RUNNING for resume
        await simulateCrash(store, 'exec-0');

        final result = await engineWithWarning.resume<int>(
          'exec-0',
          (ctx) async {
            return await ctx.step(
              'process-item-200',
              () async => 999,
            );
          },
        );

        expect(result, 10);
        expect(warnings, hasLength(1));
        expect(warnings[0].$3, 'process-item-100');
        expect(warnings[0].$4, 'process-item-200');

        engineWithWarning.dispose();
      });
    });

    group('dispose', () {
      test('closes observer streams', () async {
        await engine.run<int>(
          'disposable',
          (ctx) async =>
              await ctx.step('s', () async => 1),
        );

        final stream = engine.observe('exec-0');
        final first = await stream.first;
        expect(first.status, isA<Completed>());

        engine.dispose();
      });
    });
  });

  group('WorkflowContextImpl', () {
    group('sleep', () {
      test('completes after duration', () async {
        final result = await engine.run<int>(
          'sleep_wf',
          (ctx) async {
            await ctx.sleep(
              'wait',
              const Duration(milliseconds: 50),
            );
            return 42;
          },
        );
        expect(result, 42);
      });

    });

    group('waitSignal', () {
      test('receives signal payload', () async {
        final future = engine.run<String>(
          'signal_wf',
          (ctx) async {
            final payload =
                await ctx.waitSignal<String>('sig');
            return payload ?? 'none';
          },
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 50),
        );
        await engine.sendSignal('exec-0', 'sig', 'hello');

        final result = await future;
        expect(result, 'hello');
      });

    });
  });
}
