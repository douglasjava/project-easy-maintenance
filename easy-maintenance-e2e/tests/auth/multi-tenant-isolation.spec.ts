import { test, expect } from '@playwright/test';
import { loginAs } from '../../fixtures/auth';
import { TENANT_A, TENANT_B } from '../../fixtures/tenant';
import { api } from '../../fixtures/api-client';

// ----------------------------------------------------------------
// Multi-tenant isolation — TASK-E2E-002
//
// Seeds (npm run setup:db):
//   Org-A = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa  (2 items)
//   Org-B = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb  (1 item)
// ----------------------------------------------------------------

test.describe('Multi-tenant isolation', () => {
  let tokenA: string;
  let orgIdA: string;
  let tokenB: string;
  let orgIdB: string;

  test.beforeAll(async ({ request }) => {
    const authA = await loginAs(request, TENANT_A.adminEmail, TENANT_A.adminPassword);
    tokenA = authA.token;
    orgIdA = authA.orgId;

    const authB = await loginAs(request, TENANT_B.adminEmail, TENANT_B.adminPassword);
    tokenB = authB.token;
    orgIdB = authB.orgId;
  });

  // ------------------------------------------------------------
  // Cross-tenant access → 403
  // ------------------------------------------------------------

  test.describe('Cross-tenant requests return 403', () => {
    test('GET /items with token-A but X-Org-Id of Org-B → 403', async ({ request }) => {
      const fakeAuth = { token: tokenA, orgId: orgIdB, userId: 0, email: '' };
      const res = await api.get(request, '/items', fakeAuth);
      expect(res.status()).toBe(403);
    });

    test('POST /items with token-A but X-Org-Id of Org-B → 403', async ({ request }) => {
      const fakeAuth = { token: tokenA, orgId: orgIdB, userId: 0, email: '' };
      const res = await api.post(request, '/items', fakeAuth, {
        name: 'should not be created',
        itemType: 'OTHER',
        itemCategory: 'OPERATIONAL',
        customPeriodUnit: 'MESES',
        customPeriodQty: 1,
      });
      expect(res.status()).toBe(403);
    });

    test('DELETE /items/{id} with token-A but X-Org-Id of Org-B → 403', async ({ request }) => {
      const fakeAuth = { token: tokenA, orgId: orgIdB, userId: 0, email: '' };
      const res = await api.delete(request, '/items/99999', fakeAuth);
      expect([403, 404]).toContain(res.status());
    });
  });

  // ------------------------------------------------------------
  // Missing or malformed X-Org-Id → 400
  // ------------------------------------------------------------

  test.describe('Missing or malformed X-Org-Id returns 400', () => {
    test('GET /items without X-Org-Id header → 400', async ({ request }) => {
      const res = await request.get('/easy-maintenance/api/v1/items', {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(res.status()).toBe(400);
    });

    test('GET /items with non-UUID X-Org-Id → 400', async ({ request }) => {
      const res = await request.get('/easy-maintenance/api/v1/items', {
        headers: {
          Authorization: `Bearer ${tokenA}`,
          'X-Org-Id': 'not-a-valid-uuid',
        },
      });
      expect(res.status()).toBe(400);
    });
  });

  // ------------------------------------------------------------
  // Unauthenticated access → 401 or 403
  // ------------------------------------------------------------

  test('GET /items without token → 401', async ({ request }) => {
    const res = await request.get('/easy-maintenance/api/v1/items', {
      headers: { 'X-Org-Id': orgIdA },
    });
    expect([401, 403]).toContain(res.status());
  });

  // ------------------------------------------------------------
  // Happy path (correct tenant) → 200
  // ------------------------------------------------------------

  test.describe('Correct tenant returns 200', () => {
    test('GET /items with valid token-A and X-Org-Id-A → 200', async ({ request }) => {
      const authA = { token: tokenA, orgId: orgIdA, userId: 0, email: '' };
      const res = await api.get(request, '/items', authA);
      expect(res.status()).toBe(200);
    });

    test('GET /items with valid token-B and X-Org-Id-B → 200', async ({ request }) => {
      const authB = { token: tokenB, orgId: orgIdB, userId: 0, email: '' };
      const res = await api.get(request, '/items', authB);
      expect(res.status()).toBe(200);
    });
  });

  // ------------------------------------------------------------
  // Data isolation — Org-A must not see Org-B items
  // ------------------------------------------------------------

  test.describe('Data isolation between tenants', () => {
    test('GET /items for Org-A returns only Org-A items (E2E_ITEM_A_*)', async ({ request }) => {
      const authA = { token: tokenA, orgId: orgIdA, userId: 0, email: '' };
      const res = await api.get(request, '/items', authA);
      expect(res.status()).toBe(200);

      const body = await res.json();
      const items: Array<{ itemType: string }> = body.content ?? body.items ?? body ?? [];
      const types = items.map((i) => i.itemType);

      expect(types.some((t) => t.startsWith('E2E_ITEM_A_'))).toBe(true);
      expect(types.every((t) => !t.startsWith('E2E_ITEM_B_'))).toBe(true);
    });

    test('GET /items for Org-B returns only Org-B items (E2E_ITEM_B_*)', async ({ request }) => {
      const authB = { token: tokenB, orgId: orgIdB, userId: 0, email: '' };
      const res = await api.get(request, '/items', authB);
      expect(res.status()).toBe(200);

      const body = await res.json();
      const items: Array<{ itemType: string }> = body.content ?? body.items ?? body ?? [];
      const types = items.map((i) => i.itemType);

      expect(types.some((t) => t.startsWith('E2E_ITEM_B_'))).toBe(true);
      expect(types.every((t) => !t.startsWith('E2E_ITEM_A_'))).toBe(true);
    });
  });
});
