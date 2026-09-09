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

-- -------------------------------------------------------
-- 10. EPIC-030 / TASK-254 — Compliance Dashboard test tenants
--
--     Reuses tenant-a-admin's password hash (E2ePassA1!) for all 3 new users below —
--     same fixed E2E-only credential, no new bcrypt hash needed.
--
--     tenant-c-admin@e2e.test: 1 org, 2 items, 0 maintenances
--         -> GET /dashboard/summary must return state = ONBOARDING
--     tenant-d-admin@e2e.test: 1 org, 5 items (3 compliant w/ evidence + 2 overdue)
--         -> state = OPERATING, complianceIndex = 60 (3/5), 2 items in the OVERDUE action queue
--     tenant-e-admin@e2e.test: 3 orgs, 2 items each (org 1: 1 compliant/1 overdue = 50%;
--         orgs 2/3: 2 compliant each = 100%)
--         -> state = PORTFOLIO, complianceIndex = 83 (5/6), unitsRanking has org 1 first (worst)
-- -------------------------------------------------------
INSERT INTO organizations (code, name, city, doc, street, number, neighborhood, state, zip_code, country, company_type, created_at, updated_at)
VALUES
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'E2E Org Onboarding', 'São Paulo', '00000000000193', 'Rua Teste', '789', 'Centro', 'SP', '01000-000', 'BR', 'COMMERCIAL', NOW(), NOW()),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E Org Operating', 'São Paulo', '00000000000194', 'Rua Teste', '101', 'Centro', 'SP', '01000-000', 'BR', 'COMMERCIAL', NOW(), NOW()),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'E2E Org Portfolio 1', 'São Paulo', '00000000000195', 'Rua Teste', '102', 'Centro', 'SP', '01000-000', 'BR', 'COMMERCIAL', NOW(), NOW()),
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'E2E Org Portfolio 2', 'São Paulo', '00000000000196', 'Rua Teste', '103', 'Centro', 'SP', '01000-000', 'BR', 'COMMERCIAL', NOW(), NOW()),
    ('11111111-1111-1111-1111-111111111111', 'E2E Org Portfolio 3', 'São Paulo', '00000000000197', 'Rua Teste', '104', 'Centro', 'SP', '01000-000', 'BR', 'COMMERCIAL', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    city = VALUES(city),
    updated_at = NOW();

INSERT INTO users (email, name, role, status, password_hash, created_at, updated_at)
VALUES
    ('tenant-c-admin@e2e.test', 'E2E Admin C (Onboarding)', 'ADMIN', 'ACTIVE',
     '$2b$10$0KwI7n86mNzgwTONFgm3zeI9jA.kN2aPMByC6J.l6/4GltRP95NL6', NOW(), NOW()),
    ('tenant-d-admin@e2e.test', 'E2E Admin D (Operating)', 'ADMIN', 'ACTIVE',
     '$2b$10$0KwI7n86mNzgwTONFgm3zeI9jA.kN2aPMByC6J.l6/4GltRP95NL6', NOW(), NOW()),
    ('tenant-e-admin@e2e.test', 'E2E Admin E (Portfolio)', 'ADMIN', 'ACTIVE',
     '$2b$10$0KwI7n86mNzgwTONFgm3zeI9jA.kN2aPMByC6J.l6/4GltRP95NL6', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    name          = VALUES(name),
    status        = VALUES(status),
    password_hash = VALUES(password_hash),
    updated_at    = NOW();

INSERT IGNORE INTO user_organizations (user_id, organization_code, created_at, updated_at)
SELECT u.id, 'cccccccc-cccc-cccc-cccc-cccccccccccc', NOW(), NOW()
FROM users u WHERE u.email = 'tenant-c-admin@e2e.test';

INSERT IGNORE INTO user_organizations (user_id, organization_code, created_at, updated_at)
SELECT u.id, 'dddddddd-dddd-dddd-dddd-dddddddddddd', NOW(), NOW()
FROM users u WHERE u.email = 'tenant-d-admin@e2e.test';

INSERT IGNORE INTO user_organizations (user_id, organization_code, created_at, updated_at)
SELECT u.id, org.code, NOW(), NOW()
FROM users u
JOIN (
    SELECT 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' AS code
    UNION ALL SELECT 'ffffffff-ffff-ffff-ffff-ffffffffffff'
    UNION ALL SELECT '11111111-1111-1111-1111-111111111111'
) org ON TRUE
WHERE u.email = 'tenant-e-admin@e2e.test';

INSERT INTO billing_accounts (user_id, billing_email, status, payment_method, name, created_at, updated_at)
SELECT u.id, u.email, 'ACTIVE', 'CARD', u.name, NOW(), NOW()
FROM users u
WHERE u.email IN ('tenant-c-admin@e2e.test', 'tenant-d-admin@e2e.test', 'tenant-e-admin@e2e.test')
  AND NOT EXISTS (SELECT 1 FROM billing_accounts ba WHERE ba.user_id = u.id);

INSERT INTO billing_subscriptions (billing_account_id, status, cycle, current_period_start, current_period_end, total_cents, created_at, updated_at)
SELECT ba.id, 'ACTIVE', 'MONTHLY', NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), 0, NOW(), NOW()
FROM billing_accounts ba
JOIN users u ON ba.user_id = u.id
WHERE u.email IN ('tenant-c-admin@e2e.test', 'tenant-d-admin@e2e.test', 'tenant-e-admin@e2e.test')
  AND NOT EXISTS (SELECT 1 FROM billing_subscriptions bs WHERE bs.billing_account_id = ba.id);

INSERT INTO billing_subscription_items (billing_subscription_id, source_type, source_id, plan_code, value_cents, cancel_at_period_end, created_at, updated_at)
SELECT bs.id, 'ORGANIZATION', org.code, 'STARTER', 0, FALSE, NOW(), NOW()
FROM billing_subscriptions bs
JOIN billing_accounts ba ON bs.billing_account_id = ba.id
JOIN users u ON ba.user_id = u.id
JOIN (
    SELECT 'tenant-c-admin@e2e.test' AS email, 'cccccccc-cccc-cccc-cccc-cccccccccccc' AS code
    UNION ALL SELECT 'tenant-d-admin@e2e.test', 'dddddddd-dddd-dddd-dddd-dddddddddddd'
    UNION ALL SELECT 'tenant-e-admin@e2e.test', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
    UNION ALL SELECT 'tenant-e-admin@e2e.test', 'ffffffff-ffff-ffff-ffff-ffffffffffff'
    UNION ALL SELECT 'tenant-e-admin@e2e.test', '11111111-1111-1111-1111-111111111111'
) org ON org.email = u.email
WHERE u.email = org.email
  AND NOT EXISTS (
      SELECT 1 FROM billing_subscription_items bsi
      WHERE bsi.billing_subscription_id = bs.id AND bsi.source_id = org.code
  );

-- Child rows (attachments -> maintenances -> items) dropped in FK order, then rebuilt, so this
-- block stays safely re-runnable like section 7 above.
DELETE FROM maintenance_attachments
WHERE maintenance_id IN (
    SELECT m.id FROM maintenances m
    JOIN maintenance_items i ON i.id = m.item_id
    WHERE i.organization_code IN (
        'cccccccc-cccc-cccc-cccc-cccccccccccc', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
        'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
        '11111111-1111-1111-1111-111111111111'
    )
);

DELETE FROM maintenances
WHERE item_id IN (
    SELECT id FROM maintenance_items WHERE organization_code IN (
        'cccccccc-cccc-cccc-cccc-cccccccccccc', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
        'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
        '11111111-1111-1111-1111-111111111111'
    )
);

DELETE FROM maintenance_items
WHERE organization_code IN (
    'cccccccc-cccc-cccc-cccc-cccccccccccc', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '11111111-1111-1111-1111-111111111111'
);

INSERT INTO maintenance_items
    (organization_code, item_type, item_category, custom_period_unit, custom_period_qty, next_due_at, status, created_at, updated_at)
VALUES
    -- ONBOARDING: 2 items, 0 maintenances -> itemsTotal < 5, maintenancesEver = 0
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'E2E_ONB_ITEM_1', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 60 DAY), 'OK', NOW(), NOW()),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'E2E_ONB_ITEM_2', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 90 DAY), 'OK', NOW(), NOW()),

    -- OPERATING: 5 items -> 3 compliant (future due + evidence below) + 2 overdue -> index 60
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_1', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW()),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_2', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW()),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_3', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW()),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_4', 'OPERATIONAL', 'MESES', 6, DATE_SUB(CURDATE(), INTERVAL 52 DAY), 'OVERDUE', NOW(), NOW()),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_5', 'OPERATIONAL', 'MESES', 6, DATE_SUB(CURDATE(), INTERVAL 14 DAY), 'OVERDUE', NOW(), NOW()),

    -- PORTFOLIO org 1 (worst unit, 50%): 1 compliant + 1 overdue
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'E2E_PF1_ITEM_1', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW()),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'E2E_PF1_ITEM_2', 'OPERATIONAL', 'MESES', 6, DATE_SUB(CURDATE(), INTERVAL 27 DAY), 'OVERDUE', NOW(), NOW()),

    -- PORTFOLIO org 2 (100%): 2 compliant
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'E2E_PF2_ITEM_1', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW()),
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'E2E_PF2_ITEM_2', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW()),

    -- PORTFOLIO org 3 (100%): 2 compliant
    ('11111111-1111-1111-1111-111111111111', 'E2E_PF3_ITEM_1', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW()),
    ('11111111-1111-1111-1111-111111111111', 'E2E_PF3_ITEM_2', 'OPERATIONAL', 'MESES', 6, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'OK', NOW(), NOW());

-- Maintenance history (+ evidence attachment below) for every item meant to be "compliant" —
-- drives maintenancesEver > 0 for OPERATING/PORTFOLIO and feeds the compliance-index formula's
-- evidence flag (ComplianceMetricsRepository). Overdue items deliberately get none: they're
-- already non-compliant via the status flag, and their absence is what the E2E "postpone"/
-- "complete" scenarios act on via the action queue.
INSERT INTO maintenances (item_id, performed_at, `type`, performed_by, cost_cents, next_due_at, created_at)
SELECT i.id, DATE_SUB(CURDATE(), INTERVAL 30 DAY), 'PREVENTIVA', 'E2E Seed', 15000, DATE_SUB(CURDATE(), INTERVAL 30 DAY), NOW()
FROM maintenance_items i
JOIN (
    SELECT 'dddddddd-dddd-dddd-dddd-dddddddddddd' AS org, 'E2E_OPE_ITEM_1' AS item_type
    UNION ALL SELECT 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_2'
    UNION ALL SELECT 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_3'
    UNION ALL SELECT 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'E2E_PF1_ITEM_1'
    UNION ALL SELECT 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'E2E_PF2_ITEM_1'
    UNION ALL SELECT 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'E2E_PF2_ITEM_2'
    UNION ALL SELECT '11111111-1111-1111-1111-111111111111', 'E2E_PF3_ITEM_1'
    UNION ALL SELECT '11111111-1111-1111-1111-111111111111', 'E2E_PF3_ITEM_2'
) compliant ON compliant.org = i.organization_code AND compliant.item_type = i.item_type;

INSERT INTO maintenance_attachments (maintenance_id, attachment_type, file_url, uploaded_at)
SELECT m.id, 'REPORT', 'https://e2e-seed.local/evidence.pdf', NOW()
FROM maintenances m
JOIN maintenance_items i ON i.id = m.item_id
JOIN (
    SELECT 'dddddddd-dddd-dddd-dddd-dddddddddddd' AS org, 'E2E_OPE_ITEM_1' AS item_type
    UNION ALL SELECT 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_2'
    UNION ALL SELECT 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'E2E_OPE_ITEM_3'
    UNION ALL SELECT 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'E2E_PF1_ITEM_1'
    UNION ALL SELECT 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'E2E_PF2_ITEM_1'
    UNION ALL SELECT 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'E2E_PF2_ITEM_2'
    UNION ALL SELECT '11111111-1111-1111-1111-111111111111', 'E2E_PF3_ITEM_1'
    UNION ALL SELECT '11111111-1111-1111-1111-111111111111', 'E2E_PF3_ITEM_2'
) compliant ON compliant.org = i.organization_code AND compliant.item_type = i.item_type;
