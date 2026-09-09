# TASK-253 — FRONTEND: Estado `ONBOARDING`

## Tipo
FRONTEND

## Categoria
Dashboard / Compliance

## Prioridade
🟡 Médio

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — validar com uma conta sintética nova (< 5 itens, 0 manutenções) que renderiza `ONBOARDING`
sem nenhum gráfico/contador zerado na tela.

---

## Contexto
Renumerada de TASK-137 do documento original. Renderizado quando `/dashboard/summary` retorna
`state: ONBOARDING`. Checklist de implementação de 7 passos + sugestão de itens obrigatórios via IA
("Gerar plano automático").

## Escopo
- Checklist de 7 passos com anel de progresso, derivado de dado real do tenant (não hardcoded).
- Itens obrigatórios sugeridos pro tipo de estabelecimento, como chips mostrando a norma que exige
  cada um, + botão "Gerar plano automático".
- Nenhum gráfico, nenhum contador zerado neste estado.

## Viabilidade Técnica

**Já existe boa parte disso — não é greenfield:**
- `OnboardingChecklist.tsx` (196 linhas) e `GuidedTour.tsx` já implementam uma versão do conceito
  "conta nova" no dashboard atual (`src/app/page.tsx` os renderiza incondicionalmente hoje, antes
  mesmo do conteúdo principal). Este task precisa decidir explicitamente: substituir esses dois
  componentes pelo novo checklist de 7 passos, ou integrar o que já existe com o layout novo. O
  documento original não sabia que isso já existia.
- **"Gerar plano automático" já tem pra onde apontar**: `AiBootstrapService`
  (`ai/application/service/AiBootstrapService.java`, fluxo `preview`/`apply`) +
  `AiBootstrapController` já implementam exatamente o "SAMU" que o documento original assume que
  existe — inclusive com `CompanyType` como parâmetro de entrada. **Isso resolve a decisão #3 do
  épico**: não é "assumir que não existe e usar seed table" — existe, e dá pra usar direto.

**Sem achado técnico contrário** no checklist de 7 passos em si (é composição de dado que já é
possível calcular: empresa cadastrada, itens cadastrados, etc. — tudo consultável via endpoints
existentes).

## Dependências
TASK-249 (shell). `AiBootstrapService` já pronto (sem dependência de outra task deste épico).

## Riscos
Baixo — é o task mais "gratuito" do épico, boa parte da fundação já existe (checklist parcial +
IA de sugestão já prontos). Risco principal é decidir mal a integração com `OnboardingChecklist`/
`GuidedTour` existentes e acabar com dois fluxos de onboarding paralelos e divergentes.

## Esforço
Pequeno-médio — menor que o documento original estimava, já que o SAMU (decisão #3) já existe.

## Status
🔴 Não iniciada — bloqueada por TASK-249.
