import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sheet_export_service.dart';

/// PC-5: the sheet export (PDF / Excel download) service.
final sheetExportServiceProvider = Provider<SheetExportService>((ref) => SheetExportService());
