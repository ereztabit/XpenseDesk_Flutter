/// PC-5 sheet export: the two formats and the downloaded file's name.
enum SheetExportFormat {
  pdf('pdf', 'pdf', 'application/pdf'),
  excel(
    'excel',
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const SheetExportFormat(this.apiValue, this.extension, this.mimeType);

  final String apiValue;
  final String extension;
  final String mimeType;
}

/// The file name from `Content-Disposition` - `filename*=UTF-8''...` first,
/// then `filename="..."` - else `sheet-export.<ext>`. Path parts are dropped.
String sheetExportFileName(String? contentDisposition, SheetExportFormat format) {
  final fallback = 'sheet-export.${format.extension}';
  if (contentDisposition == null || contentDisposition.isEmpty) return fallback;

  String? name;
  final star = RegExp(r"filename\*\s*=\s*UTF-8''([^;]+)", caseSensitive: false)
      .firstMatch(contentDisposition);
  if (star != null) {
    try {
      name = Uri.decodeComponent(star.group(1)!.trim());
    } on ArgumentError {
      name = null;
    }
  }
  name ??= RegExp(r'filename\s*=\s*"?([^";]+)"?', caseSensitive: false)
      .firstMatch(contentDisposition)
      ?.group(1)
      ?.trim();

  if (name == null || name.isEmpty) return fallback;
  final base = name.split(RegExp(r'[\\/]')).last;
  return base.isEmpty ? fallback : base;
}
