import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Document-level `dragover`/`drop` plumbing shared by `WebFileDropGuard` and
/// `WebFileDropRegion`. Both always call `preventDefault()`: on `dragover` so
/// the drop is allowed at all, and on `drop` so the browser never opens the
/// file itself.
class DocumentDragListener {
  DocumentDragListener({required this.onOver, required this.onDrop});

  final ValueChanged<web.DragEvent> onOver;
  final ValueChanged<web.DragEvent> onDrop;

  late final JSFunction _overCallback = ((web.Event event) {
    event.preventDefault();
    if (event.isA<web.DragEvent>()) onOver(event as web.DragEvent);
  }).toJS;

  late final JSFunction _dropCallback = ((web.Event event) {
    event.preventDefault();
    if (event.isA<web.DragEvent>()) onDrop(event as web.DragEvent);
  }).toJS;

  void attach() {
    web.document.addEventListener('dragover', _overCallback);
    web.document.addEventListener('drop', _dropCallback);
  }

  void detach() {
    web.document.removeEventListener('dragover', _overCallback);
    web.document.removeEventListener('drop', _dropCallback);
  }
}
