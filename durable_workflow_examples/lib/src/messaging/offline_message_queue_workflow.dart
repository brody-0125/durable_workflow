/// Messaging: Offline Message Queue Workflow
///
/// Use case:
///   Queue messages + media while offline, and when network recovers,
///   process in order: media upload → message send → server ACK receipt.
///
/// Common approaches in existing Flutter apps:
///   - Chat UI libraries: provide UI only. Send logic must be implemented by the app
///   - Protocol-specific chat apps: use SDK event queues. Protocol-dependent
///   - Firebase-based chat apps: rely on Firestore offline cache. Media upload dependencies managed manually
///   - Chat service SDKs: internal message queue. Third-party service dependent. Not customizable
///
/// With durable_workflow:
///   - Orchestrate media upload → message send as a single workflow
///   - Manage offline messages as a durable queue in SQLite
///   - RetryPolicy.exponential() for automatic resend on network recovery
///   - ctx.sleep() for wait between retries during network instability
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

// ---------------------------------------------------------------------------
// Simulated messaging services
// ---------------------------------------------------------------------------

class PendingMessage {
  final String messageId;
  final String chatId;
  final String text;
  final List<String> mediaFiles; // local file paths
  final DateTime createdAt;

  PendingMessage({
    required this.messageId,
    required this.chatId,
    required this.text,
    this.mediaFiles = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasMedia => mediaFiles.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'chatId': chatId,
        'text': text,
        'mediaCount': mediaFiles.length,
      };
}

Future<String> uploadMedia(String localPath) async {
  await Future.delayed(const Duration(milliseconds: 200));
  final url = 'https://media.example.com/${localPath.split('/').last}';
  print('    [step] Media uploaded: $localPath → $url');
  return url;
}

Future<void> deleteUploadedMedia(String url) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [compensate] Uploaded media deleted: $url');
}

Future<String> sendMessage(
    String chatId, String text, List<String> mediaUrls) async {
  await Future.delayed(const Duration(milliseconds: 150));
  final serverMsgId = 'SRV-${DateTime.now().millisecondsSinceEpoch}';
  final mediaLabel = mediaUrls.isEmpty ? '' : ' + ${mediaUrls.length} media';
  print('    [step] Message sent: "$text"$mediaLabel → $serverMsgId');
  return serverMsgId;
}

Future<bool> waitForDeliveryAck(String serverMsgId) async {
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [step] Delivery confirmed (ACK): $serverMsgId → delivered');
  return true;
}

Future<void> updateLocalMessageStatus(
    String messageId, String status, {String? serverMsgId}) async {
  await Future.delayed(const Duration(milliseconds: 30));
  print('    [step] Local status updated: $messageId → $status${serverMsgId != null ? " ($serverMsgId)" : ""}');
}

// ---------------------------------------------------------------------------
// Workflow definition
// ---------------------------------------------------------------------------

/// Offline message send workflow
///
/// Declaratively expresses the message delivery guarantee logic that
/// apps like Fluffychat, stream-chat, etc. implement in thousands of lines within their SDKs.
///
/// Key benefits:
///   - App termination after media upload → resumes from message send on restart (no media re-upload)
///   - On send failure, uploaded media is automatically cleaned up (saga compensation)
///   - Queued messages are processed sequentially on network recovery
///
/// Note: Dynamic step names ('upload_media_$i')
///   The mediaFiles list must be identical before and after crash for recovery to work correctly.
///   The message object must be stored as workflow input in the checkpoint to guarantee this.
Future<String> offlineMessageWorkflow(
  WorkflowContext ctx, {
  required PendingMessage message,
}) async {
  // Step 1: Update local status to "sending"
  await ctx.step<bool>(
    'mark_sending',
    () async {
      await updateLocalMessageStatus(message.messageId, 'sending');
      return true;
    },
  );

  // Step 2: Upload media files (individually checkpointed + compensated)
  final mediaUrls = <String>[];

  for (var i = 0; i < message.mediaFiles.length; i++) {
    final url = await ctx.step<String>(
      'upload_media_$i',
      () => uploadMedia(message.mediaFiles[i]),
      compensate: (result) => deleteUploadedMedia(result),
      retry: RetryPolicy.exponential(
        maxAttempts: 5,
        initialDelay: const Duration(seconds: 2),
        maxDelay: const Duration(seconds: 30),
      ),
      idempotencyKey: 'media-${message.messageId}-$i',
    );
    mediaUrls.add(url);
  }

  // Step 3: Send message to server
  final serverMsgId = await ctx.step<String>(
    'send_message',
    () => sendMessage(message.chatId, message.text, mediaUrls),
    retry: RetryPolicy.exponential(
      maxAttempts: 10,
      initialDelay: const Duration(seconds: 1),
      maxDelay: const Duration(minutes: 1),
    ),
    idempotencyKey: 'msg-${message.messageId}',
  );

  // Step 4: Wait for delivery confirmation
  await ctx.step<bool>(
    'wait_ack',
    () => waitForDeliveryAck(serverMsgId),
    retry: RetryPolicy.exponential(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 5),
    ),
  );

  // Step 5: Update local status to "delivered"
  await ctx.step<bool>(
    'mark_delivered',
    () async {
      await updateLocalMessageStatus(
        message.messageId,
        'delivered',
        serverMsgId: serverMsgId,
      );
      return true;
    },
  );

  return serverMsgId;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
  );

  try {
    print('=== Messaging: Offline Message Queue Workflow ===\n');

    // Send message with media attachments
    final message = PendingMessage(
      messageId: 'MSG-001',
      chatId: 'CHAT-42',
      text: 'Sending you the meeting materials',
      mediaFiles: [
        '/photos/meeting_notes.jpg',
        '/documents/agenda.pdf',
      ],
    );

    print('  Message: "${message.text}" (${message.mediaFiles.length} media files)\n');

    final result = await engine.run<String>(
      'offline_message',
      (ctx) => offlineMessageWorkflow(ctx, message: message),
    );

    print('\n  Message sent: server ID = $result');
  } catch (e) {
    print('\n  Message send failed: $e');
  } finally {
    engine.dispose();
  }
}
