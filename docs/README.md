# XpenseDesk Flutter Documentation

AI-powered expense approval tool for small businesses.

## Product (Source of Truth)
- [AI Expense Approval MVP North Star](product/ai_expense_approval_mvp_north_star.md) — Complete product vision and feature set
- [MVP Screen Map](product/mvp_screen_map.md) — Screen definitions and user flows

## v2 (Post-MVP Backlog)
- [v2 Checklist](v2/README.md) — features/bugs deferred out of the MVP

## Guides
- [Flutter Web Deployment Guide](flutter-web-deployment-guide.md) — build + Azure Static Web Apps deploy
- [PWA Debugging & Verification Guide](pwa-debugging-guide.md) — inspect manifest/icons/service worker; why `flutter run` stubs the manifest

## Where a spec lives

| Folder | Meaning |
|--------|---------|
| [in-progress/](in-progress/) | What we are actively working on **right now**. Empty when nothing is in flight. |
| [backlog/](backlog/) | Open features we are not working on yet. Indexed in [current-work.md](current-work.md). |
| [completed/](completed/) | Shipped to production. |
| [bugs/](bugs/) + [bugs/completed/](bugs/completed/) | Open and closed bug reports. |

A spec moves `backlog/` → `in-progress/` when work starts, → `completed/` when it
ships, or back to `backlog/` if the work is paused or dropped.

## Backlog specs (open, not started)
- [Multi-Currency Expenses](backlog/multi-currency-expenses.md) — core + follow-up 1 shipped and verified; follow-up 2 (AI scan of foreign currency) open
- [Spend Overview Spec](backlog/spend-overview-spec.md) — manager card live; employee side + the approvals-screen slot are still placeholders
- [Post-Login Deep Linking](backlog/post-login-deep-linking-spec.md)
- [Calendar Week-Start Localization](backlog/calendar-week-start-localization-spec.md) — post-MVP
- [Coupon Verbiage Review](backlog/coupon-verbiage-review.md) — copy-only
- [Manager Edit Decline Reason](backlog/manager-edit-decline-reason.md) — deferred to v2, blocked on the server API

Shipped feature specs live in [completed/](completed/) — including the Microsoft
login and SSO onboarding guides, payment status, PWA, and the Expense Sheets
transformation.

## API Guides
- [Authentication Client Guide](api-guides/authentication_client_guide.md)
- [Client Onboarding / Company API](api-guides/client-onboarding-company-api-guide.md)
- [Expense API Guide](api-guides/expense-api-guide.md)
- [Users API Documentation](api-guides/users_api_documentation.md)
- [Expenses Analysis API Guide](api-guides/expenses-analysis-api-guide.md)

## Completed
- [Login Flow](completed/login.md)
- [Menu System](completed/menu_system.md)
- [User Profile Screen](completed/user_profile_screen.md)
- [Users Management UX](completed/users_management_ux.md)
- [Onboarding Implementation Plan](completed/onboarding-implementation-plan.md)
- [Employee Expenses Design](completed/Exmployee-expenses-design.md)
- [Employee Expenses Implementation Plan](completed/employee-expenses-implementation-plan.md)
- [New Expense Desktop Spec](completed/new-expense-desktop-spec.md)
- [New Expense Mobile Spec](completed/new-expense-mobile-spec.md)
- [Edit Expense Spec](completed/edit-expense-spec.md)
- [Cycle Widget Spec](completed/cycle-widget-spec.md)
- [Cycle Selector Spec](completed/cycle-selector-spec.md)
- [Cycle Expenses Report Spec](completed/cycle-expenses-report-spec.md)
- [Cycle Expenses Report Mobile Spec](completed/cycle-expenses-report-mobile-spec.md)
- [Category Selector Spec](completed/category-selector-spec.md)
- [Mobile Language Switcher Spec](completed/mobile-language-switcher-spec.md)
- [Pull to Refresh Spec](completed/pull-to-refresh-spec.md)
- [Web Startup Loader Spec](completed/web-startup-loader-spec.md)
- [Expenses Analysis Spec](completed/expenses-analysis-spec.md)
- [Flutter Delete User Error Guide](completed/flutter-delete-user-error-guide.md)
- [Manager Dashboard Spec](completed/manager-dashboard-spec.md)
- [Users Management Go-To-Dev](completed/users_managment_gotodev.md)
