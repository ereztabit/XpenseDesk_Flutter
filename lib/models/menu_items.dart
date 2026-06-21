import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/l10n/app_localizations.dart';
import '../utils/pwa_utils.dart';
import 'user_info.dart';

/// Context buckets for the navigation menu. Items are ordered by group and the
/// renderers draw a divider whenever the group changes (no text headers).
/// `logout` is its own group so it always gets a dedicated divider.
enum MenuGroup { work, reports, settings, support, logout }

class MenuItem {
  final String id;
  final IconData icon;
  final String label;
  final MenuGroup group;
  final bool requiresManagerRole;
  final bool isDestructive;
  final bool isAction;
  final bool desktopOnly;

  const MenuItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.group,
    this.requiresManagerRole = false,
    this.isDestructive = false,
    this.isAction = false,
    this.desktopOnly = false,
  });
}

class MenuItems {
  static List<MenuItem> getItems(AppLocalizations t, bool isManager) {
    // Ordered by group; renderers insert a divider on each group change.
    final allItems = [
      // Work
      MenuItem(
        id: 'dashboard',
        icon: Icons.dashboard_outlined,
        label: t.dashboard,
        group: MenuGroup.work,
        requiresManagerRole: true,
      ),
      MenuItem(
        id: 'sheet-approvals',
        icon: Icons.fact_check_outlined,
        label: t.sheetApprovals,
        group: MenuGroup.work,
        requiresManagerRole: true,
      ),
      MenuItem(
        id: 'payments',
        icon: Icons.payments_outlined,
        label: t.paymentsTitle,
        group: MenuGroup.work,
        requiresManagerRole: true,
      ),
      // Reports
      MenuItem(
        id: 'expenses-analysis',
        icon: Icons.bar_chart,
        label: t.expensesAnalysis,
        group: MenuGroup.reports,
        requiresManagerRole: true,
      ),
      MenuItem(
        id: 'expenses-detail-report',
        icon: Icons.description_outlined,
        label: t.expensesDetailReport,
        group: MenuGroup.reports,
      ),
      // Settings — personal profile sits above company/admin settings
      MenuItem(
        id: 'profile',
        icon: Icons.person_outline,
        label: t.myProfile,
        group: MenuGroup.settings,
      ),
      MenuItem(
        id: 'company-config',
        icon: Icons.settings_outlined,
        label: t.companyConfiguration,
        group: MenuGroup.settings,
        requiresManagerRole: true,
      ),
      MenuItem(
        id: 'user-management',
        icon: Icons.people_outline,
        label: t.userManagement,
        group: MenuGroup.settings,
        requiresManagerRole: true,
      ),
      // Support & legal
      // iOS-only: install hint (iOS has no native install prompt). Hidden once
      // the app is already running as an installed PWA.
      if (PwaUtils.shouldShowIosHint)
        MenuItem(
          id: 'install-app',
          icon: Icons.ios_share,
          label: t.iosInstallMenuLabel,
          group: MenuGroup.support,
          isAction: true,
        ),
      MenuItem(
        id: 'contact-support',
        icon: Icons.email_outlined,
        label: t.contactSupport,
        group: MenuGroup.support,
        isAction: true,
      ),
      MenuItem(
        id: 'privacy-policy',
        icon: Icons.privacy_tip_outlined,
        label: t.privacyPolicy,
        group: MenuGroup.support,
        isAction: true,
      ),
      MenuItem(
        id: 'terms-of-service',
        icon: Icons.article_outlined,
        label: t.termsOfService,
        group: MenuGroup.support,
        isAction: true,
      ),
      // Logout — own group → always a dedicated divider
      MenuItem(
        id: 'logout',
        icon: Icons.logout,
        label: t.logout,
        group: MenuGroup.logout,
        isDestructive: true,
        isAction: true,
      ),
    ];

    return allItems
        .where((item) => !item.requiresManagerRole || isManager)
        .toList();
  }

  static Widget buildUserInfo(UserInfo? userInfo, AppLocalizations t) {
    final displayName = userInfo?.fullName ?? userInfo?.email ?? '';
    final email = userInfo?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (userInfo?.fullName != null) ...[
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  static String getInitials(String? fullName, String email) {
    if (fullName != null && fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      }
      return fullName[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  /// Returns the menu item id that corresponds to [route], or null if no match.
  static String? activeIdForRoute(String route) {
    if (route == '/dashboard') return 'dashboard';
    if (route == '/manager-approvals') return 'sheet-approvals';
    if (route == '/manager/payments') return 'payments';
    if (route.endsWith('/profile')) return 'profile';
    if (route == '/manager/analysis') return 'expenses-analysis';
    if (route.endsWith('/history/report')) return 'expenses-detail-report';
    if (route == '/manager/company-config') return 'company-config';
    if (route == '/manager/users') return 'user-management';
    return null;
  }

  static Future<void> launchContactSupport(
    UserInfo userInfo,
    AppLocalizations t,
  ) async {
    try {
      final subject = Uri.encodeComponent(
        t.helpRequestSubject + userInfo.companyName,
      );
      final mailtoUri = Uri.parse('mailto:support@xpensedesk.com?subject=$subject');
      await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Silently fail if email client cannot be launched
      debugPrint('Could not launch email client: $e');
    }
  }
}
