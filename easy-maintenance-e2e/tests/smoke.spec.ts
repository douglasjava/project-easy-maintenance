import { test, expect } from '@playwright/test';

/**
 * Smoke test: validates the E2E project is correctly wired and the API is reachable.
 * Run before any other suite: `npm run test:smoke`
 */
test.describe('Smoke — API reachability', () => {
  test('GET /actuator/health returns UP', async ({ request }) => {
    const response = await request.get('/actuator/health');
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.status).toBe('UP');
  });

  test('POST /auth/login with invalid credentials returns 401', async ({ request }) => {
    const response = await request.post('/easy-maintenance/api/v1/auth/login', {
      data: { email: 'nonexistent@e2e.test', password: 'wrong', remember: false },
    });
    expect(response.status()).toBe(401);
  });
});
