/// Finance: KYC Onboarding Workflow
///
/// Use case:
///   ID photo capture → OCR verification → identity confirmation → credit check → account creation → welcome notification
///
/// Common approaches in existing Flutter apps:
///   - Banking apps: handle transfers as a single API call. Risk of duplicate transfers
///   - Payment gateway libraries: wrap payment APIs. Results lost if app terminates before callback
///   - Fintech boilerplates: save KYC progress in SharedPreferences. No atomicity guarantee
///   - Expense tracker apps: only save transaction records to local DB. Manual server sync retry
///
/// With durable_workflow:
///   - Each KYC step is checkpointed with idempotencyKey → prevents duplicate execution
///   - On credit check failure, saga compensation rolls back previous steps
///   - All steps are persisted in SQLite as an audit trail
library;

import 'dart:convert';

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

// ---------------------------------------------------------------------------
// Simulated KYC services
// ---------------------------------------------------------------------------

/// Identity verification result.
///
/// Uses ctx.step()'s serialize/deserialize parameters for
/// safe serialization/deserialization during checkpoint storage and recovery.
class IdVerificationResult {
  final String verificationId;
  final String fullName;
  final String idNumber;
  final bool isValid;

  IdVerificationResult({
    required this.verificationId,
    required this.fullName,
    required this.idNumber,
    required this.isValid,
  });

  Map<String, dynamic> toJson() => {
        'verificationId': verificationId,
        'fullName': fullName,
        'idNumber': idNumber,
        'isValid': isValid,
      };

  factory IdVerificationResult.fromJson(Map<String, dynamic> json) =>
      IdVerificationResult(
        verificationId: json['verificationId'] as String,
        fullName: json['fullName'] as String,
        idNumber: json['idNumber'] as String,
        isValid: json['isValid'] as bool,
      );
}

Future<String> uploadIdDocument(String imagePath) async {
  await Future.delayed(const Duration(milliseconds: 200));
  final docId = 'DOC-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] ID document uploaded: $imagePath → $docId');
  return docId;
}

Future<void> deleteUploadedDocument(String docId) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [compensate] Uploaded document deleted: $docId');
}

Future<IdVerificationResult> verifyIdentity(String docId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  final result = IdVerificationResult(
    verificationId: 'VER-${DateTime.now().millisecondsSinceEpoch}',
    fullName: 'John Doe',
    idNumber: '990101-1******',
    isValid: true,
  );
  print('    [step] Identity verified: ${result.fullName} (${result.verificationId})');
  return result;
}

Future<Map<String, dynamic>> checkCredit(String idNumber) async {
  await Future.delayed(const Duration(milliseconds: 300));
  final result = {
    'score': 750,
    'grade': 'A',
    'approved': true,
  };
  print('    [step] Credit check: score=${result['score']}, grade=${result['grade']}');
  return result;
}

Future<String> createAccount(String fullName, String verificationId) async {
  await Future.delayed(const Duration(milliseconds: 200));
  final accountId = 'ACC-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Account created: $accountId ($fullName)');
  return accountId;
}

Future<void> closeAccount(String accountId) async {
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [compensate] Account closed: $accountId');
}

Future<void> sendWelcomeNotification(String accountId, String fullName) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [step] Welcome notification sent: $fullName ($accountId)');
}

Future<void> issueVirtualCard(String accountId) async {
  await Future.delayed(const Duration(milliseconds: 150));
  print('    [step] Virtual card issued: $accountId');
}

// ---------------------------------------------------------------------------
// Workflow definition
// ---------------------------------------------------------------------------

/// KYC onboarding workflow
///
/// Implements the complex onboarding flow that fintech apps manage with
/// SharedPreferences + try-catch, using durable workflow.
///
/// Key benefits:
///   - Credit check API is paid → idempotencyKey prevents duplicate calls
///   - Card issuance failure after account creation → saga compensation closes the account
///   - All steps recorded in DB → automatic financial regulatory audit trail
///
/// ## Compensation Closure Pattern
///
/// The compensate: callback receives the step result as a parameter,
/// so you can use it directly without mutable variable workarounds.
Future<String> kycOnboardingWorkflow(
  WorkflowContext ctx, {
  required String userId,
  required String idImagePath,
}) async {
  // Step 1: Upload ID document (compensation: delete document)
  final docId = await ctx.step<String>(
    'upload_id_document',
    () => uploadIdDocument(idImagePath),
    compensate: (result) => deleteUploadedDocument(result),
    retry: RetryPolicy.exponential(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 2),
    ),
  );

  // Step 2: OCR + identity verification
  // Ensure checkpoint recovery safety for IdVerificationResult custom object via serialize/deserialize
  final verification = await ctx.step<IdVerificationResult>(
    'verify_identity',
    () => verifyIdentity(docId),
    retry: RetryPolicy.exponential(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 5),
      maxDelay: const Duration(seconds: 30),
    ),
    idempotencyKey: 'verify-$userId',
    serialize: (result) => jsonEncode(result.toJson()),
    deserialize: (data) => IdVerificationResult.fromJson(
      jsonDecode(data) as Map<String, dynamic>,
    ),
  );

  if (!verification.isValid) {
    throw Exception('Identity verification failed: ${verification.verificationId}');
  }

  // Step 3: Credit check (paid API → idempotency key required)
  final creditResult = await ctx.step<Map<String, dynamic>>(
    'check_credit',
    () => checkCredit(verification.idNumber),
    idempotencyKey: 'credit-$userId',
  );

  if (creditResult['approved'] != true) {
    throw Exception('Credit check not approved: grade=${creditResult['grade']}');
  }

  // Step 4: Create account (compensation: close account)
  final accountId = await ctx.step<String>(
    'create_account',
    () => createAccount(verification.fullName, verification.verificationId),
    compensate: (result) => closeAccount(result),
    idempotencyKey: 'account-$userId',
  );

  // Step 5: Issue virtual card
  await ctx.step<bool>(
    'issue_virtual_card',
    () async {
      await issueVirtualCard(accountId);
      return true;
    },
    retry: RetryPolicy.fixed(
      maxAttempts: 2,
      delay: const Duration(seconds: 3),
    ),
  );

  // Step 6: Welcome notification
  await ctx.step<bool>(
    'send_welcome',
    () async {
      await sendWelcomeNotification(accountId, verification.fullName);
      return true;
    },
  );

  return accountId;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
  );

  try {
    print('=== Finance: KYC Onboarding Workflow ===\n');

    final result = await engine.run<String>(
      'kyc_onboarding',
      (ctx) => kycOnboardingWorkflow(
        ctx,
        userId: 'USER-001',
        idImagePath: '/photos/id_card_front.jpg',
      ),
    );

    print('\n  KYC completed: account ID = $result');
  } catch (e) {
    print('\n  KYC failed: $e');
  } finally {
    engine.dispose();
  }
}
