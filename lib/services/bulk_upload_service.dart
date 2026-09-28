import 'dart:typed_data';

import '../models/bulk_upload_batch.dart';
import '../models/staged_file.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// A refusal from a bulk-upload endpoint (api-guide §4.2, §5).
///
/// [errorCode] is the server's flat `ApiErrorCodes` name — the client maps it
/// to its own copy and never shows [message]. [statusCode] is 0 when the
/// failure was local (no session token).
class BulkUploadException implements Exception {
  final int statusCode;
  final String? errorCode;
  final String message;
  final Map<String, dynamic>? data;

  const BulkUploadException(
    this.message, {
    this.statusCode = 0,
    this.errorCode,
    this.data,
  });

  /// 5xx, or no status at all — worth a Retry, unlike a 4xx rule refusal.
  bool get isTransient => statusCode == 0 || statusCode >= 500;

  @override
  String toString() => message;
}

/// One staging upload in flight, from [BulkUploadService.stageFile].
class StagingUpload {
  StagingUpload._(this.result, this._cancel);

  /// Completes with the staged file, or errors with [BulkUploadException],
  /// [NetworkException], [UnauthorizedException] or
  /// [UploadCancelledException].
  final Future<StagedFile> result;
  final void Function() _cancel;

  void cancel() => _cancel();
}

/// Client for the bulk receipt upload API (FS-1007, backend
/// `docs/bulk-upload/api-guide.md`).
class BulkUploadService {
  final ApiService _apiService;
  final AuthService _authService;

  BulkUploadService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  Future<String> _requireSessionToken() async {
    final token = await _authService.getSessionToken();
    if (token == null || token.isEmpty) {
      throw const BulkUploadException('No session token found');
    }
    return token;
  }

  BulkUploadException _refusal(
    int statusCode,
    Map<String, dynamic> body,
    String fallback,
  ) {
    return BulkUploadException(
      body['message'] as String? ?? fallback,
      statusCode: statusCode,
      errorCode: body['errorCode'] as String?,
      data: body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null,
    );
  }

  /// POST /api/bulk-uploads/files — parks one file in staging. Nothing is
  /// written to the database until [submit].
  StagingUpload stageFile(
    Uint8List bytes,
    String filename, {
    void Function(double fraction)? onProgress,
  }) {
    UploadTask? task;
    var cancelled = false;

    Future<StagedFile> run() async {
      final token = await _requireSessionToken();
      if (cancelled) throw const UploadCancelledException();

      task = _apiService.uploadFileWithProgress(
        '/api/bulk-uploads/files',
        fieldName: 'file',
        bytes: bytes,
        filename: filename,
        authToken: token,
        onProgress: onProgress,
      );
      final response = await task!.result;
      final body = response.body;

      if (response.statusCode != 200 || body['success'] != true) {
        throw _refusal(response.statusCode, body, 'Failed to stage file');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw BulkUploadException('Invalid response from server',
            statusCode: response.statusCode);
      }
      return StagedFile.fromJson(data);
    }

    return StagingUpload._(run(), () {
      cancelled = true;
      task?.abort();
    });
  }

  /// POST /api/bulk-uploads — sends the staged files as one batch and
  /// returns its `batchId`.
  Future<String> submit(
    List<({String stagedFileId, String originalFileName})> files,
  ) async {
    final token = await _requireSessionToken();
    final response = await _apiService.postWithStatus(
      '/api/bulk-uploads',
      {
        'files': [
          for (final f in files)
            {
              'stagedFileId': f.stagedFileId,
              'originalFileName': f.originalFileName,
            },
        ],
      },
      authToken: token,
    );

    final body = response.body;
    if (response.statusCode != 200 || body['success'] != true) {
      throw _refusal(response.statusCode, body, 'Failed to send batch');
    }
    final data = body['data'] as Map<String, dynamic>?;
    return data?['batchId'] as String? ?? '';
  }

  /// GET /api/bulk-uploads — the caller's 10 most recent batches, newest
  /// first. Not blocked by the company flag (api-guide §2).
  Future<List<BulkUploadBatch>> getBatches() async {
    final token = await _requireSessionToken();
    final response = await _apiService.getWithStatus(
      '/api/bulk-uploads',
      authToken: token,
    );

    final body = response.body;
    if (response.statusCode != 200 || body['success'] != true) {
      throw _refusal(response.statusCode, body, 'Failed to load batches');
    }
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(BulkUploadBatch.fromJson)
        .toList();
  }
}
