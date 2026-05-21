-- ============================================================
-- E2E Test Seed — Easy Maintenance
-- Run via: npm run setup:db
--
-- Creates 2 isolated tenants with real credentials so Playwright
-- tests can authenticate via the real /auth/login endpoint.
--
-- Idempotent: safe to run multiple times.
-- ============================================================

-- -------------------------------------------------------
-- 1. Organizations
-- -------------------------------------------------------
INSERT INTO organizations (
    code,
    name,
    city,
    doc,
    street,
    number,
    neighborhood,
    state,
    zip_code,
    country,
    company_type,
    created_at,
    updated_at
)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'E2E Org A',
        'São Paulo',
        '00000000000191',
        'Rua Teste',
        '123',
        'Centro',
        'SP',
        '01000-000',
        'BR',
        'COMMERCIAL',
        NOW(),
        NOW()
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'E2E Org B',
        'São Paulo',
        '00000000000192',
        'Rua Teste',
        '456',
        'Centro',
        'SP',
        '01000-000',
        'BR',
        'COMMERCIAL',
        NOW(),
        NOW()
    )
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
               city = VALUES(city),
                          updated_at = NOW();

-- -------------------------------------------------------
-- 2. Users (BCrypt hashes for E2ePassA1! and E2ePassB1!)
-- -------------------------------------------------------
INSERT INTO users (email, name, role, status, password_hash, created_at, updated_at)
VALUES
    ('tenant-a-admin@e2e.test', 'E2E Admin A', 'ADMIN', 'ACTIVE',
     '$2b$10$0KwI7n86mNzgwTONFgm3zeI9jA.kN2aPMByC6J.l6/4GltRP95NL6', NOW(), NOW()),
    ('tenant-b-admin@e2e.test', 'E2E Admin B', 'ADMIN', 'ACTIVE',
     '$2b$10$ukZCbz0NBjVy1Te1vVOPHOodysni/yPm3OE2ygk/Dkf78SWWlnPaG', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    name         = VALUES(name),
    status       = VALUES(status),
    password_hash = VALUES(password_hash),
    updated_at   = NOW();

-- -------------------------------------------------------
-- 3. User ↔ Organization links
-- -------------------------------------------------------
INSERT IGNORE INTO user_organizations (user_id, organization_code, created_at, updated_at)
SELECT u.id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NOW(), NOW()
FROM users u WHERE u.email = 'tenant-a-admin@e2e.test';

INSERT IGNORE INTO user_organizations (user_id, organization_code, created_at, updated_at)
SELECT u.id, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', NOW(), NOW()
FROM users u WHERE u.email = 'tenant-b-admin@e2e.test';

-- -------------------------------------------------------
-- 4. Billing accounts (one per user)
-- -------------------------------------------------------
INSERT INTO billing_accounts (user_id, billing_email, status, payment_method, name, created_at, updated_at)
SELECT u.id, u.email, 'ACTIVE', 'CARD', u.name, NOW(), NOW()
FROM users u
WHERE u.email IN ('tenant-a-admin@e2e.test', 'tenant-b-admin@e2e.test')
  AND NOT EXISTS (SELECT 1 FROM billing_accounts ba WHERE ba.user_id = u.id);

-- -------------------------------------------------------
-- 5. Billing subscriptions (one per billing account)
-- -------------------------------------------------------
INSERT INTO billing_subscriptions (billing_account_id, status, cycle, current_period_start, current_period_end, total_cents, created_at, updated_at)
SELECT ba.id, 'ACTIVE', 'MONTHLY', NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), 0, NOW(), NOW()
FROM billing_accounts ba
JOIN users u ON ba.user_id = u.id
WHERE u.email IN ('tenant-a-admin@e2e.test', 'tenant-b-admin@e2e.test')
  AND NOT EXISTS (SELECT 1 FROM billing_subscriptions bs WHERE bs.billing_account_id = ba.id);

-- -------------------------------------------------------
-- 6. Subscription items: Org-A subscribed to STARTER via User-A
--                        Org-B subscribed to STARTER via User-B
-- -------------------------------------------------------
INSERT INTO billing_subscription_items (billing_subscription_id, source_type, source_id, plan_code, value_cents, cancel_at_period_end, created_at, updated_at)
SELECT bs.id, 'ORGANIZATION', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'STARTER', 0, FALSE, NOW(), NOW()
FROM billing_subscriptions bs
JOIN billing_accounts ba ON bs.billing_account_id = ba.id
JOIN users u ON ba.user_id = u.id
WHERE u.email = 'tenant-a-admin@e2e.test'
  AND NOT EXISTS (
      SELECT 1 FROM billing_subscription_items bsi
      WHERE bsi.billing_subscription_id = bs.id
        AND bsi.source_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  );

INSERT INTO billing_subscription_items (billing_subscription_id, source_type, source_id, plan_code, value_cents, cancel_at_period_end, created_at, updated_at)
SELECT bs.id, 'ORGANIZATION', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'STARTER', 0, FALSE, NOW(), NOW()
FROM billing_subscriptions bs
JOIN billing_accounts ba ON bs.billing_account_id = ba.id
JOIN users u ON ba.user_id = u.id
WHERE u.email = 'tenant-b-admin@e2e.test'
  AND NOT EXISTS (
      SELECT 1 FROM billing_subscription_items bsi
      WHERE bsi.billing_subscription_id = bs.id
        AND bsi.source_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  );

-- -------------------------------------------------------
-- 7. Test items for data isolation assertions
--    Org-A: 2 items  |  Org-B: 1 item
--    GET /items for Org-A must return exactly 2 (no Org-B items)
-- -------------------------------------------------------
DELETE FROM maintenance_items
WHERE organization_code IN (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
);

INSERT INTO maintenance_items (organization_code, item_type, item_category, next_due_at, status, created_at, updated_at)
VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'E2E_ITEM_A_1', 'OPERATIONAL', DATE_ADD(NOW(), INTERVAL 30 DAY), 'OK', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'E2E_ITEM_A_2', 'OPERATIONAL', DATE_ADD(NOW(), INTERVAL 60 DAY), 'OK', NOW(), NOW()),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'E2E_ITEM_B_1', 'OPERATIONAL', DATE_ADD(NOW(), INTERVAL 30 DAY), 'OK', NOW(), NOW());

-- -------------------------------------------------------
-- 8. Invoice for Tenant-A — used as FK for webhook PIX test payment
--    Period 2026-03-01→2026-03-31 (distinct from any real invoice period)
-- -------------------------------------------------------
INSERT INTO invoices (payer_user_id, currency, period_start, period_end, status, due_date, subtotal_cents, discount_cents, total_cents)
SELECT u.id, 'BRL', '2026-03-01', '2026-03-31', 'OPEN', '2026-03-31', 9990, 0, 9990
FROM users u WHERE u.email = 'tenant-a-admin@e2e.test'
ON DUPLICATE KEY UPDATE status = VALUES(status), updated_at = NOW();

-- -------------------------------------------------------
-- 9. Payment for webhook PIX test
--    external_reference = 'e2e-pix-ref-001' is the lookup key used in PAYMENT_CREATED webhook
--    Starts with null PIX fields — handler populates them after webhook is received
-- -------------------------------------------------------
INSERT INTO payments (invoice_id, payer_user_id, provider, method_type, status, amount_cents, currency, external_reference)
SELECT i.id, u.id, 'ASAAS', 'PIX', 'PENDING', 9990, 'BRL', 'e2e-pix-ref-001'
FROM invoices i
JOIN users u ON i.payer_user_id = u.id
WHERE u.email = 'tenant-a-admin@e2e.test'
  AND i.period_start = '2026-03-01'
  AND i.period_end   = '2026-03-31'
  AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.external_reference = 'e2e-pix-ref-001');
