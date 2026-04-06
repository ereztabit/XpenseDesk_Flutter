// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
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
  html.WindowBase? _popup;

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
      if (data is! Map) return;

      final type = data['type'] as String?;
      if (AppConfig.environment == 'dev') {
        debugPrint('[Tranzila ◀ recv] type=$type data=$data');
      }

      if (type == 'ready') {
        _sendInitData();
      } else if (type == 'tranzila_result') {
        final tx = data['transaction_response'] as Map?;
        if (tx == null) return;
        setState(() { _result = Map<String, dynamic>.from(tx); });
      }
    });
  }

  void _sendInitData() {
    if (_popup == null || _thtk == null) return;
    final userInfo = ref.read(userInfoProvider);
    final payload = {
      'type':               'init_data',
      'thtk':               _thtk,
      'terminal':           AppConfig.instance.tranzilaTerminal,
      'card_holder_name':   userInfo?.fullName    ?? '',
      'card_holder_email':  userInfo?.email       ?? '',
      'phone_country_code': userInfo?.dailingCode ?? '',
      'phone_number':       '',
    };
    if (AppConfig.environment == 'dev') {
      debugPrint('[Tranzila ▶ send] $payload');
    }
    _popup!.postMessage(payload, html.window.location.origin);
  }

  void _openPopup() {
    final lang = Localizations.localeOf(context).languageCode;
    final page = AppConfig.instance.tranzilaUse3ds
        ? '/CreditCard/AuthorizeCard3DS.html'
        : '/CreditCard/Authorize.html';

    // Open immediately (synchronous — keeps user gesture context for popup blocker).
    // Sensitive data (thtk, cardholder) is sent via postMessage once popup signals ready.
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dynamic popup = html.window.open(
      '$page?lang=$lang&v=$ts',
      'card-tokenization',
      'width=520,height=640,toolbar=no,menubar=no,location=no,status=no,resizable=no',
    );

    // ignore: unnecessary_null_comparison
    if (popup == null) {
      setState(() {
        _error = 'Your browser blocked the payment window. '
            'Please allow popups for this site and try again.';
      });
      return;
    }
    _popup = popup as html.WindowBase;
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
      action: AppButton(
        label: 'Enter Card Details',
        variant: AppButtonVariant.primary,
        icon: Icons.open_in_new,
        onPressed: _openPopup,
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
