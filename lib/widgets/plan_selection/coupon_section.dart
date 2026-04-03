import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../app_button.dart';

/// Coupon input with API validation, lock-after-apply, and cancel.
///
/// Starts collapsed — shows "Have a coupon?" clickable label.
/// Clicking reveals the input row. API validates via
/// `GET /api/onboarding/coupon/validate?code=XXX`.
/// Once applied, the input is locked — user must cancel to change.
class CouponSection extends ConsumerStatefulWidget {
  const CouponSection({
    super.key,
    required this.onCouponResult,
  });

  /// Called with the validated coupon code (null if cleared/invalid).
  final void Function(String? validCode) onCouponResult;

  @override
  ConsumerState<CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends ConsumerState<CouponSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;
  bool _isApplying = false;
  bool _hasText = false;
  int _failCount = 0;
  bool _blocked = false;

  /// null = no feedback, true = valid (locked), false = invalid
  bool? _isValid;

  /// Free months from API response.
  int _freeMonths = 0;

  @override
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    // Typing clears invalid feedback
    if (_isValid == false) {
      setState(() => _isValid = null);
    }
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplying = true);
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.validateCoupon(code);
      if (!mounted) return;
      if (result.isValid) {
        setState(() {
          _isValid = true;
          _freeMonths = result.freeMonths;
          _isApplying = false;
        });
        widget.onCouponResult(code);
      } else {
        _handleFailure();
      }
    } on Exception catch (_) {
      if (!mounted) return;
      _handleFailure();
    }
  }

  void _handleFailure() {
    _failCount++;
    if (_failCount >= 3) {
      // Block entirely — user is guessing coupons
      setState(() {
        _blocked = true;
        _isExpanded = false;
        _isApplying = false;
        _isValid = null;
      });
      _controller.clear();
      widget.onCouponResult(null);
      return;
    }
    setState(() {
      _isValid = false;
      _isApplying = false;
    });
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _focusNode.requestFocus();
    widget.onCouponResult(null);
  }

  void _cancelCoupon() {
    _controller.clear();
    setState(() {
      _isValid = null;
      _freeMonths = 0;
      _hasText = false;
    });
    widget.onCouponResult(null);
  }

  String _buildSuccessMessage(AppLocalizations l10n) {
    if (_freeMonths == 1) {
      return '${l10n.couponAccepted} ${l10n.couponOneMonthFree}';
    }
    if (_freeMonths > 1) {
      return '${l10n.couponAccepted} $_freeMonths ${l10n.couponMonthsFree}';
    }
    return l10n.couponAccepted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLocked = _isValid == true;

    // Blocked — hide everything
    if (_blocked) return const SizedBox.shrink();

    // Collapsed — just the clickable label
    if (!_isExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            l10n.haveCoupon,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }

    // Expanded — input + apply/remove + feedback
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          l10n.haveCoupon,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),

        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: 10,
                enabled: !isLocked,
                autofocus: true,
                onChanged: _onChanged,
                onSubmitted: (_) => _hasText ? _apply() : null,
                decoration: InputDecoration(
                  hintText: l10n.enterCouponCode,
                  counterText: '',
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppTheme.success.withAlpha(128)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isLocked)
              AppButton(
                label: l10n.removeCoupon,
                variant: AppButtonVariant.destructive,
                onPressed: _cancelCoupon,
              )
            else
              AppButton(
                label: l10n.applyCoupon,
                variant: AppButtonVariant.normal,
                isLoading: _isApplying,
                onPressed: _hasText ? _apply : null,
              ),
          ],
        ),

        // Feedback
        if (_isValid != null) ...[
          const SizedBox(height: 8),
          _isValid!
              ? Text(
                  _buildSuccessMessage(l10n),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.success,
                  ),
                )
              : Text(
                  l10n.invalidCoupon,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.destructive,
                  ),
                ),
        ],
      ],
    );
  }
}
