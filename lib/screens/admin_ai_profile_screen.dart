import 'screen_imports.dart';
import '../models/admin_ai_profile.dart';
import '../providers/admin_receipt_ai_provider.dart';
import '../utils/admin_ai_display_utils.dart';
import '../utils/admin_ai_review_utils.dart';
import '../widgets/admin/admin_header.dart';
import '../widgets/admin/receipt_ai/ai_draft_save_bar.dart';
import '../widgets/admin/receipt_ai/ai_gpt_prompt_tab.dart';
import '../widgets/admin/receipt_ai/ai_mistral_fields_tab.dart';
import '../widgets/admin/receipt_ai/ai_profile_header.dart';
import '../widgets/admin/receipt_ai/ai_profile_versions_bar.dart';
import '../widgets/admin/receipt_ai/ai_versions_tab.dart';
import '../widgets/admin/receipt_ai/ai_tab_strip.dart';

/// One AI profile (`/admin/receipt-ai/profiles/{n}`) - FS-1026. Prompts only:
/// GPT prompt, Mistral fields, versions. Edits save to the draft; companies
/// use the published version until Publish.
class AdminAiProfileScreen extends ConsumerStatefulWidget {
  const AdminAiProfileScreen({super.key, required this.profileId});

  final int profileId;

  @override
  ConsumerState<AdminAiProfileScreen> createState() => _AdminAiProfileScreenState();
}

class _AdminAiProfileScreenState extends ConsumerState<AdminAiProfileScreen> with FormBehaviorMixin {
  int _tab = 0;
  AdminAiDraftEdit? _edit;
  int? _loadedFrom; // the version number the editors hold
  bool _saving = false;

  @override
  bool get hasUnsavedChanges => _edit?.isDirty ?? false;

  /// (Re)fills the editors from the draft, else the published version - only
  /// when that version changed, so a rebuild never wipes typing.
  void _sync(AdminAiProfileDetail detail) {
    final v = detail.editable;
    if (v == null) return;
    final key = v.versionNumber * 10 + (detail.draft == null ? 0 : 1);
    if (_edit != null && _loadedFrom == key) return;
    _loadedFrom = key;
    _edit = AdminAiDraftEdit(system: v.gptSystemPrompt, user: v.gptUserPrompt, fields: v.fieldMap);
  }

  void _reload() {
    _loadedFrom = null;
    _edit = null;
    ref.invalidate(adminAiProfileProvider(widget.profileId));
    ref.invalidate(adminAiVersionsProvider(widget.profileId));
    ref.invalidate(adminAiProfilesProvider);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final edit = _edit;
    if (edit == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(adminAiProfilesServiceProvider)
          .saveDraft(widget.profileId, systemPrompt: edit.system, userPrompt: edit.user, mistralFields: edit.fields);
      if (!mounted) return;
      showAdminAiSnack(context, l10n.adminAiDraftSaved);
      setState(_reload);
    } catch (e) {
      if (mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _switchTab(int i) {
    if (i != _tab) setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminAiProfileProvider(widget.profileId));
    final detail = async.asData?.value;
    if (detail != null) _sync(detail);
    final edit = _edit;

    final Widget content;
    if (detail == null || edit == null) {
      content = async.hasError
          ? Text(adminAiErrorMessage(l10n, async.error!), style: const TextStyle(color: AppTheme.destructive))
          : const Center(child: CircularProgressIndicator());
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AiProfileVersionsBar(detail: detail, isDirty: edit.isDirty, onChanged: () => setState(_reload)),
          const SizedBox(height: 16),
          AiTabStrip(
            labels: [l10n.adminAiTabGpt, l10n.adminAiTabMistral, l10n.adminAiTabVersions],
            activeIndex: _tab,
            onTap: _switchTab,
          ),
          const SizedBox(height: 12),
          if (_tab == 0)
            AiGptPromptTab(
              edit: edit,
              todayToken: detail.todayToken,
              readOnly: detail.isArchived,
              onChanged: () => setState(() {}),
            ),
          if (_tab == 1)
            AiMistralFieldsTab(
              edit: edit,
              fields: detail.editable?.mistralFields ?? const [],
              published: detail.published?.fieldMap,
              readOnly: detail.isArchived,
              onChanged: () => setState(() {}),
            ),
          if (_tab == 2)
            AiVersionsTab(profileId: widget.profileId, isDirty: edit.isDirty, onRestored: () => setState(_reload)),
          if (_tab < 2 && edit.isDirty)
            AiDraftSaveBar(
              saving: _saving,
              disabled: detail.isArchived,
              onRevert: () => setState(() => _loadedFrom = null),
              onSave: _save,
            ),
        ],
      );
    }

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AdminHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ConstrainedContent(
                  maxWidth: AppTheme.containerMaxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AiProfileHeader(
                        profileId: widget.profileId,
                        detail: detail,
                        isDirty: _edit?.isDirty ?? false,
                        onImported: () => setState(_reload),
                      ),
                      const SizedBox(height: 16),
                      content,
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
