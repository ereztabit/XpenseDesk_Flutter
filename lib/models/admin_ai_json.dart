/// FS-1026 Receipt AI - JSON helpers shared by the admin AI models.
library;

final RegExp _hasOffset = RegExp(r'(Z|[+-]\d\d:?\d\d)$');

/// A server timestamp. The API sends UTC; a value with no offset is still read
/// as UTC (defensive), so admin times convert to Israel time correctly either way.
DateTime? adminAiUtc(Object? v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(_hasOffset.hasMatch(v) ? v : '${v}Z');
}

/// A calendar date (an expense date) - a day, never time-zone shifted.
DateTime? adminAiDayValue(Object? v) => v is String ? DateTime.tryParse(v) : null;

int? adminAiInt(Object? v) => v is num ? v.toInt() : null;
