import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App version formatted as `v{major}.{minor}` (e.g. `v1.0`).
///
/// The single source of truth is `pubspec.yaml`'s `version:`, baked into the
/// build at compile time. The minor component is auto-incremented on every
/// commit by the `.githooks/pre-commit` hook, so this label is how we confirm a
/// deployment has reached production.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final parts = info.version.split('.');
  final major = parts.isNotEmpty ? parts[0] : '0';
  final minor = parts.length > 1 ? parts[1] : '0';
  return 'v$major.$minor';
});
