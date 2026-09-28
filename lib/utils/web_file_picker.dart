import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Opens the browser's multi-select file picker filtered to [extensions]
/// (lower-case, with the dot). Completes with the picked files; a cancelled
/// picker simply never completes, the same as the single-file picker on the
/// new-expense screen.
Future<List<web.File>> pickWebFiles(List<String> extensions) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = true
    ..accept = extensions.join(',');
  input.click();

  await input.onChange.first;
  return webFileListToList(input.files);
}

/// A `FileList` (picker or drop) as a Dart list, in order.
List<web.File> webFileListToList(web.FileList? files) {
  if (files == null) return const [];
  return [
    for (var i = 0; i < files.length; i++)
      if (files.item(i) != null) files.item(i)!,
  ];
}

Future<Uint8List> readWebFileBytes(web.File file) async {
  final buffer = await file.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}
