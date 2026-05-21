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
