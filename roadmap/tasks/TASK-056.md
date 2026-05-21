# TASK-056 — Recriar rota GET /organizations/{code}/subscription

## Metadados

| Campo | Valor |
|-------|-------|
| **ID** | TASK-056 |
| **Tipo** | BUGFIX / BACKEND |
| **Prioridade** | 🔴 Crítico |
| **Épico** | EPIC-006 (Onboarding / Add-Org) |
| **Status** | Done |
| **Criado em** | 12/05/2026 |

## Problema

A rota `GET /organizations/{code}/subscription` foi perdida em uma refatoração de assinatura. O frontend a usa para exibir dados de assinatura ao adicionar/visualizar uma segunda organização. Sem ela, o fluxo quebra ou exibe tela vazia.

## Solução

- Novo método em `BillingSubscriptionItemRepository`: `findBySourceTypeAndSourceId()` com eager fetch da subscription, plan e nextPlan
- Novo método em `OrganizationsService`: `getOrganizationSubscription(String orgCode)`
- Novo endpoint em `OrganizationsController`: `GET /{orgCode}/subscription`
- Retorna `BillingSubscriptionResponse.SubscriptionItemResponse` (incluindo `activatedAt` adicionado pela TASK-057)

## Critérios de Aceite

- [x] `GET /organizations/{code}/subscription` retorna 200 com dados da subscription da org
- [x] Retorna 404 quando org não tem subscription item
- [x] Rota não exige `X-Org-Id` (está no bypass prefix `/organizations/`)
