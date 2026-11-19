import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, destructive, success, normal, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.dense = false,
    this.fitLabel = false,
  }) : assert(icon == null || iconWidget == null,
            'Provide icon OR iconWidget, not both');

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Custom leading widget (e.g. the multicolor [MicrosoftLogo]); not with [icon].
  final Widget? iconWidget;
  final bool isLoading;

  /// Compact: smaller padding, font and tap target. Default buttons stay full-size.
  final bool dense;

  /// Fixed-width spot: the label shrinks onto one line, the button keeps its size.
  final bool fitLabel;

  static const _radius = BorderRadius.all(Radius.circular(12));
  static const _padding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
  static const _densePadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 9);

  EdgeInsets get _effectivePadding => dense ? _densePadding : _padding;
  WidgetStateProperty<TextStyle?>? get _denseTextStyle => dense
      ? WidgetStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
      : null;
  WidgetStateProperty<Size?>? get _denseMinSize =>
      dense ? WidgetStateProperty.all(Size.zero) : null;
  MaterialTapTargetSize? get _denseTapTarget =>
      dense ? MaterialTapTargetSize.shrinkWrap : null;

  /// A disabled button says so under the mouse too.
  static final _cursor = WidgetStateProperty.resolveWith<MouseCursor>(
      (states) => states.contains(WidgetState.disabled)
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click);

  @override
  Widget build(BuildContext context) {
    final style = _buildStyle();
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : _label();

    // Loading keeps the enabled look (no-op tap): only a disabled button fades.
    final effectiveOnPressed = isLoading ? () {} : onPressed;

    if ((icon != null || iconWidget != null) && !isLoading) {
      return ElevatedButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: iconWidget ?? Icon(icon, size: dense ? 16 : 18),
        label: _label(),
      );
    }

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: child,
    );
  }

  Widget _label() => fitLabel
      ? FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, softWrap: false))
      : Text(label);

  ButtonStyle _buildStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return _coloredStyle(
          bg: AppTheme.primary,
          bgHover: AppTheme.primary.withAlpha(204),
          fg: Colors.white,
        );

      case AppButtonVariant.destructive:
        return _coloredStyle(
          bg: AppTheme.destructive,
          bgHover: AppTheme.destructive.withAlpha(179),
          fg: Colors.white,
        );

      case AppButtonVariant.success:
        return _coloredStyle(
          bg: AppTheme.success,
          bgHover: AppTheme.success.withAlpha(204),
          fg: Colors.white,
        );

      case AppButtonVariant.normal:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppTheme.muted.withAlpha(110);
            if (states.contains(WidgetState.hovered)) return AppTheme.primary;
            return AppTheme.muted;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppTheme.mutedForeground.withAlpha(140);
            if (states.contains(WidgetState.hovered)) return Colors.white;
            return AppTheme.foreground;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.resolveWith((states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? AppTheme.border.withAlpha(110)
                    : AppTheme.border,
              )),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: _radius),
          ),
          padding: WidgetStateProperty.all(_effectivePadding),
          textStyle: _denseTextStyle,
          minimumSize: _denseMinSize,
          tapTargetSize: _denseTapTarget,
          elevation: WidgetStateProperty.all(0),
          mouseCursor: _cursor,
        );

      case AppButtonVariant.ghost:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x0D000000);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? AppTheme.mutedForeground.withAlpha(140)
                  : AppTheme.foreground),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: _radius),
          ),
          padding: WidgetStateProperty.all(_effectivePadding),
          textStyle: _denseTextStyle,
          minimumSize: _denseMinSize,
          tapTargetSize: _denseTapTarget,
          elevation: WidgetStateProperty.all(0),
          mouseCursor: _cursor,
        );
    }
  }

  /// Shared builder for colored variants (primary, destructive, success).
  ButtonStyle _coloredStyle({required Color bg, required Color bgHover, required Color fg}) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        // Disabled = its own color, faded - never the gray of the normal
        // variant, which reads as an enabled button (owner QA, 2026-11-19).
        if (states.contains(WidgetState.disabled)) return bg.withAlpha(90);
        if (states.contains(WidgetState.hovered)) return bgHover;
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return fg.withAlpha(220);
        return fg;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      side: WidgetStateProperty.all(BorderSide.none),
      shape: WidgetStateProperty.all(
        const RoundedRectangleBorder(borderRadius: _radius),
      ),
      padding: WidgetStateProperty.all(_effectivePadding),
      textStyle: _denseTextStyle,
      minimumSize: _denseMinSize,
      tapTargetSize: _denseTapTarget,
      elevation: WidgetStateProperty.all(0),
      mouseCursor: _cursor,
    );
  }
}
