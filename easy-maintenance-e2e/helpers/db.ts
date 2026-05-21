import mysql, { RowDataPacket } from 'mysql2/promise';
import * as dotenv from 'dotenv';

dotenv.config({ path: '.env.e2e' });

function getDbConfig() {
  return {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3307'),
    user: process.env.DB_USER || 'easy_user',
    password: process.env.DB_PASSWORD || 'easy_pass',
    database: process.env.DB_NAME || 'easy_maintenance',
  };
}

/**
 * Returns how many rows exist in webhook_event for a given providerEventId.
 * Used to verify idempotency: a duplicate event must produce exactly 1 row.
 */
export async function countWebhookEvents(providerEventId: string): Promise<number> {
  const conn = await mysql.createConnection(getDbConfig());
  try {
    const [rows] = await conn.execute<RowDataPacket[]>(
      'SELECT COUNT(*) AS cnt FROM webhook_event WHERE provider_event_id = ?',
      [providerEventId],
    );
    return Number(rows[0].cnt);
  } finally {
    await conn.end();
  }
}

export interface PaymentPixFields {
  pix_qr_code: string | null;
  pix_qr_code_base64: string | null;
  pix_expires_at: Date | null;
}

/**
 * Returns the PIX fields of a payment identified by external_reference.
 * Used to verify that PaymentCreatedHandler populated them after a PIX webhook.
 */
export async function getPaymentPix(externalReference: string): Promise<PaymentPixFields | null> {
  const conn = await mysql.createConnection(getDbConfig());
  try {
    const [rows] = await conn.execute<RowDataPacket[]>(
      'SELECT pix_qr_code, pix_qr_code_base64, pix_expires_at FROM payments WHERE external_reference = ?',
      [externalReference],
    );
    return rows.length > 0 ? (rows[0] as unknown as PaymentPixFields) : null;
  } finally {
    await conn.end();
  }
}

/**
 * Polls fn every intervalMs until predicate returns true or timeout is reached.
 * Returns the last value returned by fn.
 */
export async function pollUntil<T>(
  fn: () => Promise<T>,
  predicate: (v: T) => boolean,
  { timeout = 5000, interval = 300 }: { timeout?: number; interval?: number } = {},
): Promise<T> {
  const deadline = Date.now() + timeout;
  let last: T = await fn();
  while (!predicate(last) && Date.now() < deadline) {
    await new Promise(r => setTimeout(r, interval));
    last = await fn();
  }
  return last;
}
