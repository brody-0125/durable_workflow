/// Healthcare: Patient Onboarding Workflow
///
/// Use case:
///   Patient info entry → identity verification → insurance eligibility check → consent signing → appointment creation → notification
///
/// Common approaches in existing Flutter apps:
///   - Medical info system clients: REST-based registration. No offline (remote area medical) support
///   - Health data sync libraries: data gaps on sync failure. Cannot resume partial sync
///   - Hospital management apps: CRUD-based. No multi-step intake workflow
///   - E-prescription apps: no prescription send retry. Manual status tracking
///
/// With durable_workflow:
///   - Manage the entire patient onboarding process as a single durable workflow
///   - On insurance check failure, saga compensation rolls back previous steps
///   - All steps recorded in SQLite → naturally provides regulatory compliance audit trail
///   - Execute workflow in offline environment → sync when network recovers
///   - ctx.sleep() handles insurance company response wait time
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

// ---------------------------------------------------------------------------
// Simulated healthcare services
// ---------------------------------------------------------------------------

class PatientRecord {
  final String patientId;
  final String fullName;
  final DateTime dateOfBirth;
  final String insuranceId;

  PatientRecord({
    required this.patientId,
    required this.fullName,
    required this.dateOfBirth,
    required this.insuranceId,
  });

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'insuranceId': insuranceId,
      };
}

Future<String> createPatientRecord(
    String fullName, DateTime dob, String insuranceId) async {
  await Future.delayed(const Duration(milliseconds: 150));
  final patientId = 'PAT-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Patient record created: $patientId ($fullName)');
  return patientId;
}

Future<void> deletePatientRecord(String patientId) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [compensate] Patient record deleted: $patientId');
}

Future<bool> verifyPatientIdentity(String patientId, String idNumber) async {
  await Future.delayed(const Duration(milliseconds: 300));
  print('    [step] Identity verified: $patientId → confirmed');
  return true;
}

Future<Map<String, dynamic>> checkInsuranceEligibility(
    String insuranceId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  final result = {
    'eligible': true,
    'planType': 'Premium',
    'copay': 15000,
    'deductible': 50000,
  };
  print('    [step] Insurance eligibility checked: $insuranceId → ${result['planType']} (copay ₩${result['copay']})');
  return result;
}

Future<String> recordConsent(String patientId, List<String> consentTypes) async {
  await Future.delayed(const Duration(milliseconds: 100));
  final consentId = 'CON-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Consent recorded: $consentId (${consentTypes.join(", ")})');
  return consentId;
}

Future<String> createAppointment(
    String patientId, String department, DateTime preferredDate) async {
  await Future.delayed(const Duration(milliseconds: 200));
  final appointmentId = 'APT-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Appointment created: $appointmentId ($department, ${preferredDate.toIso8601String().substring(0, 10)})');
  return appointmentId;
}

Future<void> cancelAppointment(String appointmentId) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [compensate] Appointment cancelled: $appointmentId');
}

Future<void> sendAppointmentReminder(
    String patientId, String appointmentId) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [step] Appointment reminder sent: $patientId ($appointmentId)');
}

// ---------------------------------------------------------------------------
// Workflow definition
// ---------------------------------------------------------------------------

/// Patient onboarding workflow
///
/// Integrates the multi-step intake process that apps like OpenMRS, hospital_management
/// handle via individual REST calls, into a single durable workflow.
///
/// Key benefits:
///   - Workflow can execute even in offline remote medical environments
///   - Safely waits for delayed insurance API responses with durable timer
///   - On insurance denial, saga compensation rolls back previous steps (patient record)
///   - HIPAA compliance: all steps recorded in DB as audit trail
Future<String> patientOnboardingWorkflow(
  WorkflowContext ctx, {
  required String fullName,
  required DateTime dateOfBirth,
  required String idNumber,
  required String insuranceId,
  required String department,
  required DateTime preferredDate,
}) async {
  // Step 1: Create patient record (compensation: delete record)
  final patientId = await ctx.step<String>(
    'create_patient_record',
    () => createPatientRecord(fullName, dateOfBirth, insuranceId),
    compensate: (result) => deletePatientRecord(result),
  );

  // Step 2: Identity verification
  final verified = await ctx.step<bool>(
    'verify_identity',
    () => verifyPatientIdentity(patientId, idNumber),
    retry: RetryPolicy.exponential(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 2),
    ),
  );

  if (!verified) {
    throw Exception('Identity verification failed: $patientId');
  }

  // Step 3: Insurance eligibility check (external API → retry + idempotency)
  final insurance = await ctx.step<Map<String, dynamic>>(
    'check_insurance',
    () => checkInsuranceEligibility(insuranceId),
    retry: RetryPolicy.exponential(
      maxAttempts: 5,
      initialDelay: const Duration(seconds: 3),
      maxDelay: const Duration(seconds: 30),
    ),
    idempotencyKey: 'insurance-$insuranceId',
  );

  if (insurance['eligible'] != true) {
    throw Exception('Insurance eligibility not met: $insuranceId');
  }

  // Step 4: Record consent
  await ctx.step<String>(
    'record_consent',
    () => recordConsent(patientId, [
      'Personal data collection consent',
      'Treatment consent',
      'Insurance claim consent',
    ]),
  );

  // Step 5: Create appointment (compensation: cancel appointment)
  final appointmentId = await ctx.step<String>(
    'create_appointment',
    () => createAppointment(patientId, department, preferredDate),
    compensate: (result) => cancelAppointment(result),
  );

  // Step 6: Send notification
  await ctx.step<bool>(
    'send_reminder',
    () async {
      await sendAppointmentReminder(patientId, appointmentId);
      return true;
    },
  );

  return appointmentId;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
  );

  try {
    print('=== Healthcare: Patient Onboarding Workflow ===\n');

    final result = await engine.run<String>(
      'patient_onboarding',
      (ctx) => patientOnboardingWorkflow(
        ctx,
        fullName: 'Kim Patient',
        dateOfBirth: DateTime(1990, 3, 15),
        idNumber: '900315-1******',
        insuranceId: 'INS-2024-001',
        department: 'Internal Medicine',
        preferredDate: DateTime(2026, 4, 1),
      ),
    );

    print('\n  Onboarding completed: appointment ID = $result');
  } catch (e) {
    print('\n  Onboarding failed: $e');
  } finally {
    engine.dispose();
  }
}
