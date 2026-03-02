/// Barrel file — common imports shared by every authenticated screen.
///
/// Usage:
///   import 'screen_imports.dart';
///
/// Screen-specific imports (models, services, packages) still go in each file.
library;

// Framework
export 'package:flutter/material.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';

// Localizations
export '../generated/l10n/app_localizations.dart';

// Models
export '../models/user_info.dart';

// Providers
export '../providers/auth_provider.dart';

// Theme
export '../theme/app_theme.dart';

// Shared widgets
export '../widgets/form_behavior_mixin.dart';
export '../widgets/header/app_header.dart';
export '../widgets/app_footer.dart';
export '../widgets/constrained_content.dart';
export '../widgets/error_alert.dart';
