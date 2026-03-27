// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/header/app_header.dart';
import '../widgets/app_footer.dart';
import '../utils/responsive_utils.dart';

class TranzilaPocScreen extends ConsumerStatefulWidget {
  const TranzilaPocScreen({super.key});

  @override
  ConsumerState<TranzilaPocScreen> createState() => _TranzilaPocScreenState();
}

class _TranzilaPocScreenState extends ConsumerState<TranzilaPocScreen> {
  bool _loading = true;
  String? _error;
  String? _thtk;
  Map<String, dynamic>? _result;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _fetchThtk();
    _listenForResult();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchThtk() async {
    try {
      final token = await ref.read(authServiceProvider).getSessionToken();
      final response = await ApiService().get(
        '/api/company/payment-setup',
        authToken: token,
      );
      setState(() {
        _thtk = response['data']['thtk'] as String;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _listenForResult() {
    _messageSub = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is Map && data['type'] == 'tranzila_result') {
        final tx = data['transaction_response'] as Map?;
        if (tx == null) return;
        setState(() { _result = Map<String, dynamic>.from(tx); });
      }
    });
  }

  // ISO 3166-1 alpha-2 → dial code (digits only, no +)
  static const _dialCodes = {
    'IL': '972', 'US': '1',   'GB': '44',  'DE': '49',  'FR': '33',
    'AU': '61',  'CA': '1',   'IN': '91',  'JP': '81',  'CN': '86',
    'AE': '971', 'SA': '966', 'TR': '90',  'IT': '39',  'ES': '34',
    'NL': '31',  'BE': '32',  'CH': '41',  'PL': '48',  'SE': '46',
    'NO': '47',  'DK': '45',  'FI': '358', 'PT': '351', 'AT': '43',
    'ZA': '27',  'EG': '20',  'NG': '234', 'BR': '55',  'MX': '52',
    'RU': '7',   'UA': '380',
  };

  void _openPopup() {
    final lang        = Localizations.localeOf(context).languageCode;
    final terminal    = Uri.encodeComponent(AppConfig.instance.tranzilaTerminal);
    final page        = AppConfig.instance.tranzilaUse3ds
        ? '/CreditCard/AuthorizeCard3DS.html'
        : '/CreditCard/Authorize.html';

    final userInfo    = ref.read(userInfoProvider);
    final companyInfo = ref.read(companyProvider).value;

    final name      = Uri.encodeComponent(userInfo?.fullName ?? '');
    final email     = Uri.encodeComponent(userInfo?.email   ?? '');
    final dialCode  = _dialCodes[companyInfo?.countryCode.toUpperCase() ?? ''] ?? '';

    final url = '$page'
        '?thtk=$_thtk'
        '&terminal=$terminal'
        '&lang=$lang'
        '&card_holder_name=$name'
        '&card_holder_email=$email'
        '&phone_country_code=$dialCode'
        '&phone_number='
        '&force_txn_on_3ds_fail=N';

    // dart:html types window.open() as non-nullable but it returns null at
    // runtime when the browser blocks the popup.
    final dynamic popup = html.window.open(
      url,
      'card-tokenization',
      'width=520,height=640,toolbar=no,menubar=no,location=no,status=no,resizable=no',
    );

    // ignore: unnecessary_null_comparison
    if (popup == null) {
      setState(() {
        _error = 'Your browser blocked the payment window. '
            'Please allow popups for this site and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.isMobile ? 16 : 24,
                    ),
                    child: _buildBody(context),
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _InfoCard(
        icon: Icons.error_outline,
        iconColor: AppTheme.destructive,
        title: 'Could not load payment form',
        subtitle: _error!,
      );
    }

    if (_result != null) {
      return _ResultCard(result: _result!);
    }

    return _InfoCard(
      icon: Icons.credit_card,
      iconColor: AppTheme.primary,
      title: 'Add Payment Card',
      subtitle: 'Your card details are entered in a secure window hosted by our payment provider.',
      action: ElevatedButton.icon(
        onPressed: _openPopup,
        icon: const Icon(Icons.open_in_new, size: 18),
        label: const Text('Enter Card Details'),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? action;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      color: AppTheme.card,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(subtitle,
              style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.success.withAlpha(102)),
      ),
      color: AppTheme.card,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text('Card saved successfully',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _row('Type',   result['card_type_name'] ?? result['card_type'] ?? ''),
            _row('Card',   result['card_mask']  ?? ''),
            _row('Expiry', '${result['expiry_month'] ?? ''}/${result['expiry_year'] ?? ''}'),
            _row('Token',  result['token']      ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
              style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
            ),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
