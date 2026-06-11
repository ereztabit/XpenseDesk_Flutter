import 'screen_imports.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../widgets/profile/profile_editor.dart';

/// Self-service profile screen. Orchestrator only: owns the scaffold + back
/// navigation and delegates the form to the shared [ProfileEditor]. Saving goes
/// through the self endpoint (`update-details`) and updates the session +
/// locale.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with FormBehaviorMixin {
  bool _dirty = false;

  @override
  bool get hasUnsavedChanges => _dirty;

  void _onDirtyChanged(bool dirty) {
    // Rebuild so PopScope.canPop (built from hasUnsavedChanges) stays current.
    if (_dirty != dirty) setState(() => _dirty = dirty);
  }

  Future<ProfileSaveOutcome> _save({
    required String fullName,
    required int languageId,
    required String govId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final updated = await ref.read(authServiceProvider).updateUserProfile(
            fullName,
            languageId,
            govId: govId,
          );
      // Updates the session; locale is applied automatically by updateProfile.
      ref.read(userInfoProvider.notifier).updateProfile(updated);
      return const ProfileSaveOutcome.success();
    } on AuthException catch (e) {
      if (e.errorCode == 'UsersGovIdInvalidFormat' ||
          e.errorCode == 'UsersGovIdAlreadyExists') {
        return ProfileSaveOutcome.govIdError(e.errorCode!);
      }
      return ProfileSaveOutcome.error(e.message);
    } catch (_) {
      return ProfileSaveOutcome.error(l10n.failedToUpdateProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userInfo = ref.watch(userInfoProvider);

    if (userInfo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: RefreshableScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppButton(
                        label: l10n.backToDashboard,
                        variant: AppButtonVariant.ghost,
                        icon: Icons.arrow_back,
                        onPressed: () => handleBackNavigation('/dashboard'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: AppTheme.mutedForeground),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profile,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ProfileEditor(
                        initialFullName: userInfo.fullName,
                        initialEmail: userInfo.email,
                        initialLanguageId: userInfo.languageId,
                        initialGovId: userInfo.govId ?? '',
                        onDirtyChanged: _onDirtyChanged,
                        onSave: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
