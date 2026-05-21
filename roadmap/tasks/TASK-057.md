# TASK-057 — Adicionar activated_at em billing_subscription_items

## Metadados

| Campo | Valor |
|-------|-------|
| **ID** | TASK-057 |
| **Tipo** | BACKEND / INFRA |
| **Prioridade** | 🟠 Alto |
| **Épico** | EPIC-010 (Billing) |
| **Status** | Done |
| **Criado em** | 12/05/2026 |

## Problema

`billing_subscription_items` não possui campo de data de ativação próprio. Quando um usuário adiciona uma segunda org após o onboarding, o item herda o `current_period_start` da subscription pai (que é da data do onboarding), tornando impossível saber quando cada item individualmente entrou em vigência. Isso impede proration correta em implementações futuras de billing.

## Solução

- Migration `V65`: adiciona coluna `activated_at TIMESTAMP NULL`, faz backfill com `created_at`
- Entidade `BillingSubscriptionItem`: campo `activatedAt`
- `BillingSubscriptionService.addItem()`: seta `activatedAt = Instant.now()` na criação
- `BillingSubscriptionResponse.SubscriptionItemResponse`: expõe `activatedAt` na resposta
- `IBillingSubscriptionItems` mapper: mapeia `activatedAt`
- `OrganizationsService.listUserOrganizations()`: inclui `activatedAt` no mapeamento manual

## Critérios de Aceite

- [x] Coluna `activated_at` criada com backfill de dados históricos
- [x] Novos itens recebem `activated_at = now()` na criação
- [x] Campo exposto nas respostas de subscription item
- [x] 269 testes passando após a mudança
