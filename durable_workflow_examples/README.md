# durable_workflow_examples

**[Korean README](README.ko.md)**

Use-case catalog for the [`durable_workflow`](../durable_workflow/) library.
Demonstrates real-world durable workflow patterns across 7 categories.

## Category Overview

| # | Category | Core Problem | Representative Use Case |
|---|----------|-------------|------------------------|
| 1 | [E-Commerce](#1-e-commerce) | Multi-step order transactions | Checkout, refund, inventory |
| 2 | [File Sync & Upload](#2-file-sync--upload) | Chunked file upload/sync | Resume upload, cloud sync |
| 3 | [IoT & Device Provisioning](#3-iot--device-provisioning) | Device register → configure → firmware | Smart home, BLE provisioning |
| 4 | [Finance & Banking](#4-finance--banking) | Regulatory-compliant transfer workflows | KYC, P2P transfer, rewards |
| 5 | [Desktop App](#5-desktop-app) | Long-running install/migration tasks | Installer, DB migration, batch |
| 6 | [Messaging & Chat](#6-messaging--chat) | Guaranteed message delivery, offline queue | Message retry, media upload |
| 7 | [Healthcare](#7-healthcare) | Multi-step patient registration | Patient onboarding, prescriptions |

## 1. E-Commerce

### Problem
The checkout flow is a multi-step process: `inventory check → payment → order creation → shipping request`. If the app crashes mid-flow, you can end up with a payment charged but no order created — an **inconsistent state**.

### How durable_workflow Helps
- Each step (inventory check, payment, order creation) is **checkpointed**
- Crash after payment → on restart, payment step is **skipped from cache**, resumes from order creation
- Shipping failure → **saga compensation** automatically refunds the payment

> Example: [`lib/src/ecommerce/checkout_workflow.dart`](lib/src/ecommerce/checkout_workflow.dart)

## 2. File Sync & Upload

### Problem
When uploading large files in chunks, network disconnection or app termination mid-upload means starting over from the beginning.

### How durable_workflow Helps
- Each chunk upload is a **checkpointed step**
- Crash at chunk 47/100 → resumes from chunk 48 on restart
- Upload failure → saga compensation cleans up partial uploads

> Example: [`lib/src/file_sync/chunked_upload_workflow.dart`](lib/src/file_sync/chunked_upload_workflow.dart)

## 3. IoT & Device Provisioning

### Problem
Device provisioning involves multiple steps: `discover → authenticate → configure → firmware update → verify`. Failure mid-provisioning leaves devices in an unknown state.

### How durable_workflow Helps
- Each provisioning step is checkpointed and retryable
- BLE disconnection during firmware update → resumes from last successful step
- Failed provisioning → saga compensation resets device to factory state

> Example: [`lib/src/iot_device/provisioning_workflow.dart`](lib/src/iot_device/provisioning_workflow.dart)

## 4. Finance & Banking

### Problem
Financial workflows like KYC onboarding involve `identity verification → document validation → risk assessment → account creation`. These must be completed atomically and comply with regulations.

### How durable_workflow Helps
- Each verification step is durably persisted with audit trail
- App crash during risk assessment → resumes without re-uploading documents
- Failed account creation → saga compensation reverts all verification records

> Example: [`lib/src/finance/kyc_onboarding_workflow.dart`](lib/src/finance/kyc_onboarding_workflow.dart)

## 5. Desktop App

### Problem
Desktop applications often perform long-running operations: database migrations, data imports, batch processing. Interruption means data corruption or incomplete state.

### How durable_workflow Helps
- Each migration/import step is individually checkpointed
- Process kill during migration → resumes from exact step on restart
- Failed migration → saga compensation rolls back completed steps

> Example: [`lib/src/desktop/data_migration_workflow.dart`](lib/src/desktop/data_migration_workflow.dart)

## 6. Messaging & Chat

### Problem
Offline message queuing requires guaranteed delivery: `compose → encrypt → upload media → send → confirm`. Messages can be lost if the app crashes between steps.

### How durable_workflow Helps
- Message send pipeline is a durable workflow with checkpointed steps
- Crash after media upload → on restart, skips upload, proceeds to send
- Durable signals allow waiting for server delivery confirmation

> Example: [`lib/src/messaging/offline_message_queue_workflow.dart`](lib/src/messaging/offline_message_queue_workflow.dart)

## 7. Healthcare

### Problem
Patient onboarding involves `registration → insurance verification → consent → appointment scheduling`. Incomplete onboarding leads to missing records and scheduling failures.

### How durable_workflow Helps
- Each onboarding step is durably persisted
- App crash during insurance verification → resumes without re-entering patient data
- Failed scheduling → saga compensation notifies relevant departments

> Example: [`lib/src/healthcare/patient_onboarding_workflow.dart`](lib/src/healthcare/patient_onboarding_workflow.dart)

---

## Running the Examples

```bash
# Run an example
cd durable_workflow_examples
dart run lib/src/ecommerce/checkout_workflow.dart

# Each category
dart run lib/src/file_sync/chunked_upload_workflow.dart
dart run lib/src/iot_device/provisioning_workflow.dart
dart run lib/src/finance/kyc_onboarding_workflow.dart
dart run lib/src/desktop/data_migration_workflow.dart
dart run lib/src/messaging/offline_message_queue_workflow.dart
dart run lib/src/healthcare/patient_onboarding_workflow.dart
```

---

## Known Limitations & API Improvement Notes

These examples use the `durable_workflow` library API as-is.
Here are practical limitations to be aware of.

### 1. ~~Compensation Closure Cannot Directly Capture Step Result~~ (Resolved)

`compensate:` now receives the step result as an argument (`Future<void> Function(T result)?`):

```dart
final txId = await ctx.step<String>(
  'process_payment',
  () => processPayment(orderId, amount),
  compensate: (result) => refundPayment(result),
);
```

### 2. ~~Custom Object Checkpoint Serialization~~ (Resolved)

`WorkflowContext.step<T>()` now supports `serialize`/`deserialize` parameters for safe
checkpoint storage and recovery of custom objects.

```dart
final device = await ctx.step<DeviceInfo>(
  'ble_connect',
  () => scanAndConnect(targetMac),
  serialize: (info) => jsonEncode(info.toJson()),
  deserialize: (data) => DeviceInfo.fromJson(
    jsonDecode(data) as Map<String, dynamic>,
  ),
);
```

**Applied examples:** IoT(`DeviceInfo`), Finance(`IdVerificationResult`)

### 3. All Examples Use InMemoryCheckpointStore

All state is lost on process termination. For production use, replace with
`SqliteCheckpointStore` (from `durable_workflow_sqlite`) or `DriftCheckpointStore`
(from `durable_workflow_drift`). `InMemoryCheckpointStore` is test/demo only —
import from `package:durable_workflow/testing.dart`.

### 4. Recovery Safety of Dynamic Step Names

Loop-based steps (`migrate_batch_$i`, `upload_chunk_$i`) require parameters to be
identical before and after crash for step names to match. In production, persist workflow
input in the checkpoint to guarantee this.

---

## Project Structure

```
durable_workflow_examples/
└── lib/src/
    ├── ecommerce/       Checkout workflow
    ├── file_sync/       Chunked upload workflow
    ├── iot_device/      Device provisioning workflow
    ├── finance/         KYC onboarding workflow
    ├── desktop/         Data migration workflow
    ├── messaging/       Offline message queue workflow
    └── healthcare/      Patient onboarding workflow
```

## License

See the repository root for license information.
