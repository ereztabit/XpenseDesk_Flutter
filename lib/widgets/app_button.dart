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
    this.isLoading = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Compact form for inline/secondary controls (smaller padding, font, and
  /// tap target). Default buttons stay full-size.
  final bool dense;

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
        : Text(label);

    final effectiveOnPressed = isLoading ? null : onPressed;

    if (icon != null && !isLoading) {
      return ElevatedButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: Icon(icon, size: dense ? 16 : 18),
        label: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: child,
    );
  }

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
            if (states.contains(WidgetState.hovered)) return AppTheme.primary;
            return AppTheme.muted;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return Colors.white;
            return AppTheme.foreground;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppTheme.border),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: _radius),
          ),
          padding: WidgetStateProperty.all(_effectivePadding),
          textStyle: _denseTextStyle,
          minimumSize: _denseMinSize,
          tapTargetSize: _denseTapTarget,
          elevation: WidgetStateProperty.all(0),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        );

      case AppButtonVariant.ghost:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x0D000000);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.all(AppTheme.foreground),
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
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        );
    }
  }

  /// Shared builder for colored variants (primary, destructive, success).
  ButtonStyle _coloredStyle({
    required Color bg,
    required Color bgHover,
    required Color fg,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppTheme.muted;
        if (states.contains(WidgetState.hovered)) return bgHover;
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppTheme.mutedForeground;
        }
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
      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
    );
  }
}
