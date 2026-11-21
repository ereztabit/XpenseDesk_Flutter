import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// Max lengths - the server's limits (docs/api-guides/receipt-ai-api-guide.md).
const int kAiGptPromptMaxLength = 30000;
const int kAiFieldInstructionMaxLength = 4000;

/// A monospace, multi-line prompt editor with a label and a character count.
/// Prompts are code-like text, so it is always left-to-right.
///
/// Owns its controller. [initialText] is the current value; when it differs
/// from what is typed (another version loaded, or Revert) the text follows it.
class AiPromptEditor extends StatefulWidget {
  const AiPromptEditor({
    super.key,
    this.label,
    required this.initialText,
    required this.onChanged,
    required this.maxLength,
    this.minLines = 4,
    this.maxLines = 22,
    this.readOnly = false,
  });

  final String? label;
  final String initialText;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final int minLines;
  final int maxLines;

  /// An archived profile: the text can be selected and copied, not edited;
  /// filled muted like a locked input.
  final bool readOnly;

  @override
  State<AiPromptEditor> createState() => _AiPromptEditorState();
}

class _AiPromptEditorState extends State<AiPromptEditor> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);

  @override
  void didUpdateWidget(AiPromptEditor old) {
    super.didUpdateWidget(old);
    if (widget.initialText != _controller.text) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
        ],
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _controller,
            readOnly: widget.readOnly,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: (v) {
              widget.onChanged(v);
              setState(() {});
            },
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
            decoration: InputDecoration(
              filled: widget.readOnly,
              fillColor: AppTheme.muted,
              counterText: '${_controller.text.length} / ${widget.maxLength} ${l10n.adminAiCharacters}',
              counterStyle: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
            ),
          ),
        ),
      ],
    );
  }
}
