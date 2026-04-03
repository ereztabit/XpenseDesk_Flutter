// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import '../../models/company_billing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../app_button.dart';

/// Payment Method card for the Billing tab.
/// Displays saved card details, warning banners, and handles the Tranzila
/// popup flow for updating/adding a card (no intermediate dialog).
class BillingPaymentMethodCard extends ConsumerStatefulWidget {
  const BillingPaymentMethodCard({
    super.key,
    required this.paymentMethod,
  });

  final BillingPaymentMethod? paymentMethod;

  @override
  ConsumerState<BillingPaymentMethodCard> createState() =>
      _BillingPaymentMethodCardState();
}

class _BillingPaymentMethodCardState
    extends ConsumerState<BillingPaymentMethodCard> {
  StreamSubscription? _messageSub;
  html.WindowBase? _popup;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _listenForResult();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _listenForResult() {
    _messageSub = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! Map) return;

      final type = data['type'] as String?;
      if (AppConfig.environment == 'dev') {
        debugPrint('[Tranzila ◀ recv] type=$type data=$data');
      }

      if (type == 'ready') {
        _sendInitDataWithThtk();
      } else if (type == 'tranzila_result') {
        _handleResult(Map<String, dynamic>.from(data));
      }
    });
  }

  Future<void> _openPopup() async {
    if (_busy) return;
    setState(() => _busy = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      // Fetch fresh thtk
      final thtk =
          await ref.read(authServiceProvider).getPaymentSetupToken();

      final lang = Localizations.localeOf(context).languageCode;
      final page = AppConfig.instance.tranzilaUse3ds
          ? '/CreditCard/AuthorizeCard3DS.html'
          : '/CreditCard/Authorize.html';

      final dynamic popup = html.window.open(
        '$page?lang=$lang',
        'card-tokenization',
        'width=520,height=640,toolbar=no,menubar=no,location=no,status=no,resizable=no',
      );

      // ignore: unnecessary_null_comparison
      if (popup == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.billingPopupBlocked),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _busy = false);
        return;
      }

      _popup = popup as html.WindowBase;

      // Store thtk + user info to send when popup signals ready
      _pendingThtk = thtk;
      setState(() => _busy = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingCardSaveFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _busy = false);
      }
    }
  }

  String? _pendingThtk;

  Future<void> _sendInitDataWithThtk() async {
    if (_popup == null || _pendingThtk == null) return;
    final userInfo = ref.read(userInfoProvider);
    final sessionToken = await ref.read(authServiceProvider).getSessionToken();
    final payload = {
      'type': 'init_data',
      'thtk': _pendingThtk,
      'terminal': AppConfig.instance.tranzilaTerminal,
      'card_holder_name': userInfo?.fullName ?? '',
      'card_holder_email': userInfo?.email ?? '',
      'phone_country_code': userInfo?.dailingCode ?? '',
      'phone_number': '',
      'session_token': sessionToken,
      'api_base_url': AppConfig.instance.apiBaseUrl,
    };
    if (AppConfig.environment == 'dev') {
      debugPrint('[Tranzila ▶ send] $payload');
    }
    _popup!.postMessage(payload, html.window.location.origin);
    _pendingThtk = null;
  }

  Future<void> _handleResult(Map<String, dynamic> postMessageData) async {
    final tx = postMessageData['transaction_response'] as Map?;
    if (tx == null) return;
    final txMap = Map<String, dynamic>.from(tx);

    final success = txMap['success'] == true;
    final processorCode = txMap['processor_response_code'] as String?;
    final token = txMap['token'] as String? ?? '';

    // Reconstruct the Tranzila-native response shape expected by the API
    final tranzilaResponse = <String, dynamic>{
      'errors': postMessageData['errors'],
      'transaction_response': txMap,
    };

    final l10n = AppLocalizations.of(context)!;
    final authService = ref.read(authServiceProvider);

    // Always audit (fire and forget)
    authService.auditPaymentResponse(
      paymentProviderToken: token,
      paymentProviderResponse: tranzilaResponse,
    );

    if (!success || processorCode != '000') {
      final errorMsg = txMap['error'] as String? ?? l10n.billingCardSaveFailed;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Save payment method + refresh billing
    try {
      await authService.savePaymentMethod(
        paymentProviderResponse: tranzilaResponse,
      );
      await ref.read(billingProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingCardSavedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingCardSaveFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pm = widget.paymentMethod;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.billingPaymentMethod,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (pm == null)
              _NoPaymentMethodBanner(
                  l10n: l10n, onUpdate: _openPopup, busy: _busy)
            else ...[
              _CardInfoBlock(paymentMethod: pm, l10n: l10n),
              const SizedBox(height: 12),
              if (pm.isDeclined)
                _DeclinedBanner(
                    l10n: l10n, onUpdate: _openPopup, busy: _busy)
              else if (pm.isExpired)
                _ExpiredBanner(
                    l10n: l10n, onUpdate: _openPopup, busy: _busy)
              else if (pm.isExpiringSoon)
                _ExpiringSoonBanner(
                  monthsLeft: pm.monthsUntilExpiry,
                  l10n: l10n,
                  onUpdate: _openPopup,
                  busy: _busy,
                )
              else
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppButton(
                    label: l10n.billingUpdateCard,
                    variant: AppButtonVariant.normal,
                    isLoading: _busy,
                    onPressed: _openPopup,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Card info block (brand + last 4 + expiry) ─────────────────────────────

class _CardInfoBlock extends StatelessWidget {
  const _CardInfoBlock({
    required this.paymentMethod,
    required this.l10n,
  });

  final BillingPaymentMethod paymentMethod;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.muted.withAlpha(77),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 32,
            color: AppTheme.mutedForeground,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${paymentMethod.brand} •••• ${paymentMethod.lastFourDigits}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.billingCardExpires} ${paymentMethod.expiryDisplay}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Declined banner (red) ──────────────────────────────────────────────────

class _DeclinedBanner extends StatelessWidget {
  const _DeclinedBanner({
    required this.l10n,
    required this.onUpdate,
    required this.busy,
  });

  final AppLocalizations l10n;
  final VoidCallback onUpdate;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppTheme.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.billingCardDeclined,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.destructive,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.billingUpdateCard,
            variant: AppButtonVariant.destructive,
            isLoading: busy,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}

// ─── Expired banner (red) ───────────────────────────────────────────────────

class _ExpiredBanner extends StatelessWidget {
  const _ExpiredBanner({
    required this.l10n,
    required this.onUpdate,
    required this.busy,
  });

  final AppLocalizations l10n;
  final VoidCallback onUpdate;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_off_outlined,
              size: 18, color: AppTheme.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.billingCardExpired,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.destructive,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.billingUpdateCard,
            variant: AppButtonVariant.destructive,
            isLoading: busy,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}

// ─── Expiring soon banner (amber) ───────────────────────────────────────────

class _ExpiringSoonBanner extends StatelessWidget {
  const _ExpiringSoonBanner({
    required this.monthsLeft,
    required this.l10n,
    required this.onUpdate,
    required this.busy,
  });

  static const _bgColor = Color(0xFFFFF7ED);
  static const _borderColor = Color(0xFFFED7AA);
  static const _textColor = Color(0xFFEA580C);

  final int monthsLeft;
  final AppLocalizations l10n;
  final VoidCallback onUpdate;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_outlined, size: 18, color: _textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l10n.billingCardExpiringSoon} $monthsLeft ${l10n.billingCardExpiringSoonMonths}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.billingUpdateCard,
            variant: AppButtonVariant.normal,
            isLoading: busy,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}

// ─── No payment method banner (red) ─────────────────────────────────────────

class _NoPaymentMethodBanner extends StatelessWidget {
  const _NoPaymentMethodBanner({
    required this.l10n,
    required this.onUpdate,
    required this.busy,
  });

  final AppLocalizations l10n;
  final VoidCallback onUpdate;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_off_outlined,
              size: 18, color: AppTheme.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.billingNoPaymentMethod,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.destructive,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.billingAddCard,
            variant: AppButtonVariant.destructive,
            isLoading: busy,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}
