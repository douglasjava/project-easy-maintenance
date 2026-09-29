# TASK-308 — Onboarding conversacional

## Tipo
BACKEND

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 3**

## Depende de
TASK-302

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-308-<descricao-curta>`.

**Escopo**: só para conta existente, dentro de `maxOrganizations`. Perguntas: nome, tipo de empresa
(lista), CEP, e perguntas de sim/não geradas do catálogo do tipo (elevador, gerador, piscina, gás…).
Resumo "Vou cadastrar N itens" → Confirmar → `previewFromCatalog` + `apply` (sem IA).

**Critérios de aceite**
- [x] Os itens criados são os mesmos que o onboarding web criaria para as mesmas respostas.
- [x] Limite de organizações respeitado com mensagem clara.
- [x] Abandono no meio não cria nada.

**Prompt**: `execute a TASK-308 (EPIC-031): novo condomínio pelo WhatsApp reaproveitando
catalog-preview e apply do onboarding web.`

## Execução (29/09/2026)
- PR [api#143](https://github.com/douglasjava/easy-maintenance-api/pull/143).
- **Decisão (Douglas, 29/09):** perguntas de Sim/Não **por equipamento** (8: gerador, gás, sprinklers, hidrantes, alarme,
  para-raios, ar-condicionado, porta corta-fogo); o resto do catálogo entra sempre. Mapeamento em `NewOrganizationQuestions`.
- Mesma fonte e mesma carga do IA Onboarding do web (`previewFromCatalog` + `apply`, sem IA); empresa pelo mesmo
  `OrganizationsService.create` + `UsersService.addOrganization` do web, numa transação só. CEP via ViaCEP (opcional).
- Travas: só titular com acesso total (`checkCreateOrganization`, mesma regra do web) + limite do plano (início e Confirmar).
- Bug achado no roteiro ponta a ponta e corrigido: `OrganizationStep` apagava qualquer `awaiting` em toda mensagem.
- Validado localmente (simulador da Meta, dry-run): 21 itens criados = exatamente o catálogo do web menos os 5 desmarcados.

## Status
In Validation
