/// IoT: Device Provisioning Workflow
///
/// Use case:
///   BLE scan → device connection → Wi-Fi credentials transfer → cloud registration → firmware update wait
///
/// Common approaches in existing Flutter apps:
///   - BLE provisioning libraries: per-device provisioning support. Restart from beginning on mid-failure
///   - BLE communication library-based apps: manage BLE connection state via Stream. Progress lost on app restart
///   - BLE example apps: each BLE step is independent. Orchestration is hardcoded in UI code
///   - Smart home apps: REST API call chains. Manual implementation of previous step cleanup on failure
///
/// With durable_workflow:
///   - Manage the entire BLE connection→configuration→registration process as a single durable workflow
///   - Automatic retry with exponential backoff on unstable BLE connections
///   - On firmware update failure after cloud registration, saga compensation rolls back registration
///   - ctx.waitSignal() durably waits for the device's firmware update completion event
library;

import 'dart:convert';

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

// ---------------------------------------------------------------------------
// Simulated IoT services
// ---------------------------------------------------------------------------

/// IoT device information.
///
/// Uses ctx.step()'s serialize/deserialize parameters for
/// safe serialization/deserialization during checkpoint storage and recovery.
class DeviceInfo {
  final String deviceId;
  final String macAddress;
  final String firmwareVersion;

  DeviceInfo({
    required this.deviceId,
    required this.macAddress,
    required this.firmwareVersion,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'macAddress': macAddress,
        'firmwareVersion': firmwareVersion,
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        deviceId: json['deviceId'] as String,
        macAddress: json['macAddress'] as String,
        firmwareVersion: json['firmwareVersion'] as String,
      );
}

Future<DeviceInfo> scanAndConnect(String targetMac) async {
  await Future.delayed(const Duration(milliseconds: 200));
  print('    [step] BLE device connected: $targetMac');
  return DeviceInfo(
    deviceId: 'DEV-${DateTime.now().millisecondsSinceEpoch}',
    macAddress: targetMac,
    firmwareVersion: '1.2.0',
  );
}

Future<bool> sendWifiCredentials(
    String deviceId, String ssid, String password) async {
  await Future.delayed(const Duration(milliseconds: 300));
  print('    [step] Wi-Fi credentials sent: $ssid → $deviceId');
  return true;
}

Future<bool> verifyWifiConnection(String deviceId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  print('    [step] Wi-Fi connection verified: $deviceId → internet accessible');
  return true;
}

Future<String> registerToCloud(DeviceInfo device) async {
  await Future.delayed(const Duration(milliseconds: 200));
  final registrationId = 'REG-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Cloud registered: ${device.deviceId} → $registrationId');
  return registrationId;
}

Future<void> unregisterFromCloud(String registrationId) async {
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [compensate] Cloud registration revoked: $registrationId');
}

Future<bool> checkFirmwareUpdate(String deviceId, String currentVersion) async {
  await Future.delayed(const Duration(milliseconds: 150));
  print('    [step] Firmware checked: $deviceId (current: $currentVersion, latest: 1.3.0)');
  return true; // update needed
}

Future<void> triggerFirmwareUpdate(String deviceId) async {
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [step] Firmware update OTA transfer started: $deviceId');
}

// ---------------------------------------------------------------------------
// Workflow definition
// ---------------------------------------------------------------------------

/// IoT device provisioning workflow
///
/// Implements the provisioning flow that tools like esp_provisioning handle linearly,
/// using durable workflow to gain:
///   - Automatic retry for unstable BLE connections
///   - Cloud registration rollback on mid-failure (compensation receives step result)
///   - Resume from last completed step on app restart
///   - Durably wait for device firmware update completion via ctx.waitSignal()
Future<String> provisioningWorkflow(
  WorkflowContext ctx, {
  required String targetMac,
  required String wifiSsid,
  required String wifiPassword,
}) async {
  // Step 1: BLE scan and connect (unstable → retry)
  // Ensure checkpoint recovery safety for DeviceInfo custom object via serialize/deserialize
  final device = await ctx.step<DeviceInfo>(
    'ble_connect',
    () => scanAndConnect(targetMac),
    retry: RetryPolicy.exponential(
      maxAttempts: 5,
      initialDelay: const Duration(seconds: 2),
      maxDelay: const Duration(seconds: 15),
    ),
    serialize: (info) => jsonEncode(info.toJson()),
    deserialize: (data) => DeviceInfo.fromJson(
      jsonDecode(data) as Map<String, dynamic>,
    ),
  );

  // Step 2: Send Wi-Fi credentials
  await ctx.step<bool>(
    'send_wifi_credentials',
    () => sendWifiCredentials(device.deviceId, wifiSsid, wifiPassword),
    retry: RetryPolicy.fixed(
      maxAttempts: 3,
      delay: const Duration(seconds: 3),
    ),
  );

  // Step 3: Verify Wi-Fi connection
  await ctx.step<bool>(
    'verify_wifi',
    () => verifyWifiConnection(device.deviceId),
    retry: RetryPolicy.exponential(
      maxAttempts: 5,
      initialDelay: const Duration(seconds: 3),
      maxDelay: const Duration(seconds: 20),
    ),
  );

  // Step 4: Cloud registration (compensation: revoke registration)
  final registrationId = await ctx.step<String>(
    'cloud_register',
    () => registerToCloud(device),
    compensate: (result) => unregisterFromCloud(result),
    idempotencyKey: 'register-${device.macAddress}',
  );

  // Step 5: Check firmware update
  final needsUpdate = await ctx.step<bool>(
    'check_firmware',
    () => checkFirmwareUpdate(device.deviceId, device.firmwareVersion),
  );

  if (needsUpdate) {
    // Step 6: Start firmware update OTA transfer
    await ctx.step<bool>(
      'trigger_firmware_update',
      () async {
        await triggerFirmwareUpdate(device.deviceId);
        return true;
      },
    );

    // Step 7: Durably wait until the device completes the firmware update
    //
    // ctx.waitSignal() records a PENDING signal in the DB.
    // Signal state is preserved even after app restart, so the device's
    // completion signal (engine.sendSignal()) is never missed.
    //
    // Actual flow: device OTA complete → server webhook → engine.sendSignal()
    final updateResult = await ctx.waitSignal<bool>(
      'firmware_update_complete',
      timeout: const Duration(minutes: 30),
    );
    print('    [signal] Firmware update result: $updateResult');
  }

  return registrationId;
}

// ---------------------------------------------------------------------------
// Main: waitSignal + sendSignal demonstration
// ---------------------------------------------------------------------------

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
  );

  try {
    print('=== IoT Device Provisioning Workflow ===\n');

    // Execute workflow asynchronously (suspended at waitSignal)
    final workflowFuture = engine.run<String>(
      'device_provisioning',
      (ctx) => provisioningWorkflow(
        ctx,
        targetMac: 'AA:BB:CC:DD:EE:FF',
        wifiSsid: 'HomeNetwork',
        wifiPassword: 'secure_pass_123',
      ),
    );

    // Simulation: device sends firmware update completion signal after 2 seconds
    // In a real app: server webhook or BLE notification → engine.sendSignal()
    Future.delayed(const Duration(seconds: 2), () async {
      final executions = await engine.store.loadExecutionsByStatus(
        [const Running(), const Suspended()],
      );
      for (final exec in executions) {
        print('    [external] Firmware update completion signal sent');
        await engine.sendSignal(
          exec.workflowExecutionId,
          'firmware_update_complete',
          true,
        );
      }
    });

    final result = await workflowFuture;
    print('\n  Provisioning completed: registration ID = $result');
  } catch (e) {
    print('\n  Provisioning failed: $e');
  } finally {
    engine.dispose();
  }
}
