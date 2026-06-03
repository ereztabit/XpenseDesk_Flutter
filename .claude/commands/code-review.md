Run a project-specific code review on the current changes. **Apply this after every code change in this Flutter codebase.** This is a mandatory post-change step per project standards.

Output: a CR markdown next to the relevant implementation doc (typically `docs/in-progress/<feature>/<feature>-CR.md`). Findings categorized as **blocker** / **should-fix** / **nit**. Propose fixes; wait for user approval before applying them.

---

## Rules to enforce

### Rule 1 — File size & component-per-file

- Every **widget / screen** Dart file under 200 lines. Run `wc -l <files>`.
- Util / service modules may exceed 200 lines when they contain multiple grouped static-method classes by theme (mirrors `lib/utils/format_utils.dart`, `lib/utils/sheet_utils.dart`). The rule is about not bloating individual *widgets* — domain helpers are correctly consolidated.
- **Substantial** UI components are their own widget in their own file. Run `grep '^class _\w\+ '` over touched dirs.
  - The conventional `_FooState extends ConsumerState<Foo>` for stateful widgets is allowed (it's the state pair of the public widget).
  - Substantial private widgets — `_HeaderRow`, `_TabButton`, `_BodyRow`, `_ExpensesArea`, anything that owns a real chunk of layout (~40+ lines, structural elements like rows / headers / list items) — are violations. Extract.
  - **Exception:** trivial styling micro-helpers under ~30 lines (small badges, pills, switch dispatchers) may stay private to their parent file. They're noise to extract and don't drive file bloat.

### Rule 2 — Logic in services, helpers in utils

- Widgets compose data and render UI. They do **not** house derived-data math.
- Pure functions on domain data (filtering, counting, sorting, permissions, formatting, derivation) belong in `lib/utils/<theme>_utils.dart`.
- HTTP calls and stateful business logic belong in `lib/services/<theme>_service.dart`.
- Red flags in widget code:
  - Long `_foo()` private methods on `*State` or `ConsumerWidget` classes that compute derived values.
  - `.where(...)`, `.fold(...)`, `.map(...)` chains in `build()` that compute summaries.
  - `firstWhere`/`reduce` selecting "the default", "the current", "the matching" — selection logic belongs in a util.
- Consolidate utils per theme — prefer **one file with multiple grouped static-method classes** over many tiny files. Mirror the `format_utils.dart` pattern.

### Rule 3 — No hardcoded currencies

- Every amount renders via `num.toCurrency(companyLocale, currencyCode)` (or `toSmartCurrency` / `toFormattedNumber`) from `lib/utils/format_utils.dart`.
- The symbol comes from `NumberFormat.simpleCurrency(name: currencyCode).currencySymbol` — never from a string literal in widget code.
- Grep checks:
  ```
  grep -RIn "'\$'\\|'₪'\\|'€'\\|'£'" lib/widgets lib/screens
  ```
- Dart string interpolation (`'$variable'`, `'${l10n.foo}'`) is fine — the `$` is syntax, not a currency.

### Rule 4 — No hardcoded captions ⚠️ RECURRING OFFENDER — MANDATORY GATE

**This has slipped through 3+ times. Treat the grep below as a hard gate: run it on every touched file and paste the (empty) result into the CR before signing off. No "looks fine by eye".**

- Every user-visible string uses `AppLocalizations.of(context)!`.
- ARB keys (EN + HE) are added **before** widget code per CLAUDE.md.
- Required grep (must return zero on the changed files):
  ```
  grep -nE "Text\('[A-Za-z]|tooltip:\s*'[A-Za-z]|hintText:\s*'[A-Za-z]|label:\s*'[A-Za-z]|labelText:\s*'[A-Za-z]" <changed files>
  ```
- Also eyeball any new `'...'` string passed to `SnackBar`, `AlertDialog`, `Tooltip`, `semanticLabel`, enum→label switches, and `'$x ...'` interpolations — greps miss strings built by concatenation.
- **Verify BOTH locales:** when you add an ARB key, confirm it exists in `app_en.arb` AND `app_he.arb`. A key present only in EN silently falls back to the key name in HE.
- **Typographic characters are OK** — `'—'` (em dash), `' · '` (middle dot), `'#'` (hash), `'←' / '→'` (arrow glyphs). Universal punctuation; they don't translate.
- **Brand initialisms** (e.g. `'AI'`) live in **one shared widget** (`lib/widgets/ai_badge.dart`), not copy-pasted. The literal is acceptable; the duplication is not.

### Rule 5 — Flutter modern-patterns hygiene (per CLAUDE.md)

- No `Color.withOpacity` — use `withAlpha` (0–255).
- No `EdgeInsets.only(left:|right:)` — use `EdgeInsetsDirectional.only(start:|end:)`.
- No `TextAlign.left|right` — use `TextAlign.start|end`.
- No `Icons.arrow_back_ios|forward_ios` — use `Icons.arrow_back|forward`.
- No raw `http.*` outside `ApiService`.
- No `DropdownButtonFormField` (deprecated) — use `DropdownMenu` or `MenuAnchor`.
- ARB keys: no `{placeholder}` syntax — concat in widget.

### Rule 6 — Responsive overflow + RTL correctness

Layout/RTL bugs this codebase has repeatedly hit — check each on any new layout:

**Overflow:**
- A `Row` with intrinsic-width content (icon buttons, fixed widgets) inside `Expanded(flex:)` can overflow at narrow viewports. **Use `SizedBox(width: N)` for icon-button columns**, not `Expanded`.
- `IntrinsicHeight` + `Expanded` + text can sub-pixel-overflow under dart2js (the "OVERFLOWED BY 1.00 PIXELS" stripe). Avoid `IntrinsicHeight`; size with a `Stack` + `PositionedDirectional` instead.
- Test at the project breakpoints (`< 600`, `< 768`, `>= 768`).

**RTL (verify with the app switched to Hebrew):**
- **Directional Material icons auto-mirror in RTL.** `Icons.arrow_back` / `arrow_forward` (and other `matchTextDirection` glyphs) flip automatically — correct for nav back/forward buttons, but it means you must NOT manually pick `arrow_back` to mean "left". For a manually-direction-chosen arrow (e.g. a status transition), use a plain glyph in a `Text` (`'←' / '→'`) forced to `TextDirection.ltr` so it renders verbatim.
- **Don't concatenate mixed-direction content into one string** (e.g. an English name + a Hebrew date: `'$name · $date'`). Bidi reordering scrambles it. Split into separate `Text` runs in a `Row` so each keeps its own direction.
- Use `EdgeInsetsDirectional` / `start`/`end` / `PositionedDirectional`, never `left`/`right`.

## How to apply

1. Identify files touched in the current change. Use `git status --short` if needed.
2. Run line counts on every touched file (`wc -l`) and grep audits per the rules above.
3. Write a CR markdown next to the implementation doc:
   - `## TL;DR` — one paragraph
   - `## 1. File-size audit` — table of files + verdict
   - `## 2. Embedded private classes` — list
   - `## 3. Inline logic` — what to extract, where to
   - `## 4. Currencies & captions audit` — clean / flagged
   - `## 5. Flutter hygiene` — withOpacity / EdgeInsets.only / etc.
   - `## 6. Responsive overflow risk` — flagged breakpoints to check
   - `## 7. Recommended fix plan` — sequenced steps, each independently shippable
4. Present findings to the user. Recommend an option. **Wait for explicit go-ahead** before applying fixes.
5. After applying fixes, re-run the audits and confirm zero findings.
