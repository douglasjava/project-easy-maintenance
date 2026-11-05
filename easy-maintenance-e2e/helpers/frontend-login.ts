import { Page, expect } from '@playwright/test';
import { TenantConfig } from '../fixtures/tenant';

// EPIC-030/TASK-254: first UI-project helper in this repo — the `ui` Playwright project
// (playwright.config.ts) previously had no spec files at all. Drives the real login form
// (src/app/login/page.tsx: input[name=email]/input[name=password], button text "Entrar")
// instead of injecting localStorage directly, since that page is the only place these E2E
// accounts' JWT actually gets minted.
//
// Login redirect depends on how many orgs the account has (src/app/login/page.tsx):
//   - exactly 1 org  -> redirects straight to "/"
//   - 2+ orgs        -> redirects to "/select-organization", which has no "todas as unidades"
//     option (that concept only exists inside the new dashboard's own filter bar) — so for
//     multi-org tenants this helper clicks the first company row to reach "/", then the caller
//     navigates back to "/" without a `company` query param to see the PORTFOLIO scope.
export async function loginViaUi(page: Page, tenant: TenantConfig): Promise<void> {
  await page.goto('/login');
  await page.locator('input[name="email"]').fill(tenant.adminEmail);
  await page.locator('input[name="password"]').fill(tenant.adminPassword);
  await page.getByRole('button', { name: 'Entrar' }).click();

  await page.waitForURL((url) => {
    const path = url.pathname;
    return path === '/' || path === '/select-organization';
  }, { timeout: 15_000 });

  if (page.url().includes('/select-organization')) {
    await expect(page.locator('.list-group-item').first()).toBeVisible({ timeout: 15_000 });
    await page.locator('.list-group-item').first().click();
    await page.waitForURL((url) => url.pathname === '/', { timeout: 15_000 });
  }
}
