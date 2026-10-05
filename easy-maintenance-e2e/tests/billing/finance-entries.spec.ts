import { test, expect } from '@playwright/test';
import { loginAs, LoginResult } from '../../fixtures/auth';
import { TENANT_A } from '../../fixtures/tenant';
import { api } from '../../fixtures/api-client';

// EPIC-032: fluxo completo do módulo financeiro contra uma API real -- lança receita e despesa
// manuais, confere que a listagem e o resumo (/finance/summary) refletem os valores certos, e que
// cancelar um lançamento some da listagem ativa e do resumo. Segue o mesmo padrão de
// tests/auth/multi-tenant-isolation.spec.ts (API-level via loginAs + api fixture, não browser UI --
// este repo não tem helper de login via navegador).
test.describe('Financeiro — EPIC-032', () => {
  let auth: LoginResult;
  let start: string;
  let end: string;

  test.beforeAll(async ({ request }) => {
    auth = await loginAs(request, TENANT_A.adminEmail, TENANT_A.adminPassword);

    const today = new Date();
    const past = new Date();
    past.setDate(past.getDate() - 1);
    start = past.toISOString().split('T')[0];
    end = today.toISOString().split('T')[0];
  });

  test('cria receita e despesa, reflete na listagem e no resumo', async ({ request }) => {
    const revenueRes = await api.post(request, '/finance/entries', auth, {
      type: 'REVENUE',
      category: 'TAXA_CONDOMINIAL',
      amountCents: 50000,
      description: 'E2E taxa condominial',
      entryDate: end,
    });
    expect(revenueRes.status()).toBe(201);

    const expenseRes = await api.post(request, '/finance/entries', auth, {
      type: 'EXPENSE',
      category: 'CONTA_CONSUMO',
      amountCents: 8000,
      description: 'E2E conta de luz',
      entryDate: end,
    });
    expect(expenseRes.status()).toBe(201);

    const listRes = await request.get(
      `/easy-maintenance/api/v1/finance/entries?start=${start}&end=${end}&size=100`,
      { headers: { Authorization: `Bearer ${auth.token}`, 'X-Org-Id': auth.orgId } },
    );
    expect(listRes.status()).toBe(200);
    const listBody = await listRes.json();
    const descriptions = listBody.content.map((e: { description: string }) => e.description);
    expect(descriptions).toContain('E2E taxa condominial');
    expect(descriptions).toContain('E2E conta de luz');

    const summaryRes = await request.get(
      `/easy-maintenance/api/v1/finance/summary?start=${start}&end=${end}`,
      { headers: { Authorization: `Bearer ${auth.token}`, 'X-Org-Id': auth.orgId } },
    );
    expect(summaryRes.status()).toBe(200);
    const summary = await summaryRes.json();
    expect(summary.totalRevenueCents).toBeGreaterThanOrEqual(50000);
    expect(summary.totalManualExpenseCents).toBeGreaterThanOrEqual(8000);
  });

  test('cancelar lançamento remove da listagem ativa e do resumo', async ({ request }) => {
    const createRes = await api.post(request, '/finance/entries', auth, {
      type: 'REVENUE',
      category: 'MULTA',
      amountCents: 3000,
      description: 'E2E multa a cancelar',
      entryDate: end,
    });
    expect(createRes.status()).toBe(201);
    const created = await createRes.json();

    const summaryBefore = await request.get(
      `/easy-maintenance/api/v1/finance/summary?start=${start}&end=${end}`,
      { headers: { Authorization: `Bearer ${auth.token}`, 'X-Org-Id': auth.orgId } },
    );
    const revenueBefore = (await summaryBefore.json()).totalRevenueCents;

    const cancelRes = await api.post(request, `/finance/entries/${created.id}/cancel`, auth, {
      reason: 'Lançado em duplicidade por engano (E2E)',
    });
    expect(cancelRes.status()).toBe(204);

    const listRes = await request.get(
      `/easy-maintenance/api/v1/finance/entries?start=${start}&end=${end}&size=100`,
      { headers: { Authorization: `Bearer ${auth.token}`, 'X-Org-Id': auth.orgId } },
    );
    const listBody = await listRes.json();
    const ids = listBody.content.map((e: { id: number }) => e.id);
    expect(ids).not.toContain(created.id);

    const summaryAfter = await request.get(
      `/easy-maintenance/api/v1/finance/summary?start=${start}&end=${end}`,
      { headers: { Authorization: `Bearer ${auth.token}`, 'X-Org-Id': auth.orgId } },
    );
    const revenueAfter = (await summaryAfter.json()).totalRevenueCents;
    expect(revenueAfter).toBe(revenueBefore - 3000);

    const cancelAgainRes = await api.post(request, `/finance/entries/${created.id}/cancel`, auth, {
      reason: 'Segunda tentativa de cancelamento (E2E)',
    });
    expect(cancelAgainRes.status()).toBe(409);
  });
});
