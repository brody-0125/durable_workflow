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

  group('concurrent workflow execution', () {
    test('multiple workflows run concurrently without interference', () async {
      final results = await Future.wait([
        engine.run<int>('wf_a', (ctx) async {
          await ctx.step('step_a1', () async => 1);
          return await ctx.step('step_a2', () async => 10);
        }),
        engine.run<int>('wf_b', (ctx) async {
          await ctx.step('step_b1', () async => 2);
          return await ctx.step('step_b2', () async => 20);
        }),
        engine.run<int>('wf_c', (ctx) async {
          await ctx.step('step_c1', () async => 3);
          return await ctx.step('step_c2', () async => 30);
        }),
      ]);

      expect(results, [10, 20, 30]);
    });

    test('five workflows complete without race condition', () async {
      final results = await Future.wait(
        List.generate(5, (i) {
          return engine.run<String>('wf_$i', (ctx) async {
            await ctx.step('init_$i', () async => 'init');
            return await ctx.step('compute_$i', () async => 'result_$i');
          });
        }),
      );

      expect(results, List.generate(5, (i) => 'result_$i'));
    });
  });

  group('dispose safety', () {
    test('dispose after completion is safe', () {
      engine.dispose();
      // Second dispose is no-op
      engine.dispose();
    });

    test('run after dispose throws StateError', () async {
      engine.dispose();
      await expectLater(
        engine.run<void>('test', (ctx) async {}),
        throwsStateError,
      );
    });
  });

  group('recovery scanner reentrance', () {
    test('concurrent scan calls return safely', () async {
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final results = await Future.wait([
        scanner.scan(workflowRegistry: {}),
        scanner.scan(workflowRegistry: {}),
      ]);

      // At least one should complete, the other returns empty (reentrance guard)
      expect(results.length, 2);
    });
  });

  group('DurableEngineObserver', () {
    test('observer receives execution start and complete events', () async {
      final events = <String>[];
      final observer = _TestObserver(events);
      final observedEngine = DurableEngineImpl(
        store: store,
        observers: [observer],
      );

      await observedEngine.run<int>('observed_wf', (ctx) async {
        return await ctx.step('compute', () async => 42);
      });

      expect(events, contains(startsWith('start:')));
      expect(events, contains(startsWith('complete:')));

      observedEngine.dispose();
    });

    test('observer error does not affect engine', () async {
      final engine = DurableEngineImpl(
        store: store,
        observers: [_ThrowingObserver()],
      );

      final result = await engine.run<int>('safe_wf', (ctx) async {
        return await ctx.step('step1', () async => 99);
      });

      expect(result, 99);
      engine.dispose();
    });
  });

  group('input validation', () {
    test('empty workflowType throws ArgumentError', () async {
      await expectLater(
        engine.run<void>('', (ctx) async {}),
        throwsArgumentError,
      );
    });

    test('control character in step name throws ArgumentError', () async {
      await expectLater(
        engine.run<void>('valid_wf', (ctx) async {
          await ctx.step('step\x00name', () async => null);
        }),
        throwsArgumentError,
      );
    });

    test('overly long workflowType throws ArgumentError', () async {
      final longName = 'x' * 257;
      await expectLater(
        engine.run<void>(longName, (ctx) async {}),
        throwsArgumentError,
      );
    });
  });
}

class _TestObserver extends DurableEngineObserver {
  final List<String> events;
  _TestObserver(this.events);

  @override
  void onExecutionStart(String executionId, String workflowType) {
    events.add('start:$executionId:$workflowType');
  }

  @override
  void onExecutionComplete(String executionId, ExecutionStatus status) {
    events.add('complete:$executionId:$status');
  }
}

class _ThrowingObserver extends DurableEngineObserver {
  @override
  void onExecutionStart(String executionId, String workflowType) {
    throw Exception('Observer failure!');
  }
}
