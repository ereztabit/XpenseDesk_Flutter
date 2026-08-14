import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Swallows file drags anywhere in the document while it is mounted.
///
/// Without this the browser handles a stray drop itself and navigates the tab
/// to the dropped file, throwing away whatever the user had typed. Wrap a
/// screen that must survive a missed drop; [WebFileDropRegion] nests inside it
/// and adds the accepting behaviour for its own box.
class WebFileDropGuard extends StatefulWidget {
  const WebFileDropGuard({super.key, required this.child});

  final Widget child;

  @override
  State<WebFileDropGuard> createState() => _WebFileDropGuardState();
}

class _WebFileDropGuardState extends State<WebFileDropGuard> {
  late final _DocumentDragListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = _DocumentDragListener(onOver: (_) {}, onDrop: (_) {})..attach();
  }

  @override
  void dispose() {
    _listener.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A drop target for a single receipt file on Flutter web.
///
/// Flutter paints to a canvas, so there is no DOM node to hang drag handlers
/// on: the events are taken from the document and hit-tested against this
/// widget's own box. [builder] is rebuilt with `isDragOver` true while a drag
/// hovers the box so the caller can reuse its existing hover styling.
///
/// Drops are always prevented from reaching the browser (see
/// [WebFileDropGuard]); only a drop that lands inside the box is delivered to
/// [onFile].
class WebFileDropRegion extends StatefulWidget {
  const WebFileDropRegion({
    super.key,
    required this.allowedExtensions,
    required this.onFile,
    required this.builder,
    this.onUnsupportedType,
    this.onMultipleFiles,
  });

  /// Lower-case extensions with the dot, e.g. `['.jpg', '.png', '.pdf']`.
  final List<String> allowedExtensions;

  /// Called with the dropped file once it passes the extension check.
  final ValueChanged<web.File> onFile;

  /// Called instead of [onFile] when the dropped file is not an allowed type.
  final VoidCallback? onUnsupportedType;

  /// Called instead of [onFile] when several files are dropped at once — a
  /// receipt is one file, so a multi-file drop is refused rather than guessed.
  final VoidCallback? onMultipleFiles;

  final Widget Function(BuildContext context, bool isDragOver) builder;

  @override
  State<WebFileDropRegion> createState() => _WebFileDropRegionState();
}

class _WebFileDropRegionState extends State<WebFileDropRegion> {
  final GlobalKey _boxKey = GlobalKey();
  late final _DocumentDragListener _listener;

  bool _isDragOver = false;

  /// `dragover` fires continuously while the pointer moves over the page but
  /// nothing fires reliably when the drag leaves it, so the highlight is held
  /// by a short timer that each `dragover` refreshes.
  Timer? _dragOverTimer;

  @override
  void initState() {
    super.initState();
    _listener = _DocumentDragListener(onOver: _handleOver, onDrop: _handleDrop)
      ..attach();
  }

  @override
  void dispose() {
    _dragOverTimer?.cancel();
    _listener.detach();
    super.dispose();
  }

  /// True when the viewport point is inside this widget's painted box.
  /// The app fills the browser window, so Flutter's global logical pixels and
  /// the event's CSS client pixels share an origin.
  bool _isInsideBox(num clientX, num clientY) {
    final renderObject = _boxKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final origin = renderObject.localToGlobal(Offset.zero);
    return (origin & renderObject.size)
        .contains(Offset(clientX.toDouble(), clientY.toDouble()));
  }

  void _handleOver(web.DragEvent event) {
    final inside = _isInsideBox(event.clientX, event.clientY);
    event.dataTransfer?.dropEffect = inside ? 'copy' : 'none';
    _dragOverTimer?.cancel();
    // Chrome repeats dragover roughly every 350ms even when the pointer is
    // still, so the window has to outlast that or the highlight flickers.
    _dragOverTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && _isDragOver) setState(() => _isDragOver = false);
    });
    if (inside != _isDragOver && mounted) {
      setState(() => _isDragOver = inside);
    }
  }

  void _handleDrop(web.DragEvent event) {
    _dragOverTimer?.cancel();
    if (mounted && _isDragOver) setState(() => _isDragOver = false);
    if (!_isInsideBox(event.clientX, event.clientY)) return;

    final files = event.dataTransfer?.files;
    if (files == null || files.length == 0) return;
    if (files.length > 1) {
      widget.onMultipleFiles?.call();
      return;
    }

    final file = files.item(0);
    if (file == null) return;

    final name = file.name.toLowerCase();
    if (!widget.allowedExtensions.any(name.endsWith)) {
      widget.onUnsupportedType?.call();
      return;
    }
    widget.onFile(file);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _boxKey,
      child: widget.builder(context, _isDragOver),
    );
  }
}

/// Document-level `dragover`/`drop` plumbing shared by the guard and the
/// region. Both always call `preventDefault()`: on `dragover` so the drop is
/// allowed at all, and on `drop` so the browser never opens the file itself.
class _DocumentDragListener {
  _DocumentDragListener({required this.onOver, required this.onDrop});

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
