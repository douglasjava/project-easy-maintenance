# TASK-254 — QA/INFRA: E2E e regressão do dashboard novo

## Tipo
INFRA / CONFIG

## Categoria
Dashboard / Compliance / QA Automatizado

## Prioridade
🟡 Médio

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Não se aplica no sentido usual — esta task **é** a automação de QA do épico.

---

## Contexto
Renumerada de TASK-138 do documento original. Cobertura E2E (Playwright) pros 3 estados de conta +
comportamentos-chave (filtro, ação completando refetch, adiar sem motivo rejeitado, sem scroll
horizontal).

## Escopo
- Popular 3 tenants sintéticos e validar o estado renderizado em cada um:
  1. 2 itens, 0 manutenções → `ONBOARDING`, sem gráfico na tela
  2. 1 empresa com histórico → `OPERATING`, anel de conformidade visível, fila de ações populada
  3. 3 empresas, "todas" → `PORTFOLIO`, ranking de unidades visível, pior unidade primeiro
- Trocar filtro de período atualiza URL e números renderizados.
- Completar uma ação da fila refaz o summary e muda o índice de conformidade.
- Adiar sem motivo é rejeitado.
- Body da página nunca rola na horizontal em 1280px e 1920px.

## Viabilidade Técnica

**Infra já existe, mas é rasa.** `easy-maintenance-e2e` já tem `fixtures/auth.ts`,
`fixtures/tenant.ts`, `helpers/db.ts` e `playwright.config.ts` configurados — a convenção de seed
de tenant sintético que este task pede já tem onde se apoiar. Mas hoje só existe **1 spec real**
(`tests/smoke.spec.ts`) — não há um precedente rico de "cenário completo com múltiplas telas" pra
copiar; a maior parte do trabalho de escrever os specs novos é greenfield dentro de uma infra que
já existe, não reaproveitamento direto de testes parecidos.

**Sem achado técnico contrário** ao escopo em si — é consequência direta das TASK-249 a TASK-253
já estarem prontas e estáveis; não há decisão de arquitetura pendente aqui.

## Dependências
TASK-250, TASK-251, TASK-252, TASK-253 (tudo que está sendo testado precisa existir primeiro).

## Riscos
Baixo tecnicamente, mas é o último task da onda — qualquer atraso nas dependências atrasa
diretamente esta task, e qualquer decisão de escopo não fechada nas tasks anteriores (painel de
documentos da TASK-251, por exemplo) vira teste que não pode ser escrito ainda.

## Esforço
Médio.

## Status
🔴 Não iniciada — bloqueada por TASK-250/251/252/253.
