# Affiliate Referral System — Design Spec

**Date:** 2026-06-21  
**Status:** Approved  
**Author:** Douglas + Claude

---

## 1. Overview

A lightweight affiliate referral system that allows anyone to generate a unique tracking link, share it, and earn a one-time commission (20% of the referred client's first payment). The system prioritizes simplicity: no affiliate login, no recurring tracking, no financial complexity — just register, share the link, and get paid via PIX when a client converts.

---

## 2. Business Rules

- **Anyone** can register as an affiliate (no approval flow)
- Commission = **20% of the first payment** of the referred organization
- Commission is paid **once per referred client** — not recurring
- Payment is **manual PIX** initiated by the admin
- Affiliate code is the sole authentication for the dashboard (no login/password)
- An `INACTIVE` affiliate does not generate new commissions even if their code is still stored on an organization

---

## 3. Entry Points & Attribution

| Channel | Attribution method |
|---|---|
| Affiliate link → landing page (`?ref=CODE`) | Automatic via email match when admin creates account |
| WhatsApp direct (no link clicked) | Manual: admin selects affiliate in user creation form |
| Instagram / organic | No affiliate — lead tracked for conversion analytics only |

**Key rule:** the affiliate's job is always to send their link, even on WhatsApp. The link goes to `/landing?ref=CODE`. If the prospect submits their email there, attribution is automatic. If not, the admin fills the "Referred by" field manually when creating the account.

---

## 4. Data Model

### 4.1 New table: `affiliates`

```sql
id             BIGINT PK AUTO_INCREMENT
name           VARCHAR NOT NULL
email          VARCHAR NOT NULL UNIQUE
whatsapp       VARCHAR NOT NULL
code           VARCHAR(8) NOT NULL UNIQUE  -- generated, e.g. "A7K2P9"
commission_rate DECIMAL(5,4) NOT NULL DEFAULT 0.2000
status         ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE'
created_at     TIMESTAMP NOT NULL DEFAULT NOW()
```

### 4.2 New table: `referral_commissions`

```sql
id                BIGINT PK AUTO_INCREMENT
affiliate_id      BIGINT NOT NULL FK → affiliates(id)
organization_id   BIGINT NOT NULL UNIQUE  -- one commission per org
plan_name         VARCHAR NOT NULL
plan_price        DECIMAL(10,2) NOT NULL
commission_rate   DECIMAL(5,4) NOT NULL   -- snapshot at conversion time
commission_amount DECIMAL(10,2) NOT NULL  -- plan_price * commission_rate
status            ENUM('PENDING','PAID') NOT NULL DEFAULT 'PENDING'
paid_at           TIMESTAMP NULL
created_at        TIMESTAMP NOT NULL DEFAULT NOW()
```

`UNIQUE(organization_id)` enforces idempotency — one commission per referred client, ever.

### 4.3 Modified table: `organizations`

```sql
-- New column
referral_code  VARCHAR(8) NULL  -- FK reference to affiliates.code (soft)
```

### 4.4 Modified table: `landing_leads`

```sql
-- New column
affiliate_code  VARCHAR(8) NULL  -- populated when ?ref= is present
```

---

## 5. End-to-End Flow

```
1. REGISTRATION
   Affiliate visits /indicador/novo
   → fills name, email, WhatsApp
   → POST /api/v1/affiliates (public)
   → system generates unique 6-char alphanumeric code
   → page shows: "Your link: easymaintenance.com.br/landing?ref=A7K2P9"

2. PROSPECT ARRIVES
   Prospect visits /landing?ref=A7K2P9
   → frontend saves cookie "em_ref=A7K2P9" (30 days, SameSite=Lax)
   → prospect submits email form
   → POST /api/v1/landing/leads with affiliateCode="A7K2P9"
   → LandingLead saved with affiliate_code="A7K2P9"

3. ADMIN CREATES ACCOUNT
   Admin opens user creation form
   → types prospect's email
   → backend queries: SELECT * FROM landing_leads WHERE email = ? AND affiliate_code IS NOT NULL
   → if match found: "Referred by" field pre-filled with affiliate name
   → admin confirms (or fills manually for WhatsApp cases)
   → Organization created with referral_code="A7K2P9"

4. TRIAL & CONVERSION
   User completes onboarding → 14-day trial
   User chooses plan → pays first installment

5. COMMISSION CREATION
   PaymentReceivedHandler fires
   → checks: is this organization's FIRST payment? (payment.cycleNumber == 1)
   → checks: does organization.referral_code exist?
   → checks: is the affiliate ACTIVE?
   → YES to all → CommissionService.createCommission(org, payment, affiliate)
   → ReferralCommission created with status=PENDING
   → commissionAmount = planPrice * commissionRate (snapshot)

6. ADMIN PAYS
   Admin sees PENDING commission in /private/admin/affiliates
   → pays PIX to affiliate
   → clicks "Mark as Paid"
   → PATCH /api/v1/admin/commissions/{id}/pay
   → status = PAID, paid_at = now()
```

---

## 6. Backend Module Structure

New module following the existing `leads/` pattern:

```
easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/
└── affiliates/
    ├── domain/
    │   ├── Affiliate.java
    │   └── ReferralCommission.java
    ├── application/
    │   ├── dto/
    │   │   ├── CreateAffiliateRequest.java
    │   │   ├── AffiliateResponse.java
    │   │   ├── AffiliateDashboardResponse.java   -- public dashboard data
    │   │   ├── CommissionSummaryResponse.java     -- for admin
    │   │   └── ReferralLeadResponse.java          -- masked lead info for dashboard
    │   └── service/
    │       ├── AffiliateService.java
    │       └── CommissionService.java
    └── infrastructure/
        ├── persistence/
        │   ├── AffiliateRepository.java
        │   └── ReferralCommissionRepository.java
        └── web/
            ├── AffiliateController.java           -- public endpoints
            └── CommissionAdminController.java     -- admin endpoints (secured)
```

**Existing files modified:**
- `leads/domain/LandingLead.java` — add `affiliateCode` field
- `leads/application/dto/CreateLeadRequest.java` — add `affiliateCode` field
- `leads/application/service/LeadService.java` — persist `affiliateCode`
- `org_users/domain/Organization.java` — add `referralCode` field
- `org_users/application/service/OrganizationsService.java` — accept optional `referralCode` in creation flow
- `org_users/infrastructure/web/OrganizationsController.java` — expose `referralCode` field in admin create endpoint
- `webhooks/asaas/strategy/impl/PaymentReceivedHandler.java` — trigger commission on first payment

---

## 7. Frontend Module Structure

New module following Next.js app router convention:

```
easy-maintenance-web/src/app/
└── indicador/
    ├── novo/
    │   └── page.tsx        -- affiliate registration form
    └── [code]/
        └── page.tsx        -- affiliate dashboard (public, code = auth)
```

**Existing files modified:**
- `landing/page.tsx` — read `?ref=` param, set `em_ref` cookie, pass `affiliateCode` in lead submission
- `private/admin/` — new `affiliates/page.tsx` — commission management panel
- User creation form (under `private/`) — add "Referred by" field with auto-suggestion

---

## 8. API Endpoints

### Public

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/affiliates` | Register new affiliate |
| GET | `/api/v1/affiliates/{code}/dashboard` | Dashboard data (masked) |

### Admin (secured)

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/admin/commissions` | List all commissions (filterable by status) |
| PATCH | `/api/v1/admin/commissions/{id}/pay` | Mark commission as paid |
| GET | `/api/v1/admin/affiliates` | List all affiliates |
| PATCH | `/api/v1/admin/affiliates/{id}/status` | Activate/deactivate affiliate |

### Modified

| Method | Path | Change |
|---|---|---|
| POST | `/api/v1/landing/leads` | Accept optional `affiliateCode` field |
| POST | `/api/v1/organizations` (or onboarding) | Accept optional `referralCode` field |

---

## 9. Affiliate Dashboard (`/indicador/[code]`)

Displayed data:
- Affiliate name and their unique link (copy button)
- **Total leads** — how many people clicked the link and submitted email
- **Total conversions** — how many became paying clients
- **Pending commissions** — total BRL awaiting payment
- **Paid commissions** — total BRL already received
- Lead list: masked email (`jo***@gmail.com`), status (Lead / Converted), date

PII policy: emails are masked, no plan prices or organization names exposed.

---

## 10. Admin Commission Panel (`/private/admin/affiliates`)

- Table: affiliate name, referred organization, plan, plan price, commission amount (BRL), status badge, conversion date
- Filter by: status (PENDING / PAID), date range
- Action: "Mark as Paid" button on PENDING rows
- Summary row: total pending BRL

---

## 11. Edge Cases & Constraints

| Scenario | Behavior |
|---|---|
| Same affiliate tries to register twice with same email | 400 — email already registered |
| Commission already exists for this organization | No-op (UNIQUE constraint) |
| Organization has `referralCode` but affiliate is INACTIVE | Commission NOT created |
| Admin creates account without selecting affiliate | `referralCode` stays NULL, no commission ever |
| Prospect submits email multiple times (same email) | Only the first `LandingLead` with `affiliateCode` is used for match |
| First payment is a PIX that gets refunded | Commission remains PENDING — admin decides whether to pay or not (manual process) |

---

## 12. Out of Scope (future)

- Email confirmation for affiliate registration
- Recurring commissions
- Affiliate-initiated prospect reporting ("I referred this person")
- Automatic PIX payout
- Tiered commission rates
- Affiliate performance analytics beyond basic counts
