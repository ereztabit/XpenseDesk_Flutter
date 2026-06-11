import 'screen_imports.dart';
import '../models/user_details.dart';
import '../providers/users_provider.dart';
import '../services/users_service.dart';
import '../widgets/app_button.dart';
import '../widgets/profile/profile_editor.dart';

/// Admin edit surface for another employee — opens the same profile UI the
/// employee sees, so an admin can fix name / language / gov ID. Loads details
/// via `GET /api/users/details` and saves via `PUT /api/users/admin-update`;
/// never touches the admin's own session or locale.
class EditUserScreen extends ConsumerStatefulWidget {
  const EditUserScreen({super.key, required this.targetUserId});

  final String targetUserId;

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen>
    with FormBehaviorMixin {
  bool _dirty = false;
  bool _didInvalidateOnEntry = false;

  @override
  bool get hasUnsavedChanges => _dirty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInvalidateOnEntry) return;
    _didInvalidateOnEntry = true;
    // Fresh fetch on (re)entry so a previously-edited user isn't stale.
    ref.invalidate(userDetailsProvider(widget.targetUserId));
  }

  void _onDirtyChanged(bool dirty) {
    if (_dirty != dirty) setState(() => _dirty = dirty);
  }

  Future<ProfileSaveOutcome> _save({
    required String fullName,
    required int languageId,
    required String govId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(usersServiceProvider).adminUpdateUser(
            targetUserId: widget.targetUserId,
            fullName: fullName,
            languageId: languageId,
            govId: govId,
          );
      // Reflect any name/language change in the list behind us.
      await ref.read(usersListProvider.notifier).refresh();
      return const ProfileSaveOutcome.success();
    } on UsersException catch (e) {
      switch (e.errorCode) {
        case 'UsersGovIdInvalidFormat':
        case 'UsersGovIdAlreadyExists':
          return ProfileSaveOutcome.govIdError(e.errorCode!);
        case 'UsersUpdateTargetUserNotFoundInCompany':
          return ProfileSaveOutcome.error(l10n.userNotFound);
        default:
          return ProfileSaveOutcome.error(e.message);
      }
    } catch (_) {
      return ProfileSaveOutcome.error(l10n.anErrorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailsAsync = ref.watch(userDetailsProvider(widget.targetUserId));

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
                        label: l10n.backToUsers,
                        variant: AppButtonVariant.ghost,
                        icon: Icons.arrow_back,
                        onPressed: () =>
                            handleBackNavigation('/manager/users'),
                      ),
                      const SizedBox(height: 16),
                      detailsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 64),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => _buildError(l10n, err),
                        data: (details) => _buildForm(l10n, details),
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

  Widget _buildError(AppLocalizations l10n, Object err) {
    final notFound = err is UsersException &&
        err.errorCode == 'UsersUpdateTargetUserNotFoundInCompany';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        notFound ? l10n.userNotFound : l10n.anErrorOccurred,
        style: const TextStyle(color: AppTheme.destructive, fontSize: 14),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n, UserDetails details) {
    final displayName =
        details.fullName.isEmpty ? details.email : details.fullName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title — whose profile is being edited.
        Row(
          children: [
            const Icon(Icons.manage_accounts_outlined,
                color: AppTheme.mutedForeground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.editUser,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          displayName,
          style: const TextStyle(
              fontSize: 13, color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 16),
        ProfileEditor(
          // Re-create the editor per target so its initial values reset when
          // the admin opens a different user.
          key: ValueKey(details.userId),
          initialFullName: details.fullName,
          initialEmail: details.email,
          initialLanguageId: details.languageId,
          initialGovId: details.govId ?? '',
          onDirtyChanged: _onDirtyChanged,
          onSave: _save,
        ),
      ],
    );
  }
}
