import { test, expect } from '@playwright/test';
import * as dotenv from 'dotenv';

dotenv.config({ path: '.env.e2e' });

const WEBHOOK_TOKEN = process.env.ASAAS_WEBHOOK_TOKEN ?? 'e2e-webhook-secret';
const WEBHOOK_PATH = '/easy-maintenance/api/v1/public/webhooks/asaas';

/** Minimal valid payload — dateCreated uses OffsetDateTime format parsed by DateUtils.parseEventDate */
function minimalPayload() {
  return {
    id: `evt-token-test-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    event: 'PAYMENT_CREATED',
    dateCreated: '2026-04-24T03:00:00-03:00',
    payment: {
      id: 'pay_token_test',
      status: 'PENDING',
      billingType: 'CREDIT_CARD',
      externalReference: `e2e-token-ref-${Date.now()}`,
      value: 0.01,
      dueDate: '2026-04-30',
    },
  };
}

test.describe('POST /webhooks/asaas — validação de token', () => {
  test('token válido → HTTP 200', async ({ request }) => {
    const res = await request.post(WEBHOOK_PATH, {
      data: minimalPayload(),
      headers: { 'asaas-access-token': WEBHOOK_TOKEN },
    });
    expect(res.status()).toBe(200);
  });

  test('token inválido → HTTP 401', async ({ request }) => {
    const res = await request.post(WEBHOOK_PATH, {
      data: minimalPayload(),
      headers: { 'asaas-access-token': 'token-incorreto' },
    });
    expect(res.status()).toBe(401);
  });

  test('header ausente → HTTP 401', async ({ request }) => {
    const res = await request.post(WEBHOOK_PATH, {
      data: minimalPayload(),
    });
    expect(res.status()).toBe(401);
  });

  test('token em branco → HTTP 401', async ({ request }) => {
    const res = await request.post(WEBHOOK_PATH, {
      data: minimalPayload(),
      headers: { 'asaas-access-token': '   ' },
    });
    expect(res.status()).toBe(401);
  });

  test('resposta retornada imediatamente — processamento é assíncrono (< 500ms)', async ({ request }) => {
    const start = Date.now();
    const res = await request.post(WEBHOOK_PATH, {
      data: minimalPayload(),
      headers: { 'asaas-access-token': WEBHOOK_TOKEN },
    });
    const elapsed = Date.now() - start;
    expect(res.status()).toBe(200);
    expect(elapsed).toBeLessThan(500);
  });
});
