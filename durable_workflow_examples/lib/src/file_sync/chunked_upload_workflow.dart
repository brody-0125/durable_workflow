/// File Sync: Chunked Upload Workflow
///
/// Use case:
///   Upload large files in chunks, then request the server to assemble them upon completion.
///   On network disconnection or app termination, resumes from the last successful chunk.
///
/// Common approaches in existing Flutter apps:
///   - Resumable upload libraries: single file upload based on specific protocols. No multi-file orchestration
///   - Background transfer libraries: OS-level background transfer. Cannot handle inter-file dependencies
///   - Photo backup apps: implement custom retry/resume logic across thousands of lines
///   - File sync apps: implement custom sync queue via SQLite queue table. No compensation logic
///
/// With durable_workflow:
///   - Each chunk upload is checkpointed as an individual step → auto-resume on app restart
///   - On upload failure, already uploaded chunks are automatically cleaned up (server-side) via compensation
///   - Multi-file sync can be orchestrated as a single workflow
///
/// Note: Dynamic step names ('upload_chunk_$i')
///   Must re-execute with the same chunkSizeBytes after crash recovery so step names match.
///   If fileSizeBytes or chunkSizeBytes changes, totalChunks will differ,
///   causing step name mismatches and breaking recovery.
///   In production, these values should be stored as workflow input in the checkpoint.
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

// ---------------------------------------------------------------------------
// Simulated chunked upload service
// ---------------------------------------------------------------------------

class FileChunk {
  final String fileId;
  final int index;
  final int totalChunks;
  final int sizeBytes;

  FileChunk({
    required this.fileId,
    required this.index,
    required this.totalChunks,
    required this.sizeBytes,
  });

  @override
  String toString() => 'Chunk($fileId:$index/$totalChunks, ${sizeBytes}B)';
}

Future<String> initUploadSession(String fileName, int totalChunks) async {
  await Future.delayed(const Duration(milliseconds: 100));
  final sessionId = 'UPLOAD-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Upload session started: $sessionId ($fileName, $totalChunks chunks)');
  return sessionId;
}

Future<String> uploadChunk(String sessionId, FileChunk chunk) async {
  await Future.delayed(const Duration(milliseconds: 80));
  final etag = 'etag-${chunk.index}-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Chunk uploaded: ${chunk.index + 1}/${chunk.totalChunks} → $etag');
  return etag;
}

Future<String> completeUpload(String sessionId, List<String> etags) async {
  await Future.delayed(const Duration(milliseconds: 100));
  final fileUrl = 'https://cdn.example.com/files/$sessionId';
  print('    [step] Upload completed: $fileUrl (${etags.length} chunks assembled)');
  return fileUrl;
}

Future<void> abortUpload(String sessionId) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [compensate] Upload session aborted: $sessionId (server chunks cleaned up)');
}

Future<void> updateFileMetadata(String fileUrl, Map<String, String> meta) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [step] Metadata updated: ${meta['name']} → $fileUrl');
}

// ---------------------------------------------------------------------------
// Workflow definition
// ---------------------------------------------------------------------------

/// Chunked file upload workflow
///
/// Expresses the logic that apps like immich, syncreve, etc. implement
/// across thousands of lines, in ~40 lines with durable_workflow.
///
/// Crash scenario:
///   1. App crashes after uploading chunk 3/5
///   2. App restarts → RecoveryScanner resumes execution
///   3. Chunks 1~3 are skipped from cache (no re-upload)
///   4. Upload continues from chunk 4
Future<String> chunkedUploadWorkflow(
  WorkflowContext ctx, {
  required String fileName,
  required int fileSizeBytes,
  int chunkSizeBytes = 5 * 1024 * 1024, // 5MB
}) async {
  final totalChunks = (fileSizeBytes / chunkSizeBytes).ceil();

  // Step 1: Initialize upload session (compensation: abort session)
  final sessionId = await ctx.step<String>(
    'init_session',
    () => initUploadSession(fileName, totalChunks),
    compensate: (result) => abortUpload(result),
  );

  // Steps 2~N: Upload each chunk (individually checkpointed)
  final etags = <String>[];
  for (var i = 0; i < totalChunks; i++) {
    final chunk = FileChunk(
      fileId: sessionId,
      index: i,
      totalChunks: totalChunks,
      sizeBytes: i < totalChunks - 1
          ? chunkSizeBytes
          : fileSizeBytes % chunkSizeBytes,
    );

    final etag = await ctx.step<String>(
      'upload_chunk_$i',
      () => uploadChunk(sessionId, chunk),
      retry: RetryPolicy.exponential(
        maxAttempts: 5,
        initialDelay: const Duration(seconds: 2),
        maxDelay: const Duration(seconds: 30),
      ),
      idempotencyKey: 'chunk-$sessionId-$i',
    );
    etags.add(etag);
  }

  // Step N+1: Request server assembly
  final fileUrl = await ctx.step<String>(
    'complete_upload',
    () => completeUpload(sessionId, etags),
    retry: RetryPolicy.exponential(maxAttempts: 3),
  );

  // Step N+2: Update metadata
  await ctx.step<bool>(
    'update_metadata',
    () async {
      await updateFileMetadata(fileUrl, {'name': fileName});
      return true;
    },
  );

  return fileUrl;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
  );

  try {
    print('=== File Sync: Chunked Upload Workflow ===\n');

    final result = await engine.run<String>(
      'chunked_upload',
      (ctx) => chunkedUploadWorkflow(
        ctx,
        fileName: 'design_mockup_v3.psd',
        fileSizeBytes: 23 * 1024 * 1024, // 23MB → 5 chunks
      ),
    );

    print('\n  Upload completed: $result');
  } catch (e) {
    print('\n  Upload failed: $e');
  } finally {
    engine.dispose();
  }
}
