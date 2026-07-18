# TASK-127 — Frontend: seção "Seja Parceiro" na landing, linkando para o cadastro de afiliado já existente

## Tipo
FRONTEND

## Categoria
Marketing / Landing / Conversão

## Prioridade
🟡 Médio

## Épico
EPIC-006 — Produto / Experiência do Usuário (conteúdo de landing) / EPIC-012 — Affiliate Referral
(feature que está sendo surfaceada)

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — confirmar que o botão/CTA leva de fato para `/indicador/novo`, que o link do menu funciona em
mobile (menu colapsado) e que a seção não introduz duplicação com nada existente.

---

## Contexto e motivação

Douglas pediu pra dar uma olhada na landing da Total Chat (`totalchat.com.br`) — destacou que ela é
interativa, mostra os planos, e tem um item de menu "Seja Parceiro".

Levantamento antes de criar o card (16/07/2026):
- **Não precisamos replicar nada** — o programa de parceiro/afiliado **já está construído ponta a ponta**
  no nosso próprio código, só não está linkado em lugar nenhum da landing pública:
  - Frontend: `/indicador/novo` (formulário de cadastro — nome/e-mail/whatsapp, aceite de termos, gera
    link de indicação copiável) e `/indicador/[code]` (painel do afiliado).
  - Backend: módulo `affiliates` completo (`Affiliate`, `ReferralCommission`, `AffiliateService`,
    `CommissionService`, `AffiliateController` — endpoint público `POST /affiliates` —,
    `CommissionAdminController`).
  - Comissão padrão: **20%** (`AffiliateService.DEFAULT_COMMISSION_RATE`).
- Validado antes de expor publicamente: rodei os 4 conjuntos de teste do módulo
  (`AffiliateServiceTest`, `CommissionServiceTest`, `AffiliateRepositoryTest`,
  `AffiliateControllerTest`) — **27/27 passando**. Fluxo saudável.
- É a EPIC-012 (TASK-089 a 096) — construída mas o kanban ainda mostra como Backlog (documentação
  desatualizada em relação ao código; não é escopo deste card corrigir isso, só registrar).
- **Cards de preço da Total Chat ficam fora de escopo** — Douglas confirmou que isso é decisão de negócio
  separada (o que exatamente publicar como preço), não entra aqui.

### Decisão de escopo (Douglas, 16/07/2026)
Não é uma página nova nem um formulário novo — é **uma seção simples na própria landing** com uma
descrição curta do programa de parceria, terminando num botão que leva para a página já existente
(`/indicador/novo`).

---

## Escopo

### Frontend (`easy-maintenance-web`)

- Nova seção "Seja Parceiro" na `landing/page.tsx` (ou componente próprio, seguindo o padrão já usado em
  `RiskBlock`/TASK-126, para não inchar ainda mais o arquivo principal).
- Conteúdo: eyebrow + headline curta + 1-2 frases explicando o programa (indicar clientes, ganhar
  comissão) + botão CTA ("Quero ser parceiro" ou equivalente) linkando para `/indicador/novo`.
- Posição: seção secundária, próxima ao final (depois de "Para quem", antes do CTA final) — não compete
  com o pitch principal do produto.
- Item "Seja Parceiro" adicionado ao menu de navegação da landing (mesmo padrão dos outros itens:
  Problema/Solução/Diferenciais/Para quem), linkando para `/indicador/novo` (não é âncora `#`, é rota
  real).

### Fora de escopo desta task

- Qualquer alteração em `/indicador/novo` ou `/indicador/[code]` (páginas já existentes e testadas).
- Cards de preço/planos públicos (decisão de negócio separada).
- Corrigir o status desatualizado da EPIC-012 no kanban.

### QA / Testes

- Manual: clicar no item do menu e no botão da seção, confirmar que ambos levam para `/indicador/novo`;
  conferir menu mobile colapsado (hamburger); `tsc`/`eslint`/`next build` limpos.

---

## Arquivos impactados (estimativa)

### Frontend
- `src/components/landing/PartnerBlock.tsx` (novo, seguindo o padrão de `RiskBlock`)
- `src/app/landing/page.tsx` — inserir a seção + item no menu

## Critérios de Aceite

- [ ] Seção "Seja Parceiro" com descrição curta do programa (indicação + comissão) e botão CTA
- [ ] Botão da seção leva para `/indicador/novo`
- [ ] Item "Seja Parceiro" no menu de navegação, levando para `/indicador/novo`
- [ ] Funciona no menu mobile colapsado
- [ ] `tsc`/`eslint`/`next build` limpos

## Dependências
Nenhuma — `/indicador/novo` já existe, testado e saudável (27/27 testes backend passando).

## Riscos
Baixo — só adiciona um link/seção para uma feature já pronta e testada. Único risco real: se o fluxo de
afiliado não for mais monitorado/operacionalizado do lado do Douglas (pagamento manual via PIX em até 10
dias úteis, conforme os termos já exibidos em `/indicador/novo`) — expor isso publicamente aumenta a
demanda por esse processo manual. Vale confirmar com Douglas que o processo de pagamento de comissão está
ativo antes de divulgar.

## Esforço
Baixo — reaproveita padrão de componente já estabelecido (TASK-126) e uma página que já existe.

## Status
Backlog
