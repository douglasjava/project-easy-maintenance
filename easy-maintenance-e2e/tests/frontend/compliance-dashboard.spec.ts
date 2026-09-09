import { test, expect } from '@playwright/test';
import { TENANT_C_ONBOARDING, TENANT_D_OPERATING, TENANT_E_PORTFOLIO } from '../../fixtures/tenant';
import { loginViaUi } from '../../helpers/frontend-login';

// EPIC-030/TASK-254: E2E coverage for the Compliance Dashboard (src/app/page.tsx).
// Depends on seed/e2e-seed.sql section 10 (3 scenario tenants — see that file's header comment
// for the exact item/maintenance counts and the compliance-index math each tenant is built to
// produce). Run `npm run setup:db` against a running e2e MySQL (docker-compose, port 3307) before
// this spec.
//
// NOT EXECUTED THIS SESSION: no e2e MySQL container was running and the API can't boot locally
// here (missing real FIREBASE_SERVICE_ACCOUNT_JSON — see EPIC-030/TASK-243). The seed SQL itself
// (section 10) WAS validated against a real MySQL 8.0.33 instance — item/maintenance counts and
// the compliance-index formula (ComplianceMetricsRepository's exact query) were confirmed to
// produce eligible/compliant = 2/2, 5/3, 2/1, 2/2, 2/2 for the 5 seeded orgs, matching the
// 60%/83%(portfolio) indexes this spec asserts on. Every selector below is read from the actual
// component source (ComplianceHero/OnboardingPanel/ActionQueue/ComplianceFilterBar/login page),
// not guessed — but the spec itself has never been run against a live app.
//
// Serial: the "postpone" test mutates tenant-d's seeded OVERDUE item (E2E_OPE_ITEM_4), which the
// "operating state" and "no horizontal scroll" tests also read. Keeping file order + serial mode
// avoids a state-dependent flake between them.
test.describe.configure({ mode: 'serial' });

test.describe('Compliance Dashboard — account states', () => {
  test('ONBOARDING: new account with < 5 items and 0 maintenances shows the onboarding checklist, not the compliance panel', async ({ page }) => {
    await loginViaUi(page, TENANT_C_ONBOARDING);
    await page.goto('/');

    await expect(page.getByRole('heading', { name: 'Primeiros passos' })).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Registre sua primeira manutenção')).toBeVisible();

    // ONBOARDING must never render the compliance ring/KPIs/action queue (no fabricated index).
    await expect(page.locator('svg[role="img"][aria-label*="Índice de conformidade"]')).toHaveCount(0);
    await expect(page.getByText('Fila de ações')).toHaveCount(0);
  });

  test('OPERATING: single company with real history shows the compliance hero, KPI tiles and the 2 seeded OVERDUE items in the action queue', async ({ page }) => {
    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/');

    // Single-org account -> ComplianceFilterBar's company <select> must NOT render.
    await expect(page.locator('select[aria-label="Filtrar por unidade"]')).toHaveCount(0);

    await expect(
      page.locator('svg[role="img"][aria-label="Índice de conformidade: 60%"]')
    ).toBeVisible({ timeout: 15_000 });

    await expect(page.getByText('Fila de ações')).toBeVisible();
    await expect(page.getByText('E2E_OPE_ITEM_4')).toBeVisible();
    await expect(page.getByText('E2E_OPE_ITEM_5')).toBeVisible();
    // Most-overdue-first ordering (DashboardActionsRepository: -DATEDIFF sort key).
    await expect(page.getByText('Venceu há 52 dias')).toBeVisible();
    await expect(page.getByText('Venceu há 14 dias')).toBeVisible();
  });

  test('PORTFOLIO: account with 3 accessible companies shows "Todas as unidades" and the units ranking, and switching company updates the URL', async ({ page }) => {
    await loginViaUi(page, TENANT_E_PORTFOLIO);
    // loginViaUi already landed on "/" via /select-organization (picked the first company there);
    // navigate to "/" with no ?company= so DashboardScopeResolver resolves PORTFOLIO (2+ orgs, no
    // companyCode) rather than the single org that page happened to select.
    await page.goto('/');

    const companySelect = page.locator('select[aria-label="Filtrar por unidade"]');
    await expect(companySelect).toBeVisible({ timeout: 15_000 });
    await expect(companySelect.locator('option').first()).toHaveText('Todas as unidades (3)');

    await expect(
      page.locator('svg[role="img"][aria-label="Índice de conformidade: 83%"]')
    ).toBeVisible();

    // unitsRanking (DashboardCharts) only renders for PORTFOLIO scope, worst unit first.
    await expect(page.getByText('E2E Org Portfolio 1')).toBeVisible();

    // Company filter is a URL query param (?company=<code>), never client-side re-derivation.
    await companySelect.selectOption({ label: 'E2E Org Portfolio 2' });
    await expect(page).toHaveURL(/[?&]company=ffffffff-ffff-ffff-ffff-ffffffffffff/);
  });
});

test.describe('Compliance Dashboard — action queue interactions', () => {
  test('Postpone dialog rejects submission without a reason, and a valid postpone removes the item from the queue and raises the index', async ({ page }) => {
    await loginViaUi(page, TENANT_D_OPERATING);
    await page.goto('/');

    const item4Row = page.locator('div').filter({ hasText: 'E2E_OPE_ITEM_4' }).last();
    await item4Row.getByRole('button', { name: 'Adiar' }).click();

    const dialog = page.getByRole('dialog');
    await expect(dialog).toBeVisible();

    const confirmButton = dialog.getByRole('button', { name: 'Confirmar' });
    // No reason typed yet -> Confirmar must stay disabled (client-side "reason is required" gate).
    await expect(confirmButton).toBeDisabled();

    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 60);
    const isoDate = futureDate.toISOString().slice(0, 10);

    await dialog.locator('input[type="date"]').fill(isoDate);
    // Date alone still isn't enough — reason is the required field this scenario is about.
    await expect(confirmButton).toBeDisabled();

    await dialog.locator('textarea').fill('Fornecedor sem disponibilidade essa semana — E2E');
    await expect(confirmButton).toBeEnabled();
    await confirmButton.click();

    await expect(dialog).toBeHidden({ timeout: 15_000 });
    // Postponed item leaves the OVERDUE queue; refetch (react-query invalidate) picks up the
    // new compliance index: 3/5 -> 4/5 compliant (item had no maintenance history, so it's
    // evidence-exempt per ComplianceMetricsRepository's has_evidence_flag rule) = 80%.
    await expect(page.getByText('Venceu há 52 dias')).toHaveCount(0, { timeout: 15_000 });
    await expect(
      page.locator('svg[role="img"][aria-label="Índice de conformidade: 80%"]')
    ).toBeVisible({ timeout: 15_000 });
  });
});

test.describe('Compliance Dashboard — responsive layout', () => {
  for (const width of [1280, 1920]) {
    test(`no horizontal body scroll at ${width}px wide`, async ({ page }) => {
      await page.setViewportSize({ width, height: 900 });
      await loginViaUi(page, TENANT_D_OPERATING);
      await page.goto('/');

      await expect(
        page.locator('svg[role="img"][aria-label*="Índice de conformidade"]')
      ).toBeVisible({ timeout: 15_000 });

      // Charts/action queue must scroll inside their own `overflow-x: auto` container, never the
      // page body (EPIC-030 acceptance criterion, TASK-252).
      const { scrollWidth, clientWidth } = await page.evaluate(() => ({
        scrollWidth: document.documentElement.scrollWidth,
        clientWidth: document.documentElement.clientWidth,
      }));
      expect(scrollWidth).toBeLessThanOrEqual(clientWidth);
    });
  }
});
