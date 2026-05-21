import { test, expect } from '@playwright/test';
import * as dotenv from 'dotenv';
import { countWebhookEvents, getPaymentPix, pollUntil } from '../../helpers/db';

dotenv.config({ path: '.env.e2e' });

const WEBHOOK_TOKEN = process.env.ASAAS_WEBHOOK_TOKEN ?? 'e2e-webhook-secret';
const WEBHOOK_PATH = '/easy-maintenance/api/v1/public/webhooks/asaas';

// QR Code data injected via webhook — matches what PaymentCreatedHandler reads from pixTransaction.qrCode
const E2E_PIX_PAYLOAD    = '00020126580014BR.GOV.BCB.PIX0136e2e-qr-payload-test-easy-maintenance';
const E2E_PIX_IMAGE_B64  = 'aW1hZ2VfYmFzZTY0X2UyZV9wbGFjZWhvbGRlcg==';
const E2E_PIX_EXPIRATION = '2026-04-30T23:59:59';

// Seed payment referenced by the PIX test — created by npm run setup:db (seed/e2e-seed.sql section 9)
const PIX_SEED_EXTERNAL_REF = 'e2e-pix-ref-001';

type PaymentObject = {
  id: string;
  status: string;
  billingType: string;
  externalReference: string;
  value: number;
  dueDate: string;
  invoiceUrl?: string;
  transactionReceiptUrl?: null;
  pixTransaction?: {
    id: string;
    qrCode: {
      encodedImage: string;
      payload: string;
      expirationDate: string;
    };
  } | null;
};

function buildPayload(eventId: string, payment: PaymentObject) {
  return {
    id: eventId,
    event: 'PAYMENT_CREATED',
    dateCreated: '2026-04-24T03:00:00-03:00',
    payment,
  };
}

function pixPayment(eventId: string, externalRef: string): ReturnType<typeof buildPayload> {
  return buildPayload(eventId, {
    id: `pay_asaas_${eventId}`,
    status: 'PENDING',
    billingType: 'PIX',
    externalReference: externalRef,
    value: 99.90,
    dueDate: '2026-04-30',
    invoiceUrl: 'https://asaas.com/invoice/e2e-test',
    transactionReceiptUrl: null,
    pixTransaction: {
      id: 'pix-txn-e2e-001',
      qrCode: {
        encodedImage: E2E_PIX_IMAGE_B64,
        payload: E2E_PIX_PAYLOAD,
        expirationDate: E2E_PIX_EXPIRATION,
      },
    },
  });
}

function creditCardPayload(eventId: string, externalRef: string): ReturnType<typeof buildPayload> {
  return buildPayload(eventId, {
    id: `pay_asaas_${eventId}`,
    status: 'PENDING',
    billingType: 'CREDIT_CARD',
    externalReference: externalRef,
    value: 99.90,
    dueDate: '2026-04-30',
  });
}

test.describe('POST /webhooks/asaas — idempotência e campos PIX', () => {
  test('mesmo providerEventId enviado duas vezes → apenas 1 registro no banco (sem duplicação)', async ({ request }) => {
    const eventId = `evt-idem-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    const payload = creditCardPayload(eventId, `e2e-idem-ref-${Date.now()}`);

    // First delivery
    const r1 = await request.post(WEBHOOK_PATH, {
      data: payload,
      headers: { 'asaas-access-token': WEBHOOK_TOKEN },
    });
    expect(r1.status()).toBe(200);

    // Wait for async processing to store the event
    await pollUntil(
      () => countWebhookEvents(eventId),
      count => count >= 1,
      { timeout: 5000 },
    );

    // Second delivery with identical payload and same eventId
    const r2 = await request.post(WEBHOOK_PATH, {
      data: payload,
      headers: { 'asaas-access-token': WEBHOOK_TOKEN },
    });
    expect(r2.status()).toBe(200);

    // Wait briefly for the second async check to run, then verify exactly 1 row
    await new Promise(r => setTimeout(r, 1000));
    const count = await countWebhookEvents(eventId);
    expect(count).toBe(1);
  });

  test('PAYMENT_CREATED PIX com pixTransaction preenchido → pixQrCode e pixExpiresAt populados no payment', async ({ request }) => {
    const eventId = `evt-pix-fields-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    const payload = pixPayment(eventId, PIX_SEED_EXTERNAL_REF);

    const res = await request.post(WEBHOOK_PATH, {
      data: payload,
      headers: { 'asaas-access-token': WEBHOOK_TOKEN },
    });
    expect(res.status()).toBe(200);

    // Poll until PaymentCreatedHandler finishes updating the payment
    const pix = await pollUntil(
      () => getPaymentPix(PIX_SEED_EXTERNAL_REF),
      p => p?.pix_qr_code !== null && p?.pix_qr_code !== undefined,
      { timeout: 6000, interval: 400 },
    );

    expect(pix).not.toBeNull();
    expect(pix!.pix_qr_code).toBe(E2E_PIX_PAYLOAD);
    expect(pix!.pix_qr_code_base64).toBe(E2E_PIX_IMAGE_B64);
    expect(pix!.pix_expires_at).not.toBeNull();
  });

  test('PAYMENT_CREATED CREDIT_CARD → campos PIX não são alterados (handler ignora billingType != PIX)', async ({ request }) => {
    // Uses a non-existent externalReference so no payment is found — verifies handler does not crash
    const eventId = `evt-cc-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    const payload = creditCardPayload(eventId, `e2e-cc-noop-ref-${Date.now()}`);

    const res = await request.post(WEBHOOK_PATH, {
      data: payload,
      headers: { 'asaas-access-token': WEBHOOK_TOKEN },
    });
    expect(res.status()).toBe(200);

    // Wait for async — verify event was stored (no exception propagated)
    const count = await pollUntil(
      () => countWebhookEvents(eventId),
      c => c >= 1,
      { timeout: 5000 },
    );
    expect(count).toBe(1);
  });

  test('PAYMENT_CREATED PIX com pixTransaction nulo → HTTP 200, sem erro 500 (handler robusto)', async ({ request }) => {
    const eventId = `evt-pix-null-txn-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    const payload = buildPayload(eventId, {
      id: `pay_asaas_${eventId}`,
      status: 'PENDING',
      billingType: 'PIX',
      externalReference: `e2e-null-pix-txn-${Date.now()}`,
      value: 99.90,
      dueDate: '2026-04-30',
      pixTransaction: null,
    });

    const res = await request.post(WEBHOOK_PATH, {
      data: payload,
      headers: { 'asaas-access-token': WEBHOOK_TOKEN },
    });
    expect(res.status()).toBe(200);
  });
});
