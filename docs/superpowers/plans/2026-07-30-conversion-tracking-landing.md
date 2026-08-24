# Conversion Tracking for Landing Page (EPIC-018) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare `easymaintenance.com.br` for paid traffic (Meta Ads, Google Ads) launching this week: persist UTM attribution, require LGPD consent on the demo form, add a `/obrigado` confirmation page, and wire up (currently no-op) Lead/Contact conversion event stubs.

**Architecture:** Backend gets one additive column + one validation rule on the existing `POST /landing/leads` endpoint. Frontend gets two new small pure libs (`utm.ts`, `tracking.ts`), one new route (`/obrigado`), one existing-file fix (`Shell.tsx` auth whitelist), and one existing-file edit (the demo form in `landing/page.tsx`).

**Tech Stack:** Spring Boot / JPA / Flyway (backend, MySQL), Next.js App Router / TypeScript / Bootstrap / `js-cookie` / Jest+ts-jest (frontend, `testEnvironment: 'node'`, no DOM available in tests).

## Global Constraints

- No new visual identity (colors/fonts) — everything uses the existing Bootstrap styling already present in `landing/page.tsx` and `privacidade/page.tsx`. Do not introduce Playfair Display, DM Sans, or the `#0F5497`/`#7CB62E`/`#1B2B3B` palette.
- No Meta Pixel ID / Google Tag ID exists or is to be invented. `trackLead()`/`trackContact()` must be safe no-ops until real IDs are installed (out of scope for this plan).
- `consent_accepted_at` is always set from `Instant.now()` on the server — never trust a client-supplied timestamp.
- UTM cookie name is `em_utm`, 30-day expiry, `sameSite: 'Lax'` — same pattern as the existing `em_ref` affiliate cookie in `landing/page.tsx`.
- Frontend tests run under Jest with `testEnvironment: 'node'` (see `jest.config.js`) — there is no real `window`/`document`. Any test touching `window` must stub `global.window` manually; there is no React component test infrastructure in this project (documented precedent in multiple prior tasks) — do not attempt to render React components in tests.
- Backend validation errors use `RuleException` (→ HTTP 400 via the existing `GlobalExceptionHandler`), the same pattern used elsewhere in this codebase — do not invent a new exception type.

---

### Task 1: Backend — `consent_accepted_at` + mandatory consent validation

**Files:**
- Create: `easy-maintenance-api/src/main/resources/db/migration/V86__add_consent_accepted_at_to_landing_leads.sql`
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/domain/LandingLead.java`
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/application/dto/CreateLeadRequest.java`
- Modify: `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/application/service/LeadService.java`
- Test: `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/leads/application/service/LeadServiceTest.java` (new)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `POST /easy-maintenance/api/v1/landing/leads` now requires `"consentAccepted": true` in the body (400 `RuleException` otherwise); the saved `LandingLead` row gets `consent_accepted_at` set to the server instant. This is what Task 7 (frontend form) relies on.

- [ ] **Step 1: Write the failing tests**

Create `easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/leads/application/service/LeadServiceTest.java`:

```java
package com.brainbyte.easy_maintenance.leads.application.service;

import com.brainbyte.easy_maintenance.commons.exceptions.RuleException;
import com.brainbyte.easy_maintenance.leads.application.dto.CreateLeadRequest;
import com.brainbyte.easy_maintenance.leads.application.dto.LeadResponse;
import com.brainbyte.easy_maintenance.leads.domain.LandingLead;
import com.brainbyte.easy_maintenance.leads.infrastructure.persistence.LandingLeadRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LeadServiceTest {

    @Mock LandingLeadRepository repository;
    @Mock HttpServletRequest httpRequest;
    @InjectMocks LeadService service;

    @Test
    void createLead_savesConsentAcceptedAtFromServerClock_whenConsentIsTrue() {
        when(httpRequest.getRemoteAddr()).thenReturn("127.0.0.1");
        when(httpRequest.getHeader("User-Agent")).thenReturn("test-agent");
        when(repository.save(any())).thenAnswer(inv -> {
            LandingLead lead = inv.getArgument(0);
            lead.setId(1L);
            return lead;
        });

        CreateLeadRequest request = new CreateLeadRequest(
                "joao@test.com", "João", "google", "cpc", "lancamento",
                "https://google.com", "/landing", "{\"utm_source\":\"google\"}", null, true);

        Instant before = Instant.now();
        LeadResponse response = service.createLead(request, httpRequest);
        Instant after = Instant.now();

        assertThat(response.email()).isEqualTo("joao@test.com");
        verify(repository).save(argThat(lead ->
                lead.getConsentAcceptedAt() != null
                        && !lead.getConsentAcceptedAt().isBefore(before)
                        && !lead.getConsentAcceptedAt().isAfter(after)));
    }

    @Test
    void createLead_throwsRuleException_whenConsentIsFalse() {
        CreateLeadRequest request = new CreateLeadRequest(
                "joao@test.com", "João", null, null, null, null, null, null, null, false);

        assertThatThrownBy(() -> service.createLead(request, httpRequest))
                .isInstanceOf(RuleException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void createLead_throwsRuleException_whenConsentIsNull() {
        CreateLeadRequest request = new CreateLeadRequest(
                "joao@test.com", "João", null, null, null, null, null, null, null, null);

        assertThatThrownBy(() -> service.createLead(request, httpRequest))
                .isInstanceOf(RuleException.class);

        verify(repository, never()).save(any());
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd easy-maintenance-api && ./mvnw test -Dtest=LeadServiceTest`
Expected: compile error — `CreateLeadRequest` does not have a 10-argument constructor yet, and `LandingLead.getConsentAcceptedAt()` does not exist.

- [ ] **Step 3: Add the migration**

Create `easy-maintenance-api/src/main/resources/db/migration/V86__add_consent_accepted_at_to_landing_leads.sql`:

```sql
ALTER TABLE landing_leads ADD COLUMN consent_accepted_at TIMESTAMP NULL;
```

- [ ] **Step 4: Add the field to the entity**

In `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/domain/LandingLead.java`, add after the `status` field (before `createdAt`):

```java
    @Column(name = "consent_accepted_at")
    private Instant consentAcceptedAt;

```

- [ ] **Step 5: Add the field to the request DTO**

In `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/application/dto/CreateLeadRequest.java`, add as the last record component (after `affiliateCode`):

```java
    @Schema(description = "Código do afiliado que indicou o lead (opcional)", example = "ABC123")
    String affiliateCode,

    @Schema(description = "Indica se o lead aceitou a Política de Privacidade (obrigatório)", example = "true")
    Boolean consentAccepted
```

(replace the existing final line `String affiliateCode` + closing `)` with the block above, adding the comma and the new field before the closing `)`.)

- [ ] **Step 6: Enforce consent and set the server timestamp in the service**

In `easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/application/service/LeadService.java`, add the import and the check, and set the new field on the builder:

```java
import com.brainbyte.easy_maintenance.commons.exceptions.RuleException;
```

```java
    @Transactional
    public LeadResponse createLead(CreateLeadRequest request, HttpServletRequest httpRequest) {
        log.info("Creating new lead with email: {}", request.email());

        if (!Boolean.TRUE.equals(request.consentAccepted())) {
            throw new RuleException("É necessário aceitar a Política de Privacidade para enviar o formulário.");
        }

        LandingLead lead = LandingLead.builder()
                .email(request.email())
                .name(request.name())
                .source(request.source())
                .medium(request.medium())
                .campaign(request.campaign())
                .referrer(request.referrer())
                .landingPath(request.landingPath())
                .utmJson(request.utmJson())
                .affiliateCode(request.affiliateCode())
                .ip(httpRequest.getRemoteAddr())
                .userAgent(httpRequest.getHeader("User-Agent"))
                .status("NEW")
                .consentAcceptedAt(Instant.now())
                .build();

        LandingLead saved = repository.save(lead);

        return new LeadResponse(
                saved.getId(),
                saved.getEmail(),
                saved.getName(),
                saved.getStatus(),
                saved.getCreatedAt()
        );
    }
```

Also add `import java.time.Instant;` to `LeadService.java` if not already present.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `cd easy-maintenance-api && ./mvnw test -Dtest=LeadServiceTest`
Expected: PASS, 3/3.

- [ ] **Step 8: Run the full backend suite to check for regressions**

Run: `cd easy-maintenance-api && ./mvnw test`
Expected: PASS, no regressions vs. the baseline before this change.

- [ ] **Step 9: Commit**

```bash
git add easy-maintenance-api/src/main/resources/db/migration/V86__add_consent_accepted_at_to_landing_leads.sql easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/domain/LandingLead.java easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/application/dto/CreateLeadRequest.java easy-maintenance-api/src/main/java/com/brainbyte/easy_maintenance/leads/application/service/LeadService.java easy-maintenance-api/src/test/java/com/brainbyte/easy_maintenance/leads/application/service/LeadServiceTest.java
git commit -m "feat(leads): require LGPD consent and record consent_accepted_at server-side (TASK-152)"
```

---

### Task 2: Frontend — UTM capture/read library (`src/lib/utm.ts`)

**Files:**
- Create: `easy-maintenance-web/src/lib/utm.ts`
- Test: `easy-maintenance-web/src/lib/utm.test.ts`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `captureUtm(search: string): void` and `getStoredUtm(): UtmParams | undefined`, where `UtmParams = Partial<Record<'utm_source'|'utm_medium'|'utm_campaign'|'utm_content'|'utm_term', string>>`. Task 3 (`UtmCapture` component), Task 6 (`/obrigado` WhatsApp button) and Task 7 (landing form) all import from this module.

- [ ] **Step 1: Write the failing tests**

Create `easy-maintenance-web/src/lib/utm.test.ts`:

```ts
import Cookies from "js-cookie";
import { captureUtm, getStoredUtm } from "./utm";

jest.mock("js-cookie");

const mockedCookies = Cookies as jest.Mocked<typeof Cookies>;

describe("captureUtm", () => {
    afterEach(() => jest.clearAllMocks());

    it("saves all recognized utm params found in the URL", () => {
        captureUtm(
            "?utm_source=google&utm_medium=cpc&utm_campaign=lancamento&utm_content=ad1&utm_term=manutencao"
        );

        expect(mockedCookies.set).toHaveBeenCalledWith(
            "em_utm",
            JSON.stringify({
                utm_source: "google",
                utm_medium: "cpc",
                utm_campaign: "lancamento",
                utm_content: "ad1",
                utm_term: "manutencao",
            }),
            { expires: 30, sameSite: "Lax" }
        );
    });

    it("saves only the utm params present, ignoring unrelated query params", () => {
        captureUtm("?utm_source=meta&ref=ABC123");

        expect(mockedCookies.set).toHaveBeenCalledWith(
            "em_utm",
            JSON.stringify({ utm_source: "meta" }),
            { expires: 30, sameSite: "Lax" }
        );
    });

    it("does not write the cookie when the URL has no utm params", () => {
        captureUtm("?ref=ABC123");

        expect(mockedCookies.set).not.toHaveBeenCalled();
    });

    it("does not write the cookie for an empty query string", () => {
        captureUtm("");

        expect(mockedCookies.set).not.toHaveBeenCalled();
    });
});

describe("getStoredUtm", () => {
    afterEach(() => jest.clearAllMocks());

    it("returns the parsed utm object when the cookie exists", () => {
        mockedCookies.get.mockReturnValue(JSON.stringify({ utm_source: "google" }));

        expect(getStoredUtm()).toEqual({ utm_source: "google" });
    });

    it("returns undefined when the cookie does not exist", () => {
        mockedCookies.get.mockReturnValue(undefined);

        expect(getStoredUtm()).toBeUndefined();
    });

    it("returns undefined when the cookie value is malformed JSON", () => {
        mockedCookies.get.mockReturnValue("not-json");

        expect(getStoredUtm()).toBeUndefined();
    });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd easy-maintenance-web && npx jest src/lib/utm.test.ts`
Expected: FAIL — `Cannot find module './utm'`.

- [ ] **Step 3: Implement `src/lib/utm.ts`**

```ts
import Cookies from "js-cookie";

const UTM_COOKIE_NAME = "em_utm";
const UTM_COOKIE_EXPIRES_DAYS = 30;
const UTM_KEYS = ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"] as const;

export type UtmParams = Partial<Record<(typeof UTM_KEYS)[number], string>>;

/**
 * Reads utm_* params from a query string and persists them in the `em_utm`
 * cookie (30 days, same pattern as the existing `em_ref` affiliate cookie).
 * Never overwrites a stored value with an empty one — preserves first-touch
 * attribution across internal navigation that doesn't carry UTM params.
 */
export function captureUtm(search: string): void {
    const params = new URLSearchParams(search);
    const found: UtmParams = {};

    for (const key of UTM_KEYS) {
        const value = params.get(key);
        if (value) found[key] = value;
    }

    if (Object.keys(found).length === 0) return;

    Cookies.set(UTM_COOKIE_NAME, JSON.stringify(found), {
        expires: UTM_COOKIE_EXPIRES_DAYS,
        sameSite: "Lax",
    });
}

export function getStoredUtm(): UtmParams | undefined {
    const raw = Cookies.get(UTM_COOKIE_NAME);
    if (!raw) return undefined;

    try {
        return JSON.parse(raw) as UtmParams;
    } catch {
        return undefined;
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd easy-maintenance-web && npx jest src/lib/utm.test.ts`
Expected: PASS, 7/7.

- [ ] **Step 5: Commit**

```bash
git add easy-maintenance-web/src/lib/utm.ts easy-maintenance-web/src/lib/utm.test.ts
git commit -m "feat(landing): add UTM capture/read library with 30-day cookie persistence (TASK-153)"
```

---

### Task 3: Frontend — mount UTM capture on every page

**Files:**
- Create: `easy-maintenance-web/src/components/UtmCapture.tsx`
- Modify: `easy-maintenance-web/src/app/layout.tsx`

**Interfaces:**
- Consumes: `captureUtm` from `src/lib/utm.ts` (Task 2).
- Produces: nothing consumed by other tasks — this is a leaf wiring task.

- [ ] **Step 1: Create the component**

Create `easy-maintenance-web/src/components/UtmCapture.tsx`:

```tsx
"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";
import { captureUtm } from "@/lib/utm";

/**
 * Renders nothing. Re-runs on every route change (usePathname, not
 * useSearchParams — avoids the Suspense-boundary requirement) so UTM
 * params are captured on hard loads and client-side navigations alike.
 */
export default function UtmCapture() {
    const pathname = usePathname();

    useEffect(() => {
        if (typeof window === "undefined") return;
        captureUtm(window.location.search);
    }, [pathname]);

    return null;
}
```

- [ ] **Step 2: Mount it in the root layout**

In `easy-maintenance-web/src/app/layout.tsx`, add the import and mount it inside `Providers`, before `Shell`:

```tsx
import Shell from "@/components/Shell";
import Providers from "@/components/Providers";
import EnvironmentBanner from "@/components/layout/shared/EnvironmentBanner";
import UtmCapture from "@/components/UtmCapture";
```

```tsx
        <Providers>
            <EnvironmentBanner />
            <UtmCapture />
            <Shell>{children}</Shell>
        </Providers>
```

- [ ] **Step 3: Verify the build**

Run: `cd easy-maintenance-web && npm run build`
Expected: build succeeds with no new errors/warnings.

- [ ] **Step 4: Commit**

```bash
git add easy-maintenance-web/src/components/UtmCapture.tsx easy-maintenance-web/src/app/layout.tsx
git commit -m "feat(landing): mount UTM capture globally in the root layout (TASK-153)"
```

---

### Task 4: Frontend — conversion tracking stubs (`src/lib/tracking.ts`)

**Files:**
- Create: `easy-maintenance-web/src/lib/tracking.ts`
- Test: `easy-maintenance-web/src/lib/tracking.test.ts`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `trackLead(): void` and `trackContact(): void`. Task 6 (`/obrigado`) calls `trackLead()` on mount and `trackContact()` on its secondary WhatsApp button; Task 7 (landing form) calls `trackContact()` on the "Falar com Consultor" button.

- [ ] **Step 1: Write the failing tests**

Create `easy-maintenance-web/src/lib/tracking.test.ts`:

```ts
import { trackLead, trackContact } from "./tracking";

describe("trackLead", () => {
    afterEach(() => {
        // @ts-expect-error test-only global cleanup
        delete global.window;
    });

    it("does not throw when window is undefined (SSR)", () => {
        expect(() => trackLead()).not.toThrow();
    });

    it("does not throw when fbq/gtag are not installed yet", () => {
        // @ts-expect-error test-only global stub
        global.window = {};
        expect(() => trackLead()).not.toThrow();
    });

    it("calls fbq and gtag with the Lead event when both are installed", () => {
        const fbq = jest.fn();
        const gtag = jest.fn();
        // @ts-expect-error test-only global stub
        global.window = { fbq, gtag };

        trackLead();

        expect(fbq).toHaveBeenCalledWith("track", "Lead");
        expect(gtag).toHaveBeenCalledWith("event", "generate_lead");
    });
});

describe("trackContact", () => {
    afterEach(() => {
        // @ts-expect-error test-only global cleanup
        delete global.window;
    });

    it("does not throw when window is undefined (SSR)", () => {
        expect(() => trackContact()).not.toThrow();
    });

    it("calls fbq and gtag with the Contact event when both are installed", () => {
        const fbq = jest.fn();
        const gtag = jest.fn();
        // @ts-expect-error test-only global stub
        global.window = { fbq, gtag };

        trackContact();

        expect(fbq).toHaveBeenCalledWith("track", "Contact");
        expect(gtag).toHaveBeenCalledWith("event", "contact");
    });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd easy-maintenance-web && npx jest src/lib/tracking.test.ts`
Expected: FAIL — `Cannot find module './tracking'`.

- [ ] **Step 3: Implement `src/lib/tracking.ts`**

```ts
type Fbq = (...args: unknown[]) => void;
type Gtag = (...args: unknown[]) => void;

declare global {
    interface Window {
        fbq?: Fbq;
        gtag?: Gtag;
    }
}

// TODO(EPIC-018/TASK-156): instalar o Meta Pixel base e o Google tag base —
// pendente dos IDs reais (Douglas). Até lá, window.fbq/window.gtag não
// existem e as funções abaixo são no-ops seguros.

export function trackLead(): void {
    if (typeof window === "undefined") return;
    window.fbq?.("track", "Lead");
    window.gtag?.("event", "generate_lead");
}

export function trackContact(): void {
    if (typeof window === "undefined") return;
    window.fbq?.("track", "Contact");
    window.gtag?.("event", "contact");
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd easy-maintenance-web && npx jest src/lib/tracking.test.ts`
Expected: PASS, 5/5.

- [ ] **Step 5: Commit**

```bash
git add easy-maintenance-web/src/lib/tracking.ts easy-maintenance-web/src/lib/tracking.test.ts
git commit -m "feat(landing): add Lead/Contact tracking stubs, no-op until pixel IDs are installed (TASK-156)"
```

---

### Task 5: Frontend — allow anonymous access to `/obrigado`

**Files:**
- Modify: `easy-maintenance-web/src/components/Shell.tsx:22-31`

**Interfaces:**
- Consumes: nothing.
- Produces: `/obrigado` becomes reachable by anonymous visitors without redirect to `/login`. Task 6 depends on this being done first (otherwise the page it creates is unreachable for the exact audience it exists to serve).

- [ ] **Step 1: Edit the `isAuth` whitelist**

In `easy-maintenance-web/src/components/Shell.tsx`, change:

```tsx
  const isAuth = pathname?.endsWith("/login") ||
                 pathname?.endsWith("/auth/change-password") ||
                 pathname?.endsWith("/forgot-password") ||
                 pathname?.endsWith("/reset-password") ||
                 pathname?.endsWith("/select-organization") ||
                 pathname?.includes("/landing") ||
                 pathname?.startsWith("/checkout") ||
                 pathname?.startsWith("/onboarding") ||
                 pathname?.startsWith("/indicador") ||
                 pathname?.endsWith("/privacidade");
```

to:

```tsx
  const isAuth = pathname?.endsWith("/login") ||
                 pathname?.endsWith("/auth/change-password") ||
                 pathname?.endsWith("/forgot-password") ||
                 pathname?.endsWith("/reset-password") ||
                 pathname?.endsWith("/select-organization") ||
                 pathname?.includes("/landing") ||
                 pathname?.startsWith("/checkout") ||
                 pathname?.startsWith("/onboarding") ||
                 pathname?.startsWith("/indicador") ||
                 pathname?.endsWith("/privacidade") ||
                 pathname?.endsWith("/obrigado");
```

- [ ] **Step 2: Verify the build**

Run: `cd easy-maintenance-web && npm run build`
Expected: build succeeds (route doesn't exist yet, but the whitelist change alone compiles fine).

- [ ] **Step 3: Commit**

```bash
git add easy-maintenance-web/src/components/Shell.tsx
git commit -m "fix(shell): allow anonymous access to /obrigado (same class of bug as TASK-151) (TASK-155)"
```

---

### Task 6: Frontend — `/obrigado` page

**Files:**
- Create: `easy-maintenance-web/src/app/obrigado/page.tsx`
- Create: `easy-maintenance-web/src/app/obrigado/ObrigadoContent.tsx`

**Interfaces:**
- Consumes: `getStoredUtm` from `src/lib/utm.ts` (Task 2), `trackLead`/`trackContact` from `src/lib/tracking.ts` (Task 4), the `isAuth` fix from Task 5, and the existing `WhatsAppIcon` component (`@/components/icons/WhatsAppIcon`) and `Logo` component (`@/components/Logo`).
- Produces: route `/obrigado`, the redirect target Task 7's form pushes to.

- [ ] **Step 1: Create the client content component**

Create `easy-maintenance-web/src/app/obrigado/ObrigadoContent.tsx`:

```tsx
"use client";

import { useEffect } from "react";
import WhatsAppIcon from "@/components/icons/WhatsAppIcon";
import { getStoredUtm } from "@/lib/utm";
import { trackLead, trackContact } from "@/lib/tracking";

const WHATSAPP_NUMBER = "5531999826634";

function buildWhatsAppLink(): string {
    const utm = getStoredUtm();
    const campaignContext = utm?.utm_campaign
        ? ` Vim através da campanha "${utm.utm_campaign}".`
        : "";
    const message =
        `Olá, tudo bem? Acabei de solicitar uma demonstração no site da Easy Maintenance e ` +
        `gostaria de falar agora, se possível.${campaignContext}`;
    return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`;
}

export default function ObrigadoContent() {
    useEffect(() => {
        trackLead();
    }, []);

    return (
        <>
            <h1 className="fw-bold mb-3">Recebemos sua solicitação!</h1>
            <p className="text-muted mb-4">
                Obrigado pelo interesse na Easy Maintenance. Nossa equipe vai entrar em contato pelo
                e-mail informado em breve para agendar sua demonstração.
            </p>
            <p className="text-muted mb-4">
                Se preferir não esperar, fale agora mesmo com um consultor:
            </p>
            <a
                href={buildWhatsAppLink()}
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-success btn-lg rounded-pill px-4 d-inline-flex align-items-center gap-2"
                onClick={() => trackContact()}
            >
                <WhatsAppIcon size={22} />
                Falar agora no WhatsApp
            </a>
        </>
    );
}
```

- [ ] **Step 2: Create the page (server component, owns metadata)**

Create `easy-maintenance-web/src/app/obrigado/page.tsx`:

```tsx
import type { Metadata } from "next";
import Link from "next/link";
import Logo from "@/components/Logo";
import ObrigadoContent from "./ObrigadoContent";

export const metadata: Metadata = {
    title: "Obrigado pelo contato",
    description: "Recebemos sua solicitação de demonstração do Easy Maintenance.",
    robots: {
        index: false,
        follow: false,
    },
};

export default function ObrigadoPage() {
    return (
        <>
            <nav className="navbar navbar-light bg-white sticky-top shadow-sm">
                <div className="container">
                    <Link href="/landing" className="navbar-brand mb-0">
                        <Logo />
                    </Link>
                </div>
            </nav>
            <div className="container py-5 text-center" style={{ maxWidth: 640 }}>
                <ObrigadoContent />
                <div className="mt-5 pt-3 border-top">
                    <Link href="/landing" className="btn btn-outline-secondary btn-sm">
                        ← Voltar para o site
                    </Link>
                </div>
            </div>
        </>
    );
}
```

- [ ] **Step 3: Verify the build**

Run: `cd easy-maintenance-web && npm run build`
Expected: build succeeds; `/obrigado` appears in the route list with `noindex` metadata, not statically pre-rendered as indexable content.

- [ ] **Step 4: Manual check**

Run: `cd easy-maintenance-web && npm run dev`, open `http://localhost:3000/obrigado` in an incognito/anonymous browser window.
Expected: page renders (no redirect to `/login`), WhatsApp button opens `wa.me` with the pre-filled message.

- [ ] **Step 5: Commit**

```bash
git add easy-maintenance-web/src/app/obrigado/page.tsx easy-maintenance-web/src/app/obrigado/ObrigadoContent.tsx
git commit -m "feat(landing): add /obrigado confirmation page with Lead tracking + WhatsApp fallback (TASK-155)"
```

---

### Task 7: Frontend — consent checkbox + UTM payload + redirect on the demo form

**Files:**
- Modify: `easy-maintenance-web/src/app/landing/page.tsx`

**Interfaces:**
- Consumes: `getStoredUtm` from `src/lib/utm.ts` (Task 2), `trackContact` from `src/lib/tracking.ts` (Task 4), route `/obrigado` (Task 6), backend's now-required `consentAccepted` field (Task 1).
- Produces: nothing consumed by other tasks — this is the last task, it closes the loop.

- [ ] **Step 1: Add imports and consent state**

In `easy-maintenance-web/src/app/landing/page.tsx`, update the imports (after the existing `import Cookies from 'js-cookie';` line):

```tsx
import { useRouter } from 'next/navigation';
import { getStoredUtm } from '@/lib/utm';
import { trackContact } from '@/lib/tracking';
```

Update the component's state (replace the existing `const [email, setEmail] = useState('');` / `const [loading, setLoading] = useState(false);` block):

```tsx
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [consentChecked, setConsentChecked] = useState(false);
  const [consentError, setConsentError] = useState<string | null>(null);
```

- [ ] **Step 2: Update `handleSubmit`**

Replace the existing `handleSubmit`:

```tsx
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const affiliateCode = Cookies.get('em_ref') || undefined;
      await api.post('/landing/leads', { email, affiliateCode });
      alert(`Obrigado! Entraremos em contato através do e-mail: ${email}`);
      setEmail('');
    } catch (error) {
      console.error('Erro ao enviar lead:', error);
      alert('Ocorreu um erro ao enviar seu e-mail. Por favor, tente novamente mais tarde.');
    } finally {
      setLoading(false);
    }
  };
```

with:

```tsx
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!consentChecked) {
      setConsentError('É necessário concordar com a Política de Privacidade para continuar.');
      return;
    }
    setConsentError(null);
    setLoading(true);
    try {
      const affiliateCode = Cookies.get('em_ref') || undefined;
      const utm = getStoredUtm();
      await api.post('/landing/leads', {
        email,
        affiliateCode,
        consentAccepted: true,
        source: utm?.utm_source,
        medium: utm?.utm_medium,
        campaign: utm?.utm_campaign,
        utmJson: utm ? JSON.stringify(utm) : undefined,
        referrer: document.referrer || undefined,
        landingPath: window.location.pathname,
      });
      router.push('/obrigado');
    } catch (error) {
      console.error('Erro ao enviar lead:', error);
      alert('Ocorreu um erro ao enviar seu e-mail. Por favor, tente novamente mais tarde.');
    } finally {
      setLoading(false);
    }
  };
```

- [ ] **Step 3: Add the consent checkbox to the form JSX**

Replace the existing form block:

```tsx
              <form onSubmit={handleSubmit} className="row g-2">
                <div className="col-md-7">
                  <input
                    type="email"
                    className="form-control form-control-lg rounded-pill"
                    placeholder="Seu melhor e-mail"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div className="col-md-5">
                  <button
                    type="submit"
                    className="btn btn-primary btn-lg w-100 rounded-pill"
                    disabled={loading}
                  >
                    {loading ? 'Enviando...' : 'Solicitar Demonstração'}
                  </button>
                </div>
              </form>
```

with:

```tsx
              <form onSubmit={handleSubmit} className="row g-2">
                <div className="col-md-7">
                  <input
                    type="email"
                    className="form-control form-control-lg rounded-pill"
                    placeholder="Seu melhor e-mail"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div className="col-md-5">
                  <button
                    type="submit"
                    className="btn btn-primary btn-lg w-100 rounded-pill"
                    disabled={loading}
                  >
                    {loading ? 'Enviando...' : 'Solicitar Demonstração'}
                  </button>
                </div>
                <div className="col-12">
                  <div className="form-check">
                    <input
                      type="checkbox"
                      className="form-check-input"
                      id="consentCheckbox"
                      checked={consentChecked}
                      onChange={(e) => {
                        setConsentChecked(e.target.checked);
                        if (e.target.checked) setConsentError(null);
                      }}
                    />
                    <label className="form-check-label small" htmlFor="consentCheckbox">
                      Li e concordo com a{' '}
                      <Link href="/privacidade" target="_blank" className="text-decoration-underline text-white">
                        Política de Privacidade
                      </Link>
                      .
                    </label>
                  </div>
                  {consentError && (
                    <p className="text-danger small mb-0 mt-1">{consentError}</p>
                  )}
                </div>
              </form>
```

- [ ] **Step 4: Wire `trackContact` on the "Falar com Consultor" button**

Replace:

```tsx
            <a href={WHATSAPP_LINK} target="_blank" rel="noopener noreferrer" className="btn btn-outline-light btn-lg rounded-pill px-5">Falar com Consultor</a>
```

with:

```tsx
            <a
              href={WHATSAPP_LINK}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-outline-light btn-lg rounded-pill px-5"
              onClick={() => trackContact()}
            >
              Falar com Consultor
            </a>
```

- [ ] **Step 5: Run lint and build**

Run: `cd easy-maintenance-web && npm run lint && npm run build`
Expected: both succeed with no new errors.

- [ ] **Step 6: Manual end-to-end check**

Run: `cd easy-maintenance-web && npm run dev` (with the backend running locally, migrated to V86).
1. Open `http://localhost:3000/landing?utm_source=teste&utm_medium=cpc&utm_campaign=qa`.
2. Try submitting the form without checking consent → inline error shown, no network call fires.
3. Check consent, submit with a real-looking email → network tab shows `POST /landing/leads` with `consentAccepted: true` and `source`/`medium`/`campaign`/`utmJson` populated → browser redirects to `/obrigado`.
4. On `/obrigado`, click "Falar agora no WhatsApp" → opens `wa.me` with the campaign context in the message.

- [ ] **Step 7: Commit**

```bash
git add easy-maintenance-web/src/app/landing/page.tsx
git commit -m "feat(landing): require LGPD consent, send UTM on lead submit, redirect to /obrigado (TASK-154)"
```

---

## Post-implementation (not part of this plan)

- Douglas provides Meta Pixel ID / Google Tag ID → install the base pixel/gtag scripts and remove the `TODO` in `tracking.ts` (closes TASK-156 fully).
- TASK-157 (Meta Conversions API / Google Enhanced Conversions, server-side) stays in the backlog until credentials are available.
- "Termos de Uso" footer link remains broken (`href="#"`) — no content exists to link; flagged, not fixed, per EPIC-018 scope.
