// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// Result of a Tranzila popup flow.
class TranzilaPopupResult {
  final bool success;

  /// The full Tranzila-native response shape {errors, transaction_response}.
  final Map<String, dynamic> tranzilaResponse;

  /// The card token from the transaction response.
  final String token;

  /// Error message from Tranzila (on failure).
  final String? error;

  const TranzilaPopupResult({
    required this.success,
    required this.tranzilaResponse,
    required this.token,
    this.error,
  });
}

/// Manages the Tranzila popup lifecycle: open, postMessage handshake, result.
///
/// Usage:
///   final service = TranzilaPopupService(authService: ..., userFullName: ..., userEmail: ...);
///   service.onResult = (result) { ... };
///   service.startListening();
///   await service.openPopup(lang: 'he');
///   // ... dispose when done
///   service.dispose();
class TranzilaPopupService {
  TranzilaPopupService({
    required this.authService,
    required this.userFullName,
    required this.userEmail,
    required this.userDialingCode,
  });

  final AuthService authService;
  final String userFullName;
  final String userEmail;
  final String userDialingCode;

  StreamSubscription? _messageSub;
  html.WindowBase? _popup;
  String? _pendingThtk;

  /// Called when the popup sends back a result.
  void Function(TranzilaPopupResult result)? onResult;

  /// Called when popup couldn't be opened (blocked).
  void Function()? onPopupBlocked;

  /// Called when thtk fetch fails.
  void Function(Object error)? onError;

  void startListening() {
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
        _handleResult(Map<String, dynamic>.from(data));
      }
    });
  }

  Future<void> openPopup({required String lang}) async {
    try {
      final thtk = await authService.getPaymentSetupToken();
      final page = AppConfig.instance.tranzilaUse3ds
          ? '/CreditCard/AuthorizeCard3DS.html'
          : '/CreditCard/Authorize.html';
      final ts = DateTime.now().millisecondsSinceEpoch;

      final dynamic popup = html.window.open(
        '$page?lang=$lang&v=$ts',
        'card-tokenization',
        'width=520,height=640,toolbar=no,menubar=no,location=no,status=no,resizable=no',
      );

      // ignore: unnecessary_null_comparison
      if (popup == null) {
        onPopupBlocked?.call();
        return;
      }

      _popup = popup as html.WindowBase;
      _pendingThtk = thtk;
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> _sendInitData() async {
    if (_popup == null || _pendingThtk == null) return;
    final sessionToken = await authService.getSessionToken();
    final payload = {
      'type': 'init_data',
      'thtk': _pendingThtk,
      'terminal': AppConfig.instance.tranzilaTerminal,
      'card_holder_name': userFullName,
      'card_holder_email': userEmail,
      'phone_country_code': userDialingCode,
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

  void _handleResult(Map<String, dynamic> postMessageData) {
    final tx = postMessageData['transaction_response'] as Map?;
    if (tx == null) return;
    final txMap = Map<String, dynamic>.from(tx);

    final success = txMap['success'] == true;
    final processorCode = txMap['processor_response_code'] as String?;
    final token = txMap['token'] as String? ?? '';

    final tranzilaResponse = <String, dynamic>{
      'errors': postMessageData['errors'],
      'transaction_response': txMap,
    };

    // Always audit (fire and forget)
    authService.auditPaymentResponse(
      paymentProviderToken: token,
      paymentProviderResponse: tranzilaResponse,
    );

    onResult?.call(TranzilaPopupResult(
      success: success && processorCode == '000',
      tranzilaResponse: tranzilaResponse,
      token: token,
      error: success ? null : txMap['error'] as String?,
    ));
  }

  void dispose() {
    _messageSub?.cancel();
  }
}
