// Test tenant credentials — must exist in the E2E database before tests run.
// Seed these via Flyway migration or a setup script (see README).

export interface TenantConfig {
  adminEmail: string;
  adminPassword: string;
}

export const TENANT_A: TenantConfig = {
  adminEmail: process.env.TENANT_A_EMAIL ?? 'tenant-a-admin@e2e.test',
  adminPassword: process.env.TENANT_A_PASSWORD ?? 'E2ePassA1!',
};

export const TENANT_B: TenantConfig = {
  adminEmail: process.env.TENANT_B_EMAIL ?? 'tenant-b-admin@e2e.test',
  adminPassword: process.env.TENANT_B_PASSWORD ?? 'E2ePassB1!',
};

// EPIC-030/TASK-254: Compliance Dashboard scenario tenants (seed/e2e-seed.sql section 10).
// All three reuse TENANT_A's password (E2ePassA1!) — same fixed E2E-only credential.
export const TENANT_C_ONBOARDING: TenantConfig = {
  adminEmail: process.env.TENANT_C_EMAIL ?? 'tenant-c-admin@e2e.test',
  adminPassword: process.env.TENANT_C_PASSWORD ?? 'E2ePassA1!',
};

export const TENANT_D_OPERATING: TenantConfig = {
  adminEmail: process.env.TENANT_D_EMAIL ?? 'tenant-d-admin@e2e.test',
  adminPassword: process.env.TENANT_D_PASSWORD ?? 'E2ePassA1!',
};

export const TENANT_E_PORTFOLIO: TenantConfig = {
  adminEmail: process.env.TENANT_E_EMAIL ?? 'tenant-e-admin@e2e.test',
  adminPassword: process.env.TENANT_E_PASSWORD ?? 'E2ePassA1!',
};
