import { APIRequestContext } from '@playwright/test';

const API_V1 = '/easy-maintenance/api/v1';

export interface LoginResult {
  token: string;
  orgId: string;
  userId: number;
  email: string;
}

export async function loginAs(
  request: APIRequestContext,
  email: string,
  password: string,
): Promise<LoginResult> {
  const response = await request.post(`${API_V1}/auth/login`, {
    data: { email, password, remember: false },
  });

  if (!response.ok()) {
    throw new Error(
      `Login failed for ${email}: HTTP ${response.status()} — ${await response.text()}`,
    );
  }

  const body = await response.json();

  if (!body.organizationCodes || body.organizationCodes.length === 0) {
    throw new Error(`User ${email} has no organization codes`);
  }

  return {
    token: body.accessToken,
    orgId: body.organizationCodes[0],
    userId: body.id,
    email: body.email,
  };
}
