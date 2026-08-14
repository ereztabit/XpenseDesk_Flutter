import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/app_navigator.dart';
import 'admin_module_box.dart';

/// One entry in the admin landing grid. Adding a module means adding an
/// [_AdminModule] to [_modules] — never a layout change.
class _AdminModule {
  const _AdminModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) description;
  final IconData icon;
  final String route;
}

const List<_AdminModule> _modules = [
  _AdminModule(
    title: _companiesTitle,
    description: _companiesDescription,
    icon: Icons.apartment_outlined,
    route: AppRoutes.adminCompanies,
  ),
];

String _companiesTitle(AppLocalizations l10n) => l10n.adminModuleCompanies;
String _companiesDescription(AppLocalizations l10n) =>
    l10n.adminModuleCompaniesDescription;

/// The admin landing grid — the extension point for future admin modules.
/// Tiles have a fixed width and reflow, so the layout holds from one module to
/// many at any viewport.
class AdminModuleGrid extends StatelessWidget {
  const AdminModuleGrid({super.key});

  static const double _tileWidth = 320;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On narrow viewports a fixed 320px tile would overflow — let tiles
        // take the full available width instead.
        final width = constraints.maxWidth < _tileWidth
            ? constraints.maxWidth
            : _tileWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final module in _modules)
              SizedBox(
                width: width,
                child: AdminModuleBox(
                  title: module.title(l10n),
                  description: module.description(l10n),
                  icon: module.icon,
                  onTap: () => Navigator.pushNamed(context, module.route),
                ),
              ),
          ],
        );
      },
    );
  }
}
