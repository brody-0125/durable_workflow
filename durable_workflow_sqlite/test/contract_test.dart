@Tags(['integration'])
library;

import 'package:durable_workflow/testing.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:test/test.dart';

void main() {
  runCheckpointStoreContractTests(() {
    final store = SqliteCheckpointStore.inMemory();
    addTearDown(() => store.close());
    store.database.execute('PRAGMA foreign_keys = OFF');
    return store;
  });
}
