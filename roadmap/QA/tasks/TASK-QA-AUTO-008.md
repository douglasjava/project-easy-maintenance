# TASK-QA-AUTO-008 — Testes de API/integração: endpoints públicos do fornecedor e ciclo de cobrança

## Tipo
QA Automatizada — API / Integração (`easy-maintenance-api`, `@WebMvcTest`/`@SpringBootTest`)

## Categoria
Backend / Marketplace de Fornecedores / Billing

## Prioridade
🟡 Médio — **Próximo**

## Épico
EPIC-028 (origem: TASK-280 e TASK-288)

## Descrição
1. **Endpoints do link mágico** (`GET`/`PATCH /public/suppliers/manage/{token}/budget-requests`):
   teste no nível HTTP cobrindo rota pública sem `X-Org-Id`, **PATCH em pedido de outro fornecedor →
   404** (IDOR), status inválido/nulo → 422 `ProblemDetail`, token inválido → 404.
2. **Ciclo de cobrança do fornecedor** ponta a ponta com banco (Testcontainers MySQL ou H2) e
   `AsaasClient` mockado: cobrar ciclo → `PAYMENT_RECEIVED` (via `PaymentReceivedHandler`) renova
   `current_period_end`; ciclo não pago além de vencimento + tolerância → `PAST_DUE` + fora do
   marketplace; `PAST_DUE` pago → reativado.

## Justificativa para Automatização
- Hoje os endpoints só têm testes de serviço (Mockito) + smoke manual com `curl`; roteamento,
  liberação no `SecurityConfig`/`TenantFilter` e o 422 não têm proteção automática (achado da revisão
  final da TASK-280).
- A TASK-288 corrigiu um bug de cobrança que ficou meses invisível justamente por falta de teste do
  fluxo completo (webhook + job + banco).

## Cobertura Esperada
- 4 casos HTTP dos endpoints do fornecedor.
- 3 cenários do ciclo (renovação, suspensão, reativação) exercitando handler + serviço + repositório.

## Status
Backlog
