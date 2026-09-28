/// Parses an API timestamp that the server documents as UTC.
///
/// The server serialises SQL `datetime2` values without a zone designator
/// (`2026-09-27T20:17:16.441`), and `DateTime.parse` reads a zone-less string
/// as LOCAL time — which would shift every timestamp by the browser's offset.
/// A value that already carries `Z` or an offset is parsed as given.
///
/// Returns null for null, empty or unparseable input.
DateTime? parseApiUtc(String? value) {
  if (value == null || value.isEmpty) return null;
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  return DateTime.tryParse(hasZone ? value : '${value}Z')?.toUtc();
}
