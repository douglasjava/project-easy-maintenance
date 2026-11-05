import { test, expect, APIRequestContext } from '@playwright/test';
import { loginAs, LoginResult } from '../../fixtures/auth';
import { TENANT_A, TENANT_B } from '../../fixtures/tenant';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

// ----------------------------------------------------------------
// TASK-292 / TASK-317 — autorização nas rotas do usuário comum.
//
// Duas partes:
//   1. REGRESSÃO — fluxos que o web usa e que precisam continuar funcionando (dono da organização,
//      membro da equipe e painel admin).
//   2. ISOLAMENTO — o usuário B (outro cliente) não pode ler/alterar nada da conta A pelas rotas do app.
//      Estas asserções descrevem o comportamento SEGURO: falham no código antigo (é a prova da falha).
//
// Cada teste é independente (um ataque bem-sucedido no código antigo não esconde os seguintes).
// A parte 2 tenta ataques que, no código antigo, ALTERAM dados: rode sobre um banco descartável
// (docker compose do e2e + npm run setup:db).
// ----------------------------------------------------------------

const API_V1 = '/easy-maintenance/api/v1';
const ADMIN_TOKEN = process.env.BOOTSTRAP_ADMIN_TOKEN ?? 'e2e-admin-token';
const ORG_A = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

// Cada falha reinicia o worker do Playwright (e o beforeAll); sem cache o login estoura o rate limit.
const TOKEN_CACHE = path.join(os.tmpdir(), 'em-e2e-org-access-tokens.json');

async function cachedLogin(request: APIRequestContext, key: string, email: string, password: string): Promise<LoginResult> {
  let cache: Record<string, { at: number; auth: LoginResult }> = {};
  try {
    cache = JSON.parse(fs.readFileSync(TOKEN_CACHE, 'utf-8'));
  } catch {
    /* sem cache */
  }
  const hit = cache[key];
  if (hit && Date.now() - hit.at < 20 * 60 * 1000) return hit.auth;
  const auth = await loginAs(request, email, password);
  cache[key] = { at: Date.now(), auth };
  fs.writeFileSync(TOKEN_CACHE, JSON.stringify(cache));
  return auth;
}

function bearer(auth: LoginResult, orgId?: string): Record<string, string> {
  const h: Record<string, string> = { Authorization: `Bearer ${auth.token}`, 'Content-Type': 'application/json' };
  if (orgId) h['X-Org-Id'] = orgId;
  return h;
}

async function myOrganizations(request: APIRequestContext, auth: LoginResult) {
  const res = await request.get(`${API_V1}/organizations/me/${auth.userId}`, { headers: bearer(auth) });
  expect(res.status(), await res.text()).toBe(200);
  return (await res.json()) as Array<{ organization: { id: number; code: string; name: string } }>;
}

async function adminUserOrgs(request: APIRequestContext, userId: number): Promise<string[]> {
  const res = await request.get(`${API_V1}/private/admin/users/${userId}/organizations`, {
    headers: { 'X-Admin-Token': ADMIN_TOKEN },
  });
  expect(res.status(), await res.text()).toBe(200);
  const body = (await res.json()) as Array<{ organization: { code: string } }>;
  const codes = body.map((o) => o.organization.code);
  expect(codes.length, 'o admin deve devolver as organizações do usuário').toBeGreaterThan(0);
  return codes;
}

test.describe('Organizações — regressão + isolamento', () => {
  let a: LoginResult;
  let b: LoginResult;
  let orgAId: number;

  test.beforeAll(async ({ request }) => {
    a = await cachedLogin(request, 'A', TENANT_A.adminEmail, TENANT_A.adminPassword);
    b = await cachedLogin(request, 'B', TENANT_B.adminEmail, TENANT_B.adminPassword);
    // Via admin: no código antigo o S10 consegue tirar o acesso de A à própria organização.
    const res = await request.get(`${API_V1}/private/admin/organizations?size=100`, { headers: { 'X-Admin-Token': ADMIN_TOKEN } });
    const body = await res.json();
    const list = (body.content ?? body) as Array<{ id: number; code: string }>;
    orgAId = list.find((o) => o.code === ORG_A)!.id;
  });

  // ============================================================ 1. REGRESSÃO (dono)

  test('R1 dono lista as próprias organizações (/organizations/me/{id})', async ({ request }) => {
    const orgs = await myOrganizations(request, a);
    expect(orgs.map((o) => o.organization.code)).toContain(ORG_A);
  });

  test('R2 dono edita a própria organização (PATCH /organizations/{id})', async ({ request }) => {
    const res = await request.patch(`${API_V1}/organizations/${orgAId}`, {
      headers: bearer(a, ORG_A),
      data: { name: 'E2E Org A', city: 'São Paulo', street: 'Rua Teste', number: '123', zipCode: '01000000',
        state: 'SP', neighborhood: 'Centro', country: 'BR', doc: '00000000000191' },
    });
    expect(res.status(), await res.text()).toBe(200);
  });

  test('R3 dono cria nova organização e se vincula (fluxo da tela /organizations/new)', async ({ request }) => {
    const code = crypto.randomUUID();
    const created = await request.post(`${API_V1}/organizations`, {
      headers: bearer(a),
      data: { code, name: `E2E Nova ${code.slice(0, 4)}`, city: 'São Paulo', doc: '11222333000181',
        companyType: 'CONDOMINIUM', plan: 'STARTER' },
    });
    expect([200, 201], await created.text()).toContain(created.status());

    const link = await request.post(`${API_V1}/organizations/${code}/users/${a.userId}`, { headers: bearer(a) });
    // 422 = limite de organizações do plano (regra de negócio, não autorização) — aceito nos dois lados.
    expect([200, 422], await link.text()).toContain(link.status());
    if (link.status() === 200) {
      expect((await myOrganizations(request, a)).map((o) => o.organization.code)).toContain(code);
    }
  });

  test('R4 dono gerencia a equipe (fluxo da tela /users: /me/team/users)', async ({ request }) => {
    const email = `e2e-membro-${Date.now()}@e2e.test`;
    const created = await request.post(`${API_V1}/me/team/users`, {
      headers: bearer(a, ORG_A),
      data: { email, name: 'E2E Membro', role: 'READER', orgCodes: [ORG_A] },
    });
    expect([200, 201], await created.text()).toContain(created.status());
    const memberId = (await created.json()).id;

    const list = await request.get(`${API_V1}/me/team/users`, { headers: bearer(a, ORG_A) });
    expect(list.status(), await list.text()).toBe(200);
    expect(((await list.json()) as Array<{ id: number }>).map((m) => m.id)).toContain(memberId);

    const upd = await request.patch(`${API_V1}/me/team/users/${memberId}`, {
      headers: bearer(a, ORG_A),
      data: { name: 'E2E Membro Editado', role: 'TECH', orgCodes: [ORG_A] },
    });
    expect(upd.status(), await upd.text()).toBe(200);
  });

  test('R4b perfil do próprio usuário: lê e edita (fluxo da tela /profile: /user/{id})', async ({ request }) => {
    const me = await request.get(`${API_V1}/user/${a.userId}`, { headers: bearer(a) });
    expect(me.status(), await me.text()).toBe(200);
    const profile = await me.json();
    const upd = await request.patch(`${API_V1}/user/${a.userId}`, {
      headers: bearer(a),
      data: { email: profile.email, name: 'E2E Admin A', role: profile.role, status: profile.status },
    });
    expect(upd.status(), await upd.text()).toBe(200);
    expect((await upd.json()).role).toBe(profile.role);
  });

  test('R5 telas de faturamento do usuário continuam respondendo', async ({ request }) => {
    for (const path of ['/me/billing/summary', '/me/billing/invoices', '/me/billing/plans']) {
      const res = await request.get(`${API_V1}${path}`, { headers: bearer(a, ORG_A) });
      expect([200, 204, 404], `${path}: ${await res.text()}`).toContain(res.status());
    }
  });

  test('R6 painel admin continua vendo tudo (rotas /private/admin)', async ({ request }) => {
    const headers = { 'X-Admin-Token': ADMIN_TOKEN };
    for (const path of ['/private/admin/organizations', '/private/admin/billing/accounts', `/private/admin/users/${b.userId}/organizations`]) {
      const res = await request.get(`${API_V1}${path}`, { headers });
      expect(res.status(), `${path}: ${await res.text()}`).toBe(200);
    }
    const noToken = await request.get(`${API_V1}/private/admin/organizations`);
    expect(noToken.status()).toBe(401);
  });

  // ============================================================ 2. ISOLAMENTO (B contra A)

  test('S1 rota removida: GET /me/billing/accounts não lista contas de outros clientes', async ({ request }) => {
    const res = await request.get(`${API_V1}/me/billing/accounts`, { headers: bearer(b, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') });
    expect([403, 404, 405]).toContain(res.status());
  });

  test('S2 B não lista todas as organizações (GET /organizations)', async ({ request }) => {
    const res = await request.get(`${API_V1}/organizations`, { headers: bearer(b, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') });
    expect([403, 404, 405]).toContain(res.status());
  });

  test('S3 B não lê a organização de A pelo id (GET /organizations/{id})', async ({ request }) => {
    const res = await request.get(`${API_V1}/organizations/${orgAId}`, { headers: bearer(b) });
    expect([403, 404, 405]).toContain(res.status());
  });

  test('S4 B não lista as organizações de A (GET /organizations/me/{idA})', async ({ request }) => {
    const res = await request.get(`${API_V1}/organizations/me/${a.userId}`, { headers: bearer(b) });
    expect(res.status()).toBe(403);
  });

  test('S5 B não edita a organização de A (PATCH /organizations/{idA})', async ({ request }) => {
    const res = await request.patch(`${API_V1}/organizations/${orgAId}`, {
      headers: bearer(b),
      data: { name: 'Invadida', doc: '00000000000191' },
    });
    expect(res.status()).toBe(403);
  });

  test('S6 B não lê nem altera a equipe de A pelas rotas antigas (/organizations/{codeA}/users)', async ({ request }) => {
    const blocked = [403, 404, 405];
    const list = await request.get(`${API_V1}/organizations/${ORG_A}/users`, { headers: bearer(b) });
    expect(blocked).toContain(list.status());
    const one = await request.get(`${API_V1}/organizations/${ORG_A}/users/${a.userId}`, { headers: bearer(b) });
    expect(blocked).toContain(one.status());
    const upd = await request.patch(`${API_V1}/organizations/${ORG_A}/users/${a.userId}`, {
      headers: bearer(b),
      data: { name: 'Sequestrado', role: 'ADMIN', status: 'ACTIVE', email: TENANT_A.adminEmail },
    });
    expect(blocked).toContain(upd.status());
    const add = await request.post(`${API_V1}/organizations/${ORG_A}/users`, {
      headers: bearer(b),
      data: { email: `intruso-${Date.now()}@e2e.test`, name: 'Intruso', role: 'ADMIN', status: 'ACTIVE', password: 'Intruso1!' },
    });
    expect(blocked).toContain(add.status());
  });

  test('S12 B não lê nem edita o perfil de A, nem se promove pelo próprio perfil (/user/{id})', async ({ request }) => {
    const read = await request.get(`${API_V1}/user/${a.userId}`, { headers: bearer(b) });
    expect(read.status()).toBe(403);
    const write = await request.patch(`${API_V1}/user/${a.userId}`, {
      headers: bearer(b),
      data: { email: TENANT_A.adminEmail, name: 'Sequestrado', role: 'ADMIN', status: 'INACTIVE' },
    });
    expect(write.status()).toBe(403);

    // O próprio perfil não troca papel/status (quem muda é o dono da equipe ou o admin).
    const mine = await (await request.get(`${API_V1}/user/${b.userId}`, { headers: bearer(b) })).json();
    const other = mine.role === 'READER' ? 'ADMIN' : 'READER';
    const self = await request.patch(`${API_V1}/user/${b.userId}`, {
      headers: bearer(b),
      data: { email: mine.email, name: mine.name, role: other, status: mine.status },
    });
    expect(self.status(), await self.text()).toBe(200);
    expect((await self.json()).role).toBe(mine.role);
  });

  test('S7 B não lê a assinatura da organização de A (GET /organizations/{codeA}/subscription)', async ({ request }) => {
    const res = await request.get(`${API_V1}/organizations/${ORG_A}/subscription`, { headers: bearer(b) });
    expect([403, 404, 405]).toContain(res.status());
  });

  test('S8 B não se vincula à organização de A (POST /organizations/{codeA}/users/{idB})', async ({ request }) => {
    const res = await request.post(`${API_V1}/organizations/${ORG_A}/users/${b.userId}`, { headers: bearer(b) });
    expect(res.status()).toBe(403);
    expect(await adminUserOrgs(request, b.userId)).not.toContain(ORG_A);
  });

  test('S9 B não vincula organização a outro usuário (POST /organizations/{codeB}/users/{idA})', async ({ request }) => {
    const res = await request.post(`${API_V1}/organizations/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/users/${a.userId}`, { headers: bearer(b) });
    expect(res.status()).toBe(403);
  });

  test('S10 B não remove o acesso de A (DELETE /organizations/{codeA}/users/{idA})', async ({ request }) => {
    const res = await request.delete(`${API_V1}/organizations/${ORG_A}/users/${a.userId}`, { headers: bearer(b) });
    expect([403, 404, 405]).toContain(res.status());
    expect(await adminUserOrgs(request, a.userId)).toContain(ORG_A);
  });

  test('S11 PUT /organizations/{code}/subscription não emite sessão de outro usuário', async ({ request }) => {
    const res = await request.put(`${API_V1}/organizations/${crypto.randomUUID()}/subscription`, {
      headers: bearer(b),
      data: { payerUserId: a.userId, planCode: 'STARTER', paymentMethod: 'PIX' },
    });
    expect([403, 404, 405]).toContain(res.status());
    expect(res.headers()['set-cookie'] ?? '').not.toContain('accessToken');
  });
});
