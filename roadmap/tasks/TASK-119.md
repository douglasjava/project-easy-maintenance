# TASK-119 — BUGFIX Frontend: /organizations/[code] ainda exibia card de "Assinatura e Plano"

## Tipo
FRONTEND / BUGFIX

## Categoria
Billing / UX de Organizações

## Prioridade
🟠 Alto

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

Reportado por Douglas em teste manual local: a tela de detalhes da organização
(`/organizations/[code]`) ainda exibia um card completo "Assinatura e Plano" (plano atual, valor,
status, período, renovação) — a mesma informação que já não faz mais sentido no modelo de plano único
por conta (essa informação vive em `/billing`, não na organização). Além disso, a tela não tinha nenhuma
forma de editar os dados da empresa, apesar de exibi-los.

## Solução

- Removido o card "Assinatura e Plano" por completo (`sub.*` — planCode, planName, valueCents, status,
  período, cancelAtPeriodEnd) e os imports/helpers que só existiam para ele (`formatCurrency`,
  `formatDate`, ícones `CreditCard`/`Calendar`/`XCircle`).
- Card "Dados da Empresa" agora ocupa a largura total da página (era `col-lg-7`, virou `col-12`).
- Adicionado botão **Editar** no card de dados da empresa, com edição inline (nome, doc, endereço
  completo) salvando via `PATCH /organizations/{id}`.

### Decisão de escopo (confirmada com Douglas)
O botão "Editar" só aparece quando a organização exibida é a **organização ativa** da sessão
(`localStorage.organizationCode`). Motivo técnico: o `apiClient` sempre envia o header `X-Org-Id` da
organização ativa (não da organização sendo visualizada), então editar uma organização diferente da
ativa falharia na validação de tenant do backend (`@RequireTenant`). Resolver isso de forma genérica
exigiria ensinar o `apiClient` a aceitar um `X-Org-Id` explícito por requisição — descartado por ora
(opção mais simples escolhida por Douglas).

## Arquivos impactados

### Frontend
- `app/organizations/[code]/page.tsx` — reescrito: remove card de assinatura, adiciona edição inline
  condicionada à organização ativa

## Critérios de Aceite

- [x] Tela de detalhes da organização não exibe mais nenhuma informação de plano/assinatura
- [x] Card de dados da empresa ocupa a largura total da página
- [x] Botão "Editar" aparece apenas quando a organização exibida é a ativa na sessão
- [x] Edição salva via `PATCH /organizations/{id}` e atualiza a tela sem reload

## Dependências
TASK-118 (mesmo contexto de limpeza de UI da EPIC-014)

## Esforço
Baixo (removido card + adicionada edição inline em ~30 min)

## Risco de não fazer
Tela continua mostrando informação de plano por organização que não existe mais no modelo atual —
mesma classe de confusão que a TASK-118 corrigiu no fluxo de criação.

## Status
Em Validação — **verificação visual pendente** (mesma limitação já registrada nas TASK-115/116: não
consigo abrir o browser do Douglas para conferir; ele testa localmente e reporta).
