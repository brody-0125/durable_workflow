@Tags(['integration'])
library;

import 'package:drift/native.dart';
import 'package:durable_workflow/testing.dart';
import 'package:durable_workflow_drift/durable_workflow_drift.dart';
import 'package:test/test.dart';

void main() {
  runCheckpointStoreContractTests(() {
    final db = DurableWorkflowDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    return DriftCheckpointStore(db);
  });
}
