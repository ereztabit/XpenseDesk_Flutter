import 'package:flutter/material.dart';

/// Text that is always laid out left-to-right - emails today, phone numbers and
/// URLs if they need it - while its alignment still follows the page.
///
/// In RTL a plain [Text] runs the bidi algorithm over the whole string, so
/// leading/trailing punctuation jumps ends: `info@x.com_` renders as
/// `_info@x.com`. Forcing [TextDirection.ltr] fixes the order, but on its own
/// would also turn `TextAlign.start` into "left" on a Hebrew page; [textAlign]
/// is therefore resolved against the surrounding [Directionality] first.
class LtrText extends StatelessWidget {
  const LtrText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.selectable = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Renders a [SelectableText] (no [overflow] support there).
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final align = _resolve(textAlign, Directionality.of(context));
    if (selectable) {
      return SelectableText(
        text,
        style: style,
        textAlign: align,
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
      );
    }
    return Text(
      text,
      style: style,
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  // Physical left/right on purpose: start/end would be read against the
  // forced LTR direction, not the page's.
  static TextAlign _resolve(TextAlign? align, TextDirection page) {
    final rtl = page == TextDirection.rtl;
    return switch (align ?? TextAlign.start) {
      TextAlign.start => rtl ? TextAlign.right : TextAlign.left,
      TextAlign.end => rtl ? TextAlign.left : TextAlign.right,
      final other => other,
    };
  }
}
