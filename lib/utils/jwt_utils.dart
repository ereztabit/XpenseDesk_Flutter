import 'dart:convert';

/// Decodes the payload (claims) of a JWT WITHOUT verifying its signature.
///
/// Display-only use: prefilling the onboarding identity card from a Microsoft
/// ID token's `name` / `preferred_username` claims. The server independently
/// validates the same token — never trust these values for authorization.
/// Returns an empty map when the token is malformed.
Map<String, dynamic> decodeJwtClaims(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) return const {};
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload);
    return claims is Map<String, dynamic> ? claims : const {};
  } catch (_) {
    return const {};
  }
}

/// The display name claim from a Microsoft ID token ('' when absent).
String jwtDisplayName(Map<String, dynamic> claims) =>
    claims['name'] as String? ?? '';

/// The email claim from a Microsoft ID token: `email` when present, falling
/// back to `preferred_username` (the UPN, an email for M365 users).
String jwtEmail(Map<String, dynamic> claims) =>
    claims['email'] as String? ??
    claims['preferred_username'] as String? ??
    '';
