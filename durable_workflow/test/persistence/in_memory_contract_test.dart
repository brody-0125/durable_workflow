@Tags(['unit'])
library;

import 'package:durable_workflow/testing.dart';
import 'package:test/test.dart';

void main() {
  runCheckpointStoreContractTests(() => InMemoryCheckpointStore());
}
