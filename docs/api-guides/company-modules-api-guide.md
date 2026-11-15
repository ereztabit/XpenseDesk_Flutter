# Company Modules + Categories - API Guide

> Mission: FS-1010. Story: docs/backlog/company-modules-and-categories-story.md.
> Same file in the backend repo: docs/guides/company-modules-api-guide.md.

Modules: `Monthly`, `PettyCash`, `Travel`. Every company owns its categories,
per module. All bodies use the common `ApiResponse` envelope
(`success`, `message`, `errorCode`, `data`).

## Reading - no new call

`GET /api/company` (already called at app start) gains two fields. Any company
user gets them - employees need category names to show existing expenses.

```json
"modules": [
  { "module": "Monthly",   "isEnabled": true,  "isLocked": true,  "allowNegativeBalance": null,  "updatedAt": null },
  { "module": "PettyCash", "isEnabled": false, "isLocked": false, "allowNegativeBalance": false, "updatedAt": null },
  { "module": "Travel",    "isEnabled": false, "isLocked": false, "allowNegativeBalance": null,  "updatedAt": null }
],
"categories": [
  { "categoryId": 987, "module": "Monthly", "nameEn": "Food & meals", "nameHe": "אוכל וארוחות",
    "taxKey": null, "isActive": true, "isSystem": false, "isFallback": false, "isUsed": true }
]
```

| Field | Meaning |
|---|---|
| `isLocked` | Cannot be turned off yet (Monthly, MVP) - show the switch disabled |
| `allowNegativeBalance` | Petty Cash only; `null` elsewhere |
| `categories` | Every module, **inactive included**. Pickers show `isActive` ones of the module; anything showing an existing expense resolves its `categoryId` here |
| `nameEn` / `nameHe` | Either may be `null` - display the other one |
| `taxKey` | Travel only: `Flights`, `Lodging`, `Rentals`, `Transport`, `Food`, `Host`, `Other` |
| `isSystem` | Travel default: no rename; Delete deactivates it |
| `isFallback` | Monthly "Other": no delete, no deactivate (rename allowed) |
| `isUsed` | An expense uses it - Delete will deactivate rather than delete |

Ids are per company. Never assume ids 1-6. Sort by the name in the UI language.

## Writing - manager only

Every write returns the changed item in `data`; refresh `GET /api/company`
afterwards if the screen shows the full lists. An employee gets **403
`CompanyModulesManagerOnly`** on all of them.

| Method + path | Body | `data` |
|---|---|---|
| `PUT /api/company/modules/{module}` | `{ "isEnabled": true }` | the module |
| `PUT /api/company/modules/PettyCash/settings` | `{ "allowNegativeBalance": true }` | the module |
| `POST /api/company/categories` | `{ "module": "Travel", "nameEn": "Visa fees", "nameHe": null, "taxKey": "Other" }` | the category |
| `PUT /api/company/categories/{categoryId}` | `{ "nameEn": "...", "nameHe": "...", "taxKey": "..." }` (module not changeable) | the category |
| `DELETE /api/company/categories/{categoryId}` | - | `{ "outcome": "Deleted" \| "Deactivated", "category": null \| {...} }` |
| `POST /api/company/categories/{categoryId}/reactivate` | - | the category |

**Delete is one action.** No expense uses it and it is not a system category ->
`Deleted`. Otherwise -> `Deactivated` (the category stays on existing expenses).
Show the confirm text by `isUsed` / `isSystem` before calling.

## Error codes

| Code | Status | When |
|---|---|---|
| `CompanyModulesManagerOnly` | 403 | caller is not a manager |
| `CompanyModuleNotFound` | 404 | unknown module name |
| `CompanyModuleLocked` | 409 | turning Monthly off |
| `CompanyModuleLastEnabled` | 409 | turning off the last enabled module |
| `CompanyModuleSettingNotApplicable` | 400 | a setting the module does not have |
| `MandatoryFieldsMissing` | 400 | `isEnabled` / `allowNegativeBalance` / `module` missing |
| `CategoryNotFound` | 404 | no such category in this company (another company's id too) |
| `CategoryNameRequired` | 400 | neither name given |
| `CategoryNameTooLong` | 400 | a name over 100 characters |
| `CategoryNameAlreadyExists` | 409 | the module has that name already, in either language |
| `CategoryTaxKeyRequired` | 400 | Travel category without a tax key |
| `CategoryTaxKeyNotAllowed` | 400 | tax key on a non-Travel category |
| `CategoryTaxKeyInvalid` | 400 | unknown tax key |
| `CategorySystemLocked` | 409 | renaming a Travel default |
| `CategoryFallbackLocked` | 409 | deleting Monthly "Other" |

## Expenses

`POST /api/expenses` and `PUT /api/expenses/{id}` take the company's own
Monthly `categoryId`. New outcome: **400 `ExpenseCategoryNotAvailable`** - not
an active Monthly category of this company (an edit may keep the category the
expense already has, even if it was deactivated since).

Back-compat: the legacy ids 1-6 (and "no category", which files under Other)
are still accepted and stored as the company's own copy - so a returned
`categoryId` differs from the one sent. `categoryName` on expenses keeps its
stable legacy key (`FoodNMeals`, ...); display names come from `categories`.
