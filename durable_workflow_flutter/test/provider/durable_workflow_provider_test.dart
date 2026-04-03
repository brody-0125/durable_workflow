import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryCheckpointStore store;

  setUp(() {
    store = InMemoryCheckpointStore();
  });

  group('DurableWorkflowProvider', () {
    testWidgets('provides engine via of()', (tester) async {
      DurableEngine? capturedEngine;

      await tester.pumpWidget(
        DurableWorkflowProvider(
          store: store,
          workflowRegistry: const {},
          child: Builder(
            builder: (context) {
              capturedEngine = DurableWorkflowProvider.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedEngine, isNotNull);
      expect(capturedEngine, isA<DurableEngineImpl>());
    });

    testWidgets('provides recovery results stream via recoveryResults()',
        (tester) async {
      Stream<RecoveryScanResult>? capturedStream;

      await tester.pumpWidget(
        DurableWorkflowProvider(
          store: store,
          workflowRegistry: const {},
          child: Builder(
            builder: (context) {
              capturedStream =
                  DurableWorkflowProvider.recoveryResults(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedStream, isNotNull);
    });

    testWidgets('of() throws when no provider in tree', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => DurableWorkflowProvider.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('recoveryResults() throws when no provider in tree',
        (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => DurableWorkflowProvider.recoveryResults(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        DurableWorkflowProvider(
          store: store,
          workflowRegistry: const {},
          child: const MaterialApp(
            home: Scaffold(body: Text('Hello')),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('disposes cleanly', (tester) async {
      await tester.pumpWidget(
        DurableWorkflowProvider(
          store: store,
          workflowRegistry: const {},
          child: const SizedBox(),
        ),
      );

      // Disposing the widget should not throw
      await tester.pumpWidget(const SizedBox());
    });
  });
}
