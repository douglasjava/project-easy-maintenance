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
- [~] Checklist — **reduzido de 7 pra 4 passos**, derivado só de `itemsTotal` (único dado real que
      `/dashboard/summary` expõe em `ONBOARDING`). Ver Decisões na Implementação.
- [ ] Itens obrigatórios sugeridos por chip com a norma — **não implementado**; o botão "Gerar
      plano automático" existe e linka pro fluxo de IA real (`/ai-onboarding`), mas a prévia
      inline (chips) ficaria redundante com o que essa tela já mostra — decisão de não duplicar.
- [x] Nenhum gráfico, nenhum contador zerado neste estado.

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

**Correção sobre `OnboardingChecklist.tsx` (achado só na implementação, não na análise original):**
o texto acima da análise técnica dizia que o checklist de 7 passos era "composição de dado que já é
possível calcular... tudo consultável via endpoints existentes" — **isso estava errado**. Lendo o
componente de verdade: `OnboardingChecklist.tsx` não deriva nada de dado real — é
`localStorage`-based, o usuário clica manualmente num círculo pra marcar cada passo como feito
(`STORAGE_KEY = "onboardingChecklist"`, sem nenhuma leitura de API). Contradiz diretamente o
requisito desta task ("derivado de dado real do tenant, não hardcoded") — não dava pra reaproveitar
como estava. Escopo do checklist novo foi reduzido pra só o que `/dashboard/summary` realmente
expõe (`itemsTotal`) em vez dos 7 passos completos.

## Dependências
TASK-249 (shell). `AiBootstrapService` já pronto (sem dependência de outra task deste épico).

## Riscos
Baixo — é o task mais "gratuito" do épico, boa parte da fundação já existe (checklist parcial +
IA de sugestão já prontos). Risco principal é decidir mal a integração com `OnboardingChecklist`/
`GuidedTour` existentes e acabar com dois fluxos de onboarding paralelos e divergentes.

## Esforço
Pequeno-médio — menor que o documento original estimava, já que o SAMU (decisão #3) já existe.

## Implementação
`src/components/dashboard/compliance/OnboardingPanel.tsx`. 4 passos: "Empresa cadastrada" (sempre
✓, chegou até aqui), "Cadastre seus itens" (✓ quando `itemsTotal > 0`), "Atinja 5 itens
cadastrados" (✓ quando `itemsTotal >= 5`), "Registre sua primeira manutenção" (sempre pendente
nesta v1 — `/dashboard/summary` não expõe esse dado individualmente em `ONBOARDING`, só o
agregado `itemsTotal < 5 OR maintenancesEver == 0` que decide o `state` como um todo). "Gerar plano
automático" linka pro `/ai-onboarding` existente.

`npm run build`/`eslint` limpos, sem regressão em `npm test`.

## Status
🟢 Implementado com escopo reduzido e documentado (4 passos reais em vez de 7 fictícios) —
validação num navegador real fica pendente (mesmo bloqueio de Firebase do EPIC-030).
