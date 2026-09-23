# TASK-283 — Atualizar recursos/diferenciais da landing com funcionalidades já shippadas

## Tipo
FRONTEND

## Categoria
Frontend (landing pública — conteúdo/copy)

## Prioridade
🟡 Médio — não é bug, é oportunidade: landing hoje sub-representa o produto real, o que pode
reduzir conversão de quem já pesquisou concorrentes com esses recursos.

## Épico
Sem épico — pedido direto de Douglas em 23/09/2026, junto da TASK-282 (telefone no form de leads).

## QA obrigatório
Sim (visual/copy) — conferir renderização mobile (carrossel) e desktop antes de publicar.

---

## Contexto

`easy-maintenance-web/src/app/landing/page.tsx` lista os recursos do produto em dois blocos
estáticos:
- `SOLUTION_ITEMS` (seção "Tudo o que você precisa em um só lugar"): 6 itens — Central de ativos,
  Agenda de vencimentos, Repositório de laudos, Trilha de auditoria, Evidências fotográficas,
  Gestão de fornecedores.
- `DIFERENCIAIS_ITEMS` (seção "Por que o Easy Maintenance é diferente?"): 5 itens focados em
  legislação/histórico/evidência.

Comparando com o roadmap (`roadmap/kanban.md`, `roadmap/epics/`), pelo menos 5 recursos shippados e
em produção **não aparecem em lugar nenhum da landing**:

| Recurso já em produção | Onde foi implementado | Por que vale destacar |
|---|---|---|
| Índice de conformidade + dashboard por estado de conta (ONBOARDING/OPERATING/PORTFOLIO) | EPIC-030, hoje é a própria home (`/`) do app logado | Diferencial proprietário forte, nenhum item atual da landing menciona um "índice"/score |
| Chamados de moradores via QR code (abertura pública sem login, kanban interno, acompanhamento por CPF) | EPIC-027 | Resolve "Ordens no WhatsApp" (já é um dos `PROBLEM_ITEMS` da própria landing) com uma solução concreta que hoje não é citada |
| Marketplace de fornecedores cadastrados/pontuados + orçamento solicitado direto pela plataforma | EPIC-028 | "Gestão de fornecedores" já existe na lista, mas é genérico — a pontuação e o pedido de orçamento direto são diferenciais reais, não comunicados |
| Notificações automáticas de vencimento via WhatsApp (item, empresa, data, fornecedor) | EPIC-023 | Reforça o diferencial "não se perde no zap" já usado no copy de `DIFERENCIAIS_ITEMS`, mas hoje é só promessa — virou realidade e pode ser citado como prova |
| Onboarding assistido (cadastro inicial guiado) | `AiBootstrapService` / `/ai-onboarding` | Reduz fricção de setup — argumento de venda pra quem teme "mais um sistema pra configurar" |

Nota de cautela: **não inserir prova social numérica** (quantidade de clientes, avaliações, etc.)
sem confirmar dado real com Douglas. Este levantamento é só sobre **recursos do produto**, não sobre
prova social.

## Escopo da correção

1. Adicionar até 2 itens novos em `SOLUTION_ITEMS` (limite pra não estourar o grid de 6→3 colunas
   desktop sem redesenho) — candidatos: "Índice de conformidade" e "Chamados de moradores via QR
   code". Os outros 3 (marketplace com pontuação, notificação WhatsApp, onboarding assistido) podem
   enriquecer a *descrição* de itens já existentes (`Gestão de fornecedores`, diferenciais) em vez de
   virar itens novos — evita inflar demais a seção.
2. Revisar `DIFERENCIAIS_ITEMS`: considerar substituir ou complementar 1 item com a prova de que
   "evidência que não se perde no zap" e "ordens no WhatsApp" (hoje só dor, em `PROBLEM_ITEMS`) têm
   solução concreta e nomeada (chamados via QR code, notificação automática).
3. Revisar `structuredData` (JSON-LD, linha 17-31) e a meta description se algum recurso novo mudar
   o posicionamento central do produto (hoje fala só de "conformidade com ABNT NBR 5674/14037/16280"
   — talvez valha mencionar moradores/fornecedores se isso virar parte do pitch principal).
4. Nenhuma mudança de backend — puramente conteúdo/copy em componentes React existentes
   (`SOLUTION_ITEMS`, `DIFERENCIAIS_ITEMS`, possivelmente `PROBLEM_ITEMS` se um problema ganhar
   solução nomeada).

## Decisão em aberto (produto/copy)
Qual conjunto exato de recursos priorizar e a redação final de cada card — texto curto (title +
desc, 1 linha cada, seguindo o padrão atual) precisa da voz/tom que Douglas quer pro público-alvo
(síndicos/administradoras majoritariamente, segundo `PERSONA_ITEMS`). Este documento traz a matéria-
prima (o que existe e não está comunicado); a redação final deve ser revisada por Douglas antes de
publicar, não só tecnicamente correta.

## Critérios de Aceite
- [ ] Pelo menos os 2 recursos mais fortes (índice de conformidade, chamados de moradores) citados
      em algum bloco da landing (solução ou diferenciais)
- [ ] Nenhuma prova social numérica inventada ou não confirmada por Douglas
- [ ] Grid desktop (`d-none d-md-block`) e carrossel mobile (`CardCarousel`) renderizando
      corretamente com a lista atualizada (checar visualmente, os 2 layouts são independentes)
- [ ] `npm run build` sem regressão

## Dependências
Nenhuma. Pode ser feita independente da TASK-282.

## Riscos
Baixo — mudança de conteúdo estático em componentes React já existentes, sem lógica nova, sem
mudança de contrato de API.

## Esforço
Pequeno (~1-2h): redação dos novos itens + ajuste dos arrays + QA visual (desktop/mobile).

## Status
🔵 Pronto para implementar — plano definido em 23/09/2026, aguardando Douglas revisar/priorizar os
recursos e a redação antes de eu abrir a branch.
