import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/onboarding/company_submit_request.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../services/onboarding_service.dart';
import '../../../theme/app_theme.dart';

const int _kMaxFailures = 5;
const int _kResendCooldownSeconds = 30;
const int _kTimerDurationSeconds = 600; // 10 minutes

/// Step 3 — OTP Verification.
///
/// Renders 6 digit input boxes. Auto-advances focus and auto-submits on the
/// 6th digit. Supports paste, countdown timer, resend with cooldown, shake
/// animation on wrong OTP, lockout after 5 failures, and expiry handling.
///
/// On success: stores the session token, loads user info via GET /api/users/me,
/// and navigates to /dashboard.
class OtpVerificationStep extends ConsumerStatefulWidget {
  const OtpVerificationStep({super.key, required this.onBack});

  /// Called when the user taps "Wrong email address?" to go back to Step 2.
  final VoidCallback onBack;

  @override
  ConsumerState<OtpVerificationStep> createState() =>
      _OtpVerificationStepState();
}

class _OtpVerificationStepState extends ConsumerState<OtpVerificationStep>
    with SingleTickerProviderStateMixin {
  // ── OTP input ─────────────────────────────────────────────────────────────
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  Timer? _resendTimer;
  int _remainingSeconds = _kTimerDurationSeconds;
  int _resendCooldown = 0;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  bool _isExpired = false;
  bool _isResending = false;
  int _failureCount = 0;
  String? _errorMessage;

  // ── Shake animation ───────────────────────────────────────────────────────
  late AnimationController _shakeController;
  late Animation<double> _shakeOffset;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeOffset =
        Tween<double>(begin: 0, end: 1).animate(_shakeController);
    _startCountdown();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _resendTimer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Timer helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = _kTimerDurationSeconds;
      _isExpired = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = _kResendCooldownSeconds);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _timerText {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Digit input logic
  // ─────────────────────────────────────────────────────────────────────────

  String get _otpValue => _controllers.map((c) => c.text).join();

  bool get _isLocked => _failureCount >= _kMaxFailures;

  void _handleDigitChanged(int index, String value) {
    if (value.isEmpty) {
      // Cleared — handled by the Focus.onKeyEvent backspace handler
      return;
    }

    if (value.length > 1) {
      // Paste scenario — distribute digits
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < 6; i++) {
        if (i < digits.length) {
          _controllers[i].value = TextEditingValue(
            text: digits[i],
            selection: const TextSelection.collapsed(offset: 1),
          );
        } else {
          _controllers[i].clear();
        }
      }
      if (digits.length >= 6) {
        _focusNodes[5].unfocus();
        _submit();
      } else {
        _focusNodes[min(5, digits.length)].requestFocus();
      }
      return;
    }

    // Single digit — advance focus
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[5].unfocus();
      _submit();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isSubmitting || _isLocked || _isExpired) return;
    final otp = _otpValue;
    if (otp.length < 6) return;

    final wizardState = ref.read(onboardingStateProvider);
    final otpKey = wizardState.otpKey;
    if (otpKey.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(onboardingServiceProvider);
      final sessionToken =
          await service.verifyOtp(otpKey: otpKey, otp: otp);

      final authService = ref.read(authServiceProvider);
      await authService.storeSessionToken(sessionToken);

      final userInfo = await authService.getUserInfo();
      ref.read(userInfoProvider.notifier).setUserInfo(userInfo);

      ref.read(onboardingStateProvider.notifier).reset();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on OnboardingException catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _failureCount++;
      });

      // Treat all 400s as a wrong attempt — the server intentionally returns
      // one generic message for wrong OTP / expired / key-not-found.
      // Expiry detection will be added later when the server sends distinct
      // error codes.
      if (!_isLocked) {
        final l10n = AppLocalizations.of(context)!;
        // Always use our own localized message — never proxy the API response.
        setState(() => _errorMessage = l10n.onboardingOtpInvalid);
        _shakeAndClear();
      } else {
        _shakeAndClear();
      }
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isSubmitting = false;
        _errorMessage = l10n.anErrorOccurred;
      });
    }
  }

  Future<void> _shakeAndClear() async {
    await _shakeController.forward(from: 0);
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) {
      _focusNodes[0].requestFocus();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resend
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;

    final wizardState = ref.read(onboardingStateProvider);
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(onboardingServiceProvider);
      final request = CompanySubmitRequest(
        companyName: wizardState.companyName,
        countryCode: wizardState.countryCode,
        cutoverDay: wizardState.cutoverDay!,
        email: wizardState.email,
        fullName: wizardState.fullName,
        accountantEmail: wizardState.accountantEmail.isNotEmpty
            ? wizardState.accountantEmail
            : null,
      );
      final newOtpKey = await service.submitCompany(request);

      ref.read(onboardingStateProvider.notifier).setOtpKey(newOtpKey);

      for (final c in _controllers) {
        c.clear();
      }
      setState(() => _failureCount = 0);

      _startCountdown();
      _startResendCooldown();

      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    } on OnboardingException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _errorMessage = l10n.anErrorOccurred);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startOver() {
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final email = ref.read(onboardingStateProvider).email;

    if (_isLocked) return _buildLockout(l10n);
    if (_isExpired) return _buildExpired(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Email sent-to + back link ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                l10n.onboardingOtpSentTo(email),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: widget.onBack,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.onboardingOtpWrongEmail,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primaryDark,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primaryDark,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Six OTP digit boxes with shake animation
        _buildOtpBoxes(),

        const SizedBox(height: 16),

        // Inline error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.destructive,
                fontSize: 13,
              ),
            ),
          ),

        // Countdown timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(width: 4),
            Text(
              _timerText,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Resend button / spinner
        Center(
          child: _isResending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _resendCooldown == 0 ? _resend : null,
                  child: Text(
                    _resendCooldown > 0
                        ? l10n.onboardingOtpResendIn(_resendCooldown)
                        : l10n.onboardingOtpResend,
                    style: TextStyle(
                      color: _resendCooldown > 0
                          ? AppTheme.mutedForeground
                          : AppTheme.primaryDark,
                      fontSize: 14,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 24),

        // Verify button
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: (_isSubmitting || _otpValue.length < 6) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: AppTheme.primaryForeground,
              disabledBackgroundColor: AppTheme.muted,
              disabledForegroundColor: AppTheme.mutedForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryForeground,
                    ),
                  )
                : Text(l10n.onboardingOtpVerify),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBoxes() {
    return AnimatedBuilder(
      animation: _shakeOffset,
      builder: (context, child) {
        final offset = sin(_shakeOffset.value * pi * 8) * 8.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, _buildDigitBox),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 40,
      height: 44,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          maxLength: null,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppTheme.card,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppTheme.primaryDark, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
          onChanged: (value) => _handleDigitChanged(index, value),
        ),
      ),
    );
  }

  Widget _buildLockout(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.destructive.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppTheme.destructive,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingOtpLockout,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.destructive,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpired(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.muted,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.timer_off_outlined,
                color: AppTheme.mutedForeground,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingOtpExpired,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: _startOver,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: AppTheme.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
            child: Text(l10n.onboardingOtpStartOver),
          ),
        ),
      ],
    );
  }
}
