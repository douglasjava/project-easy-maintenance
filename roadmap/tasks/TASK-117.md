# TASK-117 — QA: E2E fluxo completo billing consolidado

## Tipo
QA

## Categoria
Billing

## Prioridade
🔴 Crítico

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

Mudança cirúrgica em fluxo crítico de monetização (onboarding, criação de organização, limite de itens,
downgrade). Precisa de validação end-to-end antes de considerar a epic concluída, cobrindo happy path,
erros e regressão — conforme QA mindset obrigatório do projeto.

## Roteiro de QA

- ✅ Onboarding novo → 1 cobrança única (não R$598)
- ✅ Criação de 2ª/3ª organização dentro do limite `maxOrganizations` → sem cobrança adicional
- ❌ Criação de organização além de `maxOrganizations` → bloqueada com mensagem clara
- ❌ Criação de itens em múltiplas organizações até estourar o pool compartilhado → bloqueada
  corretamente, mensagem indica limite da conta (não da organização)
- ❌ Downgrade de plano com itens/organizações acima do novo limite → bloqueado
- ⚠️ Edge case: conta com 1 organização só (comportamento não deve mudar visivelmente para quem nunca
  teve múltiplas orgs)
- ⚠️ Edge case: organização sem nenhum item cadastrado ainda
- 🔁 Regressão: tela `/billing` e painel admin refletem o novo modelo corretamente
- 🔁 Regressão: fluxo PIX/CC de cobrança (EPIC-010) continua funcionando com o novo `totalCents`
- 🔁 Regressão: `GET /organizations/{code}/subscription` não quebra consumidores existentes

## Critérios de Aceite

- [ ] Todos os cenários do roteiro validados manualmente ou via E2E automatizado
- [ ] Nenhuma regressão nos testes existentes (backend + frontend)
- [ ] Relatório de QA documentado em `roadmap/QA`

## Dependências
TASK-110, TASK-111, TASK-112, TASK-113, TASK-114, TASK-115, TASK-116

## Esforço
Médio (1 dia)

## Status
Backlog
