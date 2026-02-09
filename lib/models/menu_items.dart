import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/l10n/app_localizations.dart';
import 'token_info.dart';

class MenuItem {
  final String id;
  final IconData icon;
  final String label;
  final bool requiresManagerRole;
  final bool isDestructive;
  final bool isAction;

  const MenuItem({
    required this.id,
    required this.icon,
    required this.label,
    this.requiresManagerRole = false,
    this.isDestructive = false,
    this.isAction = false,
  });
}

class MenuItems {
  static List<MenuItem> getItems(AppLocalizations t, bool isManager) {
    final allItems = [
      MenuItem(
        id: 'profile',
        icon: Icons.person_outline,
        label: t.myProfile,
      ),
      MenuItem(
        id: 'spend-history',
        icon: Icons.history,
        label: t.spendHistory,
        requiresManagerRole: true,
      ),
      MenuItem(
        id: 'company-config',
        icon: Icons.settings_outlined,
        label: t.companyConfiguration,
        requiresManagerRole: true,
      ),
      MenuItem(
        id: 'user-management',
        icon: Icons.people_outline,
        label: t.userManagement,
        requiresManagerRole: true,
      ),
      MenuItem(
        id: 'logout',
        icon: Icons.logout,
        label: t.logout,
        isDestructive: true,
        isAction: true,
      ),
      MenuItem(
        id: 'contact-support',
        icon: Icons.email_outlined,
        label: t.contactSupport,
        isAction: true,
      ),
    ];

    return allItems
        .where((item) => !item.requiresManagerRole || isManager)
        .toList();
  }

  static Widget buildUserInfo(TokenInfo? tokenInfo, AppLocalizations t) {
    final displayName = tokenInfo?.fullName ?? tokenInfo?.email ?? '';
    final email = tokenInfo?.email ?? '';

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
        if (tokenInfo?.fullName != null) ...[
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

  static Future<void> launchContactSupport(
    TokenInfo tokenInfo,
    AppLocalizations t,
  ) async {
    try {
      final subject = Uri.encodeComponent(
        t.helpRequestSubject(tokenInfo.companyName),
      );
      final mailtoUri = Uri.parse('mailto:support@xpensedesk.com?subject=$subject');
      await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Silently fail if email client cannot be launched
      print('Could not launch email client: $e');
    }
  }
}
