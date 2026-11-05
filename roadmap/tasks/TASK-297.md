# TASK-297 — Limites do plano: usuários ilimitados, teto de itens da conta e exibição coerente

## Tipo
FULL_STACK (configuração de plano + ajuste de exibição; decisão de produto antes)

## Prioridade
🟠 Alto — argumento comercial direto de concorrente com preço público

## Contexto
Comparação com o Manu Help (25/09/2026, `docs/produto/contexto-comercial.md`): o principal argumento
de venda deles é **usuários ilimitados** nos planos pagos ("do porteiro ao gestor, ninguém paga a
mais"). Ao conferir como os nossos limites funcionam, apareceram três pontos:

1. **Usuários são limitados por organização**, não pela conta:
   `UsersService.validateUserLimit` conta `userOrganizationRepository.countByOrganizationCode(orgCode)`
   (Business: 10 por condomínio). O código já trata `maxUsers <= 0` como ilimitado, então liberar é
   **só configuração do plano** (`billing_plans.features_json` via `PATCH /private/admin/billing/plans/{code}`).
2. **Itens são limitados pela conta inteira** (pool, EPIC-014/TASK-111):
   `MaintenanceItemService.validateItemLimit` soma os itens de todas as organizações. No Business são 500
   no total, ~25 por condomínio para um síndico profissional com 20. A conta demo tem 16 itens num
   condomínio só, e um condomínio real tende a ter de 20 a 40. É um teto provável para o público que mais paga.
3. **A tela de faturamento mostra usuários como pool da conta** (`BillingDashboardService`:
   `usersUsed` = usuários distintos de todas as organizações, comparados com `maxUsers`), mas a
   validação é por organização. Um síndico com 3 condomínios e 8 usuários em cada vê "24/10" e pode
   achar que estourou o limite, sem ter estourado. Além disso, o javadoc de `BillingPlanFeatures` diz
   "max maintenance items per organization", o que está desatualizado.

## Decisões necessárias (Douglas)
- Usuários: ilimitados em todos os planos pagos, só no Business/Enterprise, ou manter 10/100 por empresa?
- Itens: manter pool da conta com teto maior (ex.: Business 1.000–2.000), passar a limitar por empresa,
  ou ilimitado nos planos pagos?
- Starter continua com limites baixos (degrau para upgrade)?

## Escopo (depois da decisão)
- Ajustar `features_json` dos planos (sem migration de código se for só valor; se for mudar a regra
  de itens para "por empresa", ajuste em `validateItemLimit` + testes).
- Tela de faturamento: exibir cada limite do jeito que ele é aplicado (ou "Ilimitado").
- Corrigir o javadoc de `BillingPlanFeatures`.
- Atualizar landing/página de preços, `context-brief.md`, `contexto-comercial.md` e o manual.

## Critérios de Aceite
- [ ] Limites decididos e aplicados nos planos
- [ ] Tela de faturamento mostra uso × limite coerente com a validação real
- [ ] Mensagem de limite atingido coerente com a regra (por empresa × conta)
- [ ] Documentos comerciais e landing com os novos limites
- [ ] Testes de `validateUserLimit` / `validateItemLimit` cobrindo a regra final

## Status
Backlog — aguardando decisão de produto
