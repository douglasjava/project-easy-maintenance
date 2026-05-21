import { APIRequestContext, APIResponse } from '@playwright/test';
import { LoginResult } from './auth';

const API_V1 = '/easy-maintenance/api/v1';

export function authHeaders(auth: LoginResult): Record<string, string> {
  return {
    Authorization: `Bearer ${auth.token}`,
    'X-Org-Id': auth.orgId,
    'Content-Type': 'application/json',
  };
}

export function crossTenantHeaders(auth: LoginResult, foreignOrgId: string): Record<string, string> {
  return {
    Authorization: `Bearer ${auth.token}`,
    'X-Org-Id': foreignOrgId,
    'Content-Type': 'application/json',
  };
}

export const api = {
  get(request: APIRequestContext, path: string, auth: LoginResult): Promise<APIResponse> {
    return request.get(`${API_V1}${path}`, { headers: authHeaders(auth) });
  },

  post(request: APIRequestContext, path: string, auth: LoginResult, data: unknown): Promise<APIResponse> {
    return request.post(`${API_V1}${path}`, { headers: authHeaders(auth), data });
  },

  put(request: APIRequestContext, path: string, auth: LoginResult, data: unknown): Promise<APIResponse> {
    return request.put(`${API_V1}${path}`, { headers: authHeaders(auth), data });
  },

  delete(request: APIRequestContext, path: string, auth: LoginResult): Promise<APIResponse> {
    return request.delete(`${API_V1}${path}`, { headers: authHeaders(auth) });
  },

  getAs(request: APIRequestContext, path: string, auth: LoginResult, orgId: string): Promise<APIResponse> {
    return request.get(`${API_V1}${path}`, { headers: crossTenantHeaders(auth, orgId) });
  },

  postAs(request: APIRequestContext, path: string, auth: LoginResult, orgId: string, data: unknown): Promise<APIResponse> {
    return request.post(`${API_V1}${path}`, { headers: crossTenantHeaders(auth, orgId), data });
  },
};
