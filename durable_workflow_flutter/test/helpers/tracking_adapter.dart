import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';

class TrackingBackgroundAdapter implements BackgroundAdapter {
  final List<String> calls = [];

  @override
  Future<void> initialize() async => calls.add('initialize');

  @override
  Future<void> scheduleRecovery() async => calls.add('scheduleRecovery');

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<void> dispose() async => calls.add('dispose');
}
