# TASK-305 — Consultas só leitura

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 2**

## Depende de
TASK-302, TASK-303

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-305-<descricao-curta>`.

**Escopo**: vencimentos (semana/30 dias), vencidos, histórico de um item (últimas 5), índice de
conformidade; até 10 linhas por resposta + link "ver todos"; nomes legíveis (portar
`formatItemType` para o backend); comparação entre condomínios → link para Relatórios.

**Critérios de aceite**
- [x] Respostas batem com o que o dashboard e as listas mostram para a mesma organização (vencido = vencimento < hoje, como o dashboard; índice do próprio DashboardSummaryService; conferido na conta demo).
- [x] Organização sem itens: resposta útil (como começar), não lista vazia.
- [x] Nenhuma consulta atravessa organizações (runAs com a organização da conversa + validação dos serviços; id forjado → "não encontrei").

**Prompt**: `execute a TASK-305 (EPIC-031): consultas só leitura pelo assistente, reaproveitando
os serviços de dashboard, itens e manutenções.`

## Execução (27/09/2026)
Branch `feature/TASK-305-assistente-consultas` · PR [api#127](https://github.com/douglasjava/easy-maintenance-api/pull/127) → `staging`.
`AssistantQueryService` (vencimentos 7/30 dias, vencidos com "há N dias", histórico das últimas 5 com escolha por lista `hist:<id>`,
índice de conformidade + link de Relatórios para quem tem vários condomínios), `ItemTypeLabels` (port do `formatItemType` do web) e
roteamento no `IntentStep` (botões do menu sem IA). `mvn test` 1246/1246; ponta a ponta local com a conta demo.
Links "ver todos" apontam para as telas sem filtro — filtros pela URL são a TASK-307.

## Ajuste do piloto (27/09/2026)
Teste em produção: período sempre 7 dias ("esse mês", "8 meses") e "histórico do elevador" sem elevador na organização
sem mostrar alternativas. Corrigido em [api#129](https://github.com/douglasjava/easy-maintenance-api/pull/129): período lido
também do texto (N dias/semanas/meses/anos, mês=30, ano=365, teto 365) e histórico não encontrado lista os itens da organização.

## Status
🟡 Em validação — [api#127](https://github.com/douglasjava/easy-maintenance-api/pull/127) mergeada em `staging`; promoção para `main` em [api#128](https://github.com/douglasjava/easy-maintenance-api/pull/128)
