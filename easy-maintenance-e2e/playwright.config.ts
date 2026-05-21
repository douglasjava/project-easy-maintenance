import { defineConfig, devices } from '@playwright/test';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(__dirname, '.env.e2e') });

const API_BASE_URL = process.env.API_BASE_URL ?? 'http://localhost:9000';
const FRONTEND_URL = process.env.FRONTEND_URL ?? 'http://localhost:3000';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: process.env.CI
    ? [['junit', { outputFile: 'results/junit.xml' }], ['html', { outputFolder: 'results/html' }]]
    : [['html', { open: 'never' }]],

  projects: [
    {
      name: 'api',
      testMatch: ['**/auth/**/*.spec.ts', '**/billing/**/*.spec.ts', '**/data/**/*.spec.ts', '**/smoke.spec.ts'],
      use: {
        baseURL: API_BASE_URL,
        extraHTTPHeaders: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
      },
    },
    {
      name: 'ui',
      testMatch: '**/frontend/**/*.spec.ts',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: FRONTEND_URL,
      },
    },
  ],
});
