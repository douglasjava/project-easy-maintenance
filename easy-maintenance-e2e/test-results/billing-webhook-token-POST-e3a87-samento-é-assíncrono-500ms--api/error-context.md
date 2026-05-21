# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: billing\webhook-token.spec.ts >> POST /webhooks/asaas — validação de token >> resposta retornada imediatamente — processamento é assíncrono (< 500ms)
- Location: tests\billing\webhook-token.spec.ts:58:7

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: 200
Received: 401
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test';
  2  | import * as dotenv from 'dotenv';
  3  | 
  4  | dotenv.config({ path: '.env.e2e' });
  5  | 
  6  | const WEBHOOK_TOKEN = process.env.ASAAS_WEBHOOK_TOKEN ?? 'e2e-webhook-secret';
  7  | const WEBHOOK_PATH = '/easy-maintenance/api/v1/public/webhooks/asaas';
  8  | 
  9  | /** Minimal valid payload — dateCreated uses OffsetDateTime format parsed by DateUtils.parseEventDate */
  10 | function minimalPayload() {
  11 |   return {
  12 |     id: `evt-token-test-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
  13 |     event: 'PAYMENT_CREATED',
  14 |     dateCreated: '2026-04-24T03:00:00-03:00',
  15 |     payment: {
  16 |       id: 'pay_token_test',
  17 |       status: 'PENDING',
  18 |       billingType: 'CREDIT_CARD',
  19 |       externalReference: `e2e-token-ref-${Date.now()}`,
  20 |       value: 0.01,
  21 |       dueDate: '2026-04-30',
  22 |     },
  23 |   };
  24 | }
  25 | 
  26 | test.describe('POST /webhooks/asaas — validação de token', () => {
  27 |   test('token válido → HTTP 200', async ({ request }) => {
  28 |     const res = await request.post(WEBHOOK_PATH, {
  29 |       data: minimalPayload(),
  30 |       headers: { 'asaas-access-token': WEBHOOK_TOKEN },
  31 |     });
  32 |     expect(res.status()).toBe(200);
  33 |   });
  34 | 
  35 |   test('token inválido → HTTP 401', async ({ request }) => {
  36 |     const res = await request.post(WEBHOOK_PATH, {
  37 |       data: minimalPayload(),
  38 |       headers: { 'asaas-access-token': 'token-incorreto' },
  39 |     });
  40 |     expect(res.status()).toBe(401);
  41 |   });
  42 | 
  43 |   test('header ausente → HTTP 401', async ({ request }) => {
  44 |     const res = await request.post(WEBHOOK_PATH, {
  45 |       data: minimalPayload(),
  46 |     });
  47 |     expect(res.status()).toBe(401);
  48 |   });
  49 | 
  50 |   test('token em branco → HTTP 401', async ({ request }) => {
  51 |     const res = await request.post(WEBHOOK_PATH, {
  52 |       data: minimalPayload(),
  53 |       headers: { 'asaas-access-token': '   ' },
  54 |     });
  55 |     expect(res.status()).toBe(401);
  56 |   });
  57 | 
  58 |   test('resposta retornada imediatamente — processamento é assíncrono (< 500ms)', async ({ request }) => {
  59 |     const start = Date.now();
  60 |     const res = await request.post(WEBHOOK_PATH, {
  61 |       data: minimalPayload(),
  62 |       headers: { 'asaas-access-token': WEBHOOK_TOKEN },
  63 |     });
  64 |     const elapsed = Date.now() - start;
> 65 |     expect(res.status()).toBe(200);
     |                          ^ Error: expect(received).toBe(expected) // Object.is equality
  66 |     expect(elapsed).toBeLessThan(500);
  67 |   });
  68 | });
  69 | 
```