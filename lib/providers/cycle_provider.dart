import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'company_provider.dart';

class CycleContext {
  final int daysRemaining;
  final DateTime cycleEndDate;

  const CycleContext({
    required this.daysRemaining,
    required this.cycleEndDate,
  });
}

DateTime _nextCycleDate(int cutoverDay) {
  final now = DateTime.now();
  var candidate = DateTime(now.year, now.month, cutoverDay);
  if (!candidate.isAfter(now)) {
    // Roll to next month — DateTime handles month=13 overflow correctly.
    candidate = DateTime(now.year, now.month + 1, cutoverDay);
  }
  return candidate;
}

final cycleContextProvider = Provider<CycleContext?>((ref) {
  final companyAsync = ref.watch(companyProvider);
  return companyAsync.whenOrNull(data: (company) {
    final cycleEnd = _nextCycleDate(company.cutoverDay);
    final ms = cycleEnd.difference(DateTime.now()).inMilliseconds;
    final days = (ms / 86400000).ceil().clamp(0, 9999);
    return CycleContext(daysRemaining: days, cycleEndDate: cycleEnd);
  });
});
