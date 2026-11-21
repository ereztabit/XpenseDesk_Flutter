import 'package:web/web.dart' as web;

import '../services/api_service.dart';
import '../services/excel_export_service.dart';
import 'admin_ai_utils.dart';

/// FS-1026: opens a receipt image in a new tab - https only, with no opener and
/// no referrer. Web-only (kept out of the display utils, which tests load on the VM).
void openAdminAiLink(String? url) {
  if (isSafeAdminAiLink(url)) web.window.open(url!, '_blank', 'noopener,noreferrer');
}

/// A receipt file that could not be fetched (not 2xx) - nothing was saved.
class AdminAiDownloadException implements Exception {
  const AdminAiDownloadException(this.statusCode);
  final int statusCode;
}

/// FS-1026: fetches a receipt file and saves it as [fileName] through a blob
/// (safe for a cross-origin link). Only a 2xx body is saved - an error page is
/// never stored as the image.
Future<void> downloadAdminAiFile(String url, String fileName, {ApiService? api}) async {
  final r = await (api ?? ApiService()).getExternalBytes(url);
  if (r.statusCode < 200 || r.statusCode > 299) throw AdminAiDownloadException(r.statusCode);
  ExcelExportService.downloadBytes(r.bytes, fileName, r.contentType ?? 'application/octet-stream');
}
