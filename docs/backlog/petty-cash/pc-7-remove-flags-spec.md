# PC-7 - Remove the dark-launch flags (Petty Cash, Travel, bulk upload)

> Mission: FS-1018 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-7-remove-flags.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-16. Not started. **Starts only when Petty Cash is done.**
Why and what goes: see the backend story. Travel's flag stays if Travel is not
done yet; the bulk upload flag is stale already and goes in the same pass.

## Client changes

- `CompanyConfiguration` and `AdminCompanyConfiguration`: drop the removed
  fields (and `AdminFeatureFlag` values); delete the models if nothing is left.
- Admin -> company -> Configuration tab: drop the removed switch rows; drop the
  Features card if it is empty (`admin_company_configuration_body.dart`,
  `admin_feature_flag_utils.dart`, `adminCompanyConfigurationProvider`, the
  admin service calls).
- Every client check of `isBulkUploadEnabled` (bulk upload entry points,
  notifications bell, live updates) and of the module flags.
- `CompanyModulesActions._guard` and the `CompanyModuleNotAvailable` message.
- ARB keys of the removed switches and the error (EN + HE).

## Done when

- Grep finds no removed flag in `lib/`; analyze and build clean; manual QA of
  the admin Configuration tab, bulk upload and the Modules tab.
