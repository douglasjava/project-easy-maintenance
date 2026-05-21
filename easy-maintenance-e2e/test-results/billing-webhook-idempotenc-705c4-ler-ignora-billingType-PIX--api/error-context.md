# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: billing\webhook-idempotency.spec.ts >> POST /webhooks/asaas — idempotência e campos PIX >> PAYMENT_CREATED CREDIT_CARD → campos PIX não são alterados (handler ignora billingType != PIX)
- Location: tests\billing\webhook-idempotency.spec.ts:133:7

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: 200
Received: 401
```

# Test source

```ts
  42  |     payment,
  43  |   };
  44  | }
  45  | 
  46  | function pixPayment(eventId: string, externalRef: string): ReturnType<typeof buildPayload> {
  47  |   return buildPayload(eventId, {
  48  |     id: `pay_asaas_${eventId}`,
  49  |     status: 'PENDING',
  50  |     billingType: 'PIX',
  51  |     externalReference: externalRef,
  52  |     value: 99.90,
  53  |     dueDate: '2026-04-30',
  54  |     invoiceUrl: 'https://asaas.com/invoice/e2e-test',
  55  |     transactionReceiptUrl: null,
  56  |     pixTransaction: {
  57  |       id: 'pix-txn-e2e-001',
  58  |       qrCode: {
  59  |         encodedImage: E2E_PIX_IMAGE_B64,
  60  |         payload: E2E_PIX_PAYLOAD,
  61  |         expirationDate: E2E_PIX_EXPIRATION,
  62  |       },
  63  |     },
  64  |   });
  65  | }
  66  | 
  67  | function creditCardPayload(eventId: string, externalRef: string): ReturnType<typeof buildPayload> {
  68  |   return buildPayload(eventId, {
  69  |     id: `pay_asaas_${eventId}`,
  70  |     status: 'PENDING',
  71  |     billingType: 'CREDIT_CARD',
  72  |     externalReference: externalRef,
  73  |     value: 99.90,
  74  |     dueDate: '2026-04-30',
  75  |   });
  76  | }
  77  | 
  78  | test.describe('POST /webhooks/asaas — idempotência e campos PIX', () => {
  79  |   test('mesmo providerEventId enviado duas vezes → apenas 1 registro no banco (sem duplicação)', async ({ request }) => {
  80  |     const eventId = `evt-idem-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  81  |     const payload = creditCardPayload(eventId, `e2e-idem-ref-${Date.now()}`);
  82  | 
  83  |     // First delivery
  84  |     const r1 = await request.post(WEBHOOK_PATH, {
  85  |       data: payload,
  86  |       headers: { 'asaas-access-token': WEBHOOK_TOKEN },
  87  |     });
  88  |     expect(r1.status()).toBe(200);
  89  | 
  90  |     // Wait for async processing to store the event
  91  |     await pollUntil(
  92  |       () => countWebhookEvents(eventId),
  93  |       count => count >= 1,
  94  |       { timeout: 5000 },
  95  |     );
  96  | 
  97  |     // Second delivery with identical payload and same eventId
  98  |     const r2 = await request.post(WEBHOOK_PATH, {
  99  |       data: payload,
  100 |       headers: { 'asaas-access-token': WEBHOOK_TOKEN },
  101 |     });
  102 |     expect(r2.status()).toBe(200);
  103 | 
  104 |     // Wait briefly for the second async check to run, then verify exactly 1 row
  105 |     await new Promise(r => setTimeout(r, 1000));
  106 |     const count = await countWebhookEvents(eventId);
  107 |     expect(count).toBe(1);
  108 |   });
  109 | 
  110 |   test('PAYMENT_CREATED PIX com pixTransaction preenchido → pixQrCode e pixExpiresAt populados no payment', async ({ request }) => {
  111 |     const eventId = `evt-pix-fields-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  112 |     const payload = pixPayment(eventId, PIX_SEED_EXTERNAL_REF);
  113 | 
  114 |     const res = await request.post(WEBHOOK_PATH, {
  115 |       data: payload,
  116 |       headers: { 'asaas-access-token': WEBHOOK_TOKEN },
  117 |     });
  118 |     expect(res.status()).toBe(200);
  119 | 
  120 |     // Poll until PaymentCreatedHandler finishes updating the payment
  121 |     const pix = await pollUntil(
  122 |       () => getPaymentPix(PIX_SEED_EXTERNAL_REF),
  123 |       p => p?.pix_qr_code !== null && p?.pix_qr_code !== undefined,
  124 |       { timeout: 6000, interval: 400 },
  125 |     );
  126 | 
  127 |     expect(pix).not.toBeNull();
  128 |     expect(pix!.pix_qr_code).toBe(E2E_PIX_PAYLOAD);
  129 |     expect(pix!.pix_qr_code_base64).toBe(E2E_PIX_IMAGE_B64);
  130 |     expect(pix!.pix_expires_at).not.toBeNull();
  131 |   });
  132 | 
  133 |   test('PAYMENT_CREATED CREDIT_CARD → campos PIX não são alterados (handler ignora billingType != PIX)', async ({ request }) => {
  134 |     // Uses a non-existent externalReference so no payment is found — verifies handler does not crash
  135 |     const eventId = `evt-cc-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  136 |     const payload = creditCardPayload(eventId, `e2e-cc-noop-ref-${Date.now()}`);
  137 | 
  138 |     const res = await request.post(WEBHOOK_PATH, {
  139 |       data: payload,
  140 |       headers: { 'asaas-access-token': WEBHOOK_TOKEN },
  141 |     });
> 142 |     expect(res.status()).toBe(200);
      |                          ^ Error: expect(received).toBe(expected) // Object.is equality
  143 | 
  144 |     // Wait for async — verify event was stored (no exception propagated)
  145 |     const count = await pollUntil(
  146 |       () => countWebhookEvents(eventId),
  147 |       c => c >= 1,
  148 |       { timeout: 5000 },
  149 |     );
  150 |     expect(count).toBe(1);
  151 |   });
  152 | 
  153 |   test('PAYMENT_CREATED PIX com pixTransaction nulo → HTTP 200, sem erro 500 (handler robusto)', async ({ request }) => {
  154 |     const eventId = `evt-pix-null-txn-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  155 |     const payload = buildPayload(eventId, {
  156 |       id: `pay_asaas_${eventId}`,
  157 |       status: 'PENDING',
  158 |       billingType: 'PIX',
  159 |       externalReference: `e2e-null-pix-txn-${Date.now()}`,
  160 |       value: 99.90,
  161 |       dueDate: '2026-04-30',
  162 |       pixTransaction: null,
  163 |     });
  164 | 
  165 |     const res = await request.post(WEBHOOK_PATH, {
  166 |       data: payload,
  167 |       headers: { 'asaas-access-token': WEBHOOK_TOKEN },
  168 |     });
  169 |     expect(res.status()).toBe(200);
  170 |   });
  171 | });
  172 | 
```