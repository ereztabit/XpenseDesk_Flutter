# Admin free plan - API guide (FS-1008)

> Mission: FS-1008. Backend story: `BackEnd/XpenseDeskServer/docs/admin-panel/admin-free-plan-story.md`.
> Frontend spec: [docs/completed/admin-free-plan-spec.md](../completed/admin-free-plan-spec.md).
> The same guide is filed in the Flutter repo as `docs/api-guides/admin-free-plan-api-guide.md`.

A support agent (platform admin, `roleId 3`) puts a company on the **free plan**
or takes it off. On the free plan the company reads as paid everywhere - no
free-receipt limit, no payment banner - with no card and nothing at Tranzila.

What a free plan is in the database: a `CompanySubscription` on the Free plan
(`BillingPlanId 3`, 0.00), status Active, `EndDate` 2099-01-01, no future plan,
on a company with no `CompanyPaymentMethod`. The rules live in the headers of
`proc_Admin_SetFreePlan` / `proc_Admin_ClearFreePlan` (applied to dev and prod
2026-10-01).

---

## 1. `POST /api/admin/companies/{companyId}/free-plan` - set

No request body.

```json
200 OK
{
  "success": true,
  "message": "Free plan set successfully",
  "data": { "isFreePlan": true, "freePlanEndDate": "2099-01-01T00:00:00" }
}
```

Also resets the company's block mode to None, and logs `FreePlanSet` in the
subscription history under the support agent.

## 2. `DELETE /api/admin/companies/{companyId}/free-plan` - clear

Removes the free-plan subscription. The company is back to where it was before
it: no subscription (`subscriptionStatus: "PendingPayment"`), the free-receipt
limit applies again, and the normal subscribe flow is open to it.

```json
200 OK
{
  "success": true,
  "message": "Free plan cleared successfully",
  "data": { "isFreePlan": false, "freePlanEndDate": null }
}
```

Logs `FreePlanCleared` in the subscription history under the support agent.

## 3. Errors (both endpoints)

| Status | `errorCode` | When |
|---|---|---|
| 403 | - | The caller is not a platform admin (an impersonated session included). |
| 404 | `AdminCompanyNotFound` | Unknown company, or the platform company. |
| 409 | `AdminFreePlanCompanyPays` | Set only. The company has a card on file, or a subscription still running. Giving it the free plan would leave its Tranzila standing order charging. A card is never removed, so a former paying customer cannot get the free plan. |
| 409 | `AdminFreePlanAlreadySet` | Set only. Already on the free plan. |
| 409 | `AdminFreePlanNotSet` | Clear only. Not on the free plan - a coupon or paid plan is never touched here. |

## 4. Where the state shows up

| Endpoint | Field | Notes |
|---|---|---|
| `GET /api/admin/companies` | `isFreePlan` (bool) | Per row. `paymentStatus` reads `Active` on the free plan like a paying company; this tells them apart. |
| `GET /api/company` | `isFreePlan` (bool) | The client hides the payment banner, the card and the cancel controls on it. `isInTrial` is unchanged by the free plan - a company given it during its trial still reads `isInTrial: true`. |
| `GET /api/company/billing` | `subscription.planId: 3`, `planName: "Free"`, `endDate: 2099-01-01`, `nextChargeAmount: 0`, `paymentMethod: null` | Unchanged shape. |
| `GET /api/users/me/free-receipts` | `isLimited: false` | Unchanged endpoint; the free plan counts as a paid plan. |

## 5. The customer's own billing calls on the free plan

Nothing at Tranzila backs the free plan, so the manager's calls that would
touch a standing order are refused - only support changes the free plan. The
app hides these controls on the free plan; the refusal is the server's guard.

| Call | On the free plan |
|---|---|
| `PUT /api/company/billing/info` | **Allowed** - saved to the database only (no standing order to update). |
| `POST /api/company/payment-method` | 409 `SubscriptionFreePlanManagedBySupport` |
| `POST /api/company/subscription/move-to-annual` | 409 `SubscriptionFreePlanManagedBySupport` |
| `POST /api/company/subscription/move-to-monthly` | 409 `SubscriptionFreePlanManagedBySupport` |
| `POST /api/company/subscription/cancel` | 409 `SubscriptionFreePlanManagedBySupport` |
| `POST /api/onboarding/subscription` | 409 `SubscribeAlreadyActive` (unchanged: the subscription is Active) |
| `POST /api/company/subscription/resume` | Refused as before - no card to charge. |
