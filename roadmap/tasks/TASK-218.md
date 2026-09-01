# TASK-218 — Feedback de demo real: Rogerio Dantas (31/08/2026)

## Tipo
Guarda-chuva (intake) — 11 pontos de tipos variados (BUGFIX, FULL_STACK, INFRA/CONFIG, dúvida de
produto), triados abaixo. Cada um vira task própria quando priorizado.

## Contexto
Reunião de apresentação/demo com o cliente Rogerio Dantas, cadastro ao vivo acompanhado por Douglas.
Primeiro feedback estruturado de um cliente real usando o produto (contexto:
[[project_zero_customers_landing_copy]] — 0 clientes pagantes até 30/07/2026, então sinal raro e de
alto valor).

## Triagem (framework `product-decision`: classificação, impacto, decisão)

| # | Resumo | Classificação | Achado ao investigar | Decisão |
|---|---|---|---|---|
| 1 | Msg de erro de anexo pouco clara + tamanho "10GB"? | BUG / UX | `application.properties`: `aws.s3.upload.max-file-size-mb=10` é o **teto rígido**, aplicado via `Math.min(planMaxFileSizeMb, hardMaxFileSizeMb)` — capa **todos os planos** em 10MB, mesmo os configurados pra 20/50MB (`V63__restructure_billing_plans.sql`). Não é 10GB, é 10MB — o teto está bem abaixo do que os planos pagos prometem. | **DO NOW** — mensagem confusa + teto provavelmente errado (limita valor que o próprio plano paga) |
| 2 | Download não funcionou pra ele, funcionou pro Douglas | Não reproduzido | Sem causa raiz — Douglas testou com o próprio usuário e funcionou | **DEFER** — só monitorar, sem repro não dá pra investigar às cegas |
| 3 | Limite de 2 anexos por manutenção é pouco | UX / produto | Não achei limite "2" no backend — parece ser estrutura fixa da tela (frontend), não regra de negócio | **PLAN** — decisão de produto (novo limite? qual?) antes de mexer na tela |
| 4 | Alerta deveria começar 1 mês antes | Dúvida de regra | Não achei config de antecedência de alerta na busca inicial — precisa investigação dedicada no job de notificação (EPIC-015) | **PLAN** — investigar regra atual antes de decidir se é bug ou ajuste de config |
| 5 | Item normativo não mapeado (pontos de ancoragem) + reabre trava Regulatório/Operacional | Dado + Produto | Confirmado: "ANCORAGEM" não existe em `item_types`/`norms` — mapeamento faltando (NR-35, NR-18, ABNT NBR 16325, conforme pesquisa do Douglas). A trava de edição do campo é a TASK-212, decisão recente e deliberada. | **DO NOW** (parte a: mapear a norma) + **discussão de produto obrigatória** (parte b: não mexer na trava sem reabrir com Douglas) |
| 6 | Sistema lento; log "letra a letra" na busca de item; rotas `_rsc`/`/events` lentas | Performance | Log confirma busca sem debounce: 4 requisições em ~530ms pra "IN"→"INS"→"INST"→"INSTAL" (cada letra digitada dispara call ao backend). `_rsc=` é prefetch nativo do Next.js App Router; `/events?cee=no` não é rota desta API — precisa investigação no frontend pra identificar a origem. | **DO NOW** (debounce da busca, causa raiz clara e barata) + **PLAN** (investigação de performance mais ampla / teste de carga) |
| 7 | Cliente quer baixar normas na íntegra | Produto / jurídico | Não investigado ainda — ABNT NBR é norma paga/licenciada (não pode ser redistribuída livremente); normas NR são públicas (Ministério do Trabalho) e podem ser linkadas | **PLAN** — pesquisa de viabilidade legal antes de qualquer desenho |
| 8 | UX: pra onde ir depois de criar um item | UX | — | **DO NEXT** — pequena, mas precisa decisão de fluxo (lista ou já abrir criar manutenção) |
| 9 | Tipo de anexo (enum) sem opção "outro" com texto livre | Produto / dado | É enum hoje — mudar exige decisão (enum aberto vira dado livre, impacto em relatórios/filtros existentes) | **PLAN** — avaliar viabilidade antes de decidir |
| 10 | Menu lateral esquerdo — melhoria de UX | UX | Genérico, sem escopo definido ainda | **PLAN** — precisa virar um brainstorm dedicado (`superpowers:brainstorming`) antes de qualquer mudança |
| 11 | Lista de fornecedores nas notificações agradou — priorizar | Produto | Já existe: **EPIC-023**, `TASK-172` (status "Pronto para implementar", ainda não iniciada), `TASK-173`, `TASK-174` | **DO NOW** — só precisa dar o start, spec já pronta |

## Itens que exigem decisão do Douglas antes de qualquer código

- **#5 (parte b)**: reabrir ou não a edição livre de Regulatório/Operacional — contradiz decisão
  deliberada da TASK-212. Risco se reabrir sem cuidado: usuário empurrar prazo legal via digitação
  livre (o problema exato que a TASK-212 fechou).
- **#3**: novo limite de anexos por manutenção — qual número, e reestruturar a tela como?
- **#7**: viabilidade jurídica de disponibilizar normas na íntegra (ABNT é paga).
- **#9**: enum de tipo de anexo virar campo livre — trade-off com relatórios/filtros existentes.
- **#10**: escopo do brainstorm de UX do menu lateral.

## Sugestão de ordem (a confirmar com Douglas)

1. **Já prontos pra abrir task e implementar**: #1 (limite/mensagem de anexo), #5a (mapear norma de
   ancoragem), #6a (debounce na busca de item), #11 (start da TASK-172).
2. **Precisam de decisão rápida antes de virar task**: #8 (fluxo pós-criação de item).
3. **Precisam de conversa/investigação mais longa antes de qualquer task**: #3, #4, #5b, #6b
   (performance ampla), #7, #9, #10.
4. **Sem ação por ora**: #2 (sem repro).

## Status
🔵 Intake — triagem feita, aguardando Douglas priorizar quais viram task/branch primeiro.
