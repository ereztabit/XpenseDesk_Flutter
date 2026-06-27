import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';

/// Singleton analytics service — fires GA4 funnel events via gtag.js interop.
final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => AnalyticsService());
