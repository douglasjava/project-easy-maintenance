# Página pública de divulgação para fornecedores (`/para-fornecedores`) — Design

**Data**: 2026-09-24
**Status**: Aprovado por Douglas (via diálogo de brainstorm)
**Épico**: [EPIC-028](../../../roadmap/epics/EPIC-028.md) — Marketplace de Fornecedores
**Task**: [TASK-285](../../../roadmap/tasks/TASK-285.md)

## Contexto

O marketplace de fornecedores (EPIC-028 Fase 2) está pronto de ponta a ponta: auto-cadastro em
`/fornecedores/cadastro`, cobrança por Pix Automático (R$ 15,99/mês, TASK-278), autogestão via link
mágico em `/fornecedores/gerenciar/[token]` e pedido de orçamento das organizações chegando no
WhatsApp do fornecedor (`/fornecedores`, logado).

O que falta é **aquisição**: não existe nenhuma página que Douglas possa divulgar (anúncio, grupo
de WhatsApp, abordagem direta) explicando ao fornecedor por que participar, quanto custa e quais
são as regras. Hoje o único texto de proposta é uma frase no topo do formulário de cadastro. As
políticas (cobrança, visibilidade, cancelamento) não estão escritas em lugar nenhum.

Este é o **subprojeto A** de um pedido de duas partes. O **subprojeto B** — fornecedor ver os
pedidos de orçamento recebidos num kanban ([TASK-280](../../../roadmap/tasks/TASK-280.md)) — tem
brainstorm/spec próprios, depois deste.

## Decisões de escopo (confirmadas com Douglas)

1. **Natureza**: página pública de marketing (tipo `/landing`, voltada pro fornecedor) — **não** um
   painel com métricas.
2. **Abordagem**: página única nova `/para-fornecedores`, com políticas numa seção própria
   (`#politicas`) + FAQ. Rejeitadas: políticas em página separada (não há volume de texto que
   justifique) e embutir tudo em `/fornecedores/cadastro` (pesa o formulário, perde URL limpa pra
   anúncio). Não usa prefixo `/fornecedores/...` (já é o marketplace logado das organizações) nem o
   termo "parceiro" (já é o programa de afiliados, "Seja Parceiro" na `/landing`).
3. **Imagens**: mockups do produto feitos em HTML/CSS (card do fornecedor como aparece no
   marketplace + mensagem de pedido de orçamento no WhatsApp) + **1 foto** de técnico/prestador no
   hero, de banco gratuito com licença comercial (Unsplash/Pexels), otimizada em `.webp`.
4. **Políticas de negócio**:
   - **Cancelamento**: a qualquer momento, sem multa nem fidelidade.
   - **Comissão**: zero — 100% do serviço fechado fica com o fornecedor.
   - **Volume**: sem garantia de quantidade de pedidos (é visibilidade, não pedido garantido).
   - **Efeito do cancelamento**: descreve o comportamento **atual** do sistema — ao revogar o Pix
     Automático, o perfil sai do marketplace imediatamente (ver "Fora de escopo" item 1).
5. **Escopo técnico**: **100% frontend**. Nenhuma mudança de API, banco ou cobrança.

## Regras que a página inteira segue

- **Nenhuma prova social numérica** ("X prédios", "Y pedidos/mês", "Z fornecedores"). A base de
  clientes ainda não sustenta esse tipo de número.
- **Nenhuma promessa que o sistema não cumpre**. Cada item da seção de políticas corresponde a um
  comportamento verificado no código (tabela abaixo) — se o código mudar, o texto muda junto.

### Políticas → comportamento verificado no código (24/09/2026)

| Política (texto da página) | Fonte no código (`easy-maintenance-api`) |
|---|---|
| R$ 15,99/mês, cobrado por Pix Automático (débito mensal autorizado no banco) | `SupplierBillingService`, TASK-278 |
| Aparece pras organizações da mesma **cidade/UF** e das **categorias** escolhidas | `SupplierRepository.findByRegionVisibleTo` |
| Ordem da lista: nº de organizações que já cadastraram/vincularam o fornecedor, depois nome | mesma query, `ORDER BY s.registrationCount DESC, s.name ASC` |
| Pedido de orçamento chega no WhatsApp; negociação direta, sem intermediação | `/fornecedores` (web) → `wa.me` |
| Zero comissão | não existe cobrança além da mensalidade (decisão de negócio, item 4) |
| Sem garantia de volume de pedidos | decisão de negócio, item 4 |
| Débito falhou: 3 dias de tolerância após o vencimento; depois o perfil sai do marketplace e volta quando o pagamento é confirmado | `SupplierBillingService.suspendOverdueSubscriptions` (ciclo cobrado e não pago, fim do período + `PIX_DUE_DAYS` + `GRACE_PERIOD_DAYS`) e `SupplierPaymentActivationService.activateFromWebhook(supplierId, paymentId)` (renova/reativa). Corrigido na [TASK-288](../../../roadmap/tasks/TASK-288.md) (24/09) |
| Cancela quando quiser revogando a autorização no app do banco; sem cobranças novas e o perfil sai do marketplace | `PixAutomaticAuthorizationCancelledHandler` (`marketplaceEnabled=false` na hora) |
| Atualiza telefone e categorias pelo link de gerenciamento recebido no cadastro | `SupplierSelfManageService`, `/fornecedores/gerenciar/[token]` |

## Estrutura da página `/para-fornecedores`

Em ordem de rolagem:

1. **Navbar simples** — mesmo padrão de `/agendar` e `/blog` (`Logo` linkando pra `/landing`) + botão
   "Quero me cadastrar".
2. **Hero** — título com a promessa (ex.: *"Seja encontrado por quem cuida de prédios na sua
   cidade"*), subtítulo *"R$ 15,99/mês · zero comissão · cancele quando quiser"*, CTA principal →
   `/fornecedores/cadastro`, foto de técnico/prestador.
3. **Por que participar** — 3–4 cards: clientes que já estão procurando seu serviço; pedido de
   orçamento direto no WhatsApp; 100% do serviço fechado é seu; seu perfil ganha força conforme mais
   organizações te cadastram.
4. **Como funciona** — 3 passos com mockups: (1) você se cadastra e autoriza o Pix Automático →
   (2) o gestor da sua cidade te encontra (mockup do card no marketplace) → (3) o pedido chega no seu
   WhatsApp (mockup da mensagem).
5. **Preço** — card único: R$ 15,99/mês, ancoragem "cerca de R$ 0,53 por dia", lista do que está
   incluso, CTA.
6. **Políticas** (`id="politicas"`) — os itens da tabela acima, em linguagem direta, sem juridiquês.
7. **FAQ** — acordeão com 5–6 perguntas (ex.: "Preciso ter CNPJ?", "Em quanto tempo apareço?",
   "Como cancelo?", "O que acontece se o débito falhar?", "Vocês ficam com parte do serviço?",
   "Como altero meus dados?"). Respostas consistentes com a seção de políticas.
8. **CTA final** + footer.

Layout responsivo (mobile obrigatório), Bootstrap 5 como no resto da landing, mockups legíveis em
390px.

## Integrações e alterações fora da página nova

- **`src/components/Shell.tsx`**: incluir `/para-fornecedores` na allowlist de rotas públicas.
  Sem isso a página redireciona pro `/login` — mesma classe de bug das TASK-272/273/274 e do
  `/agendar` (EPIC-024). Checagem explícita no QA.
- **`src/app/sitemap.ts`**: nova entrada.
- **`metadata`** próprio (title, description, Open Graph 1200×630 gerado a partir do hero) — o link
  vai ser muito compartilhado no WhatsApp.
- **Footer da `/landing`**: link "Para fornecedores". **Não** entra na navbar (acabou de ser ajustada
  pra caber — web#92/#93).
- **`/fornecedores/cadastro`**: link "Como funciona e políticas" → `/para-fornecedores#politicas`.
  Única mudança visual nessa página; formulário, cobrança e fluxo inalterados.

## Medição

Hoje o cadastro de fornecedor não dispara nenhum evento e não grava UTM. Nesta entrega (frontend):

- `src/lib/tracking.ts`: funções novas para o clique no CTA de cadastro e para
  `CompleteRegistration` — mesmo padrão de `trackLead`/`trackContact` (`window.fbq?.(...)`,
  `window.gtag?.(...)`, seguras quando os scripts não estão carregados).
- CTA da `/para-fornecedores` dispara o evento de clique; `/fornecedores/cadastro` dispara
  `CompleteRegistration` quando o cadastro retorna sucesso.
- Page view já é automático (Meta Pixel / GA instalados). UTM já é capturada globalmente por
  `UtmCapture` — a atribuição por campanha fica a cargo do Meta/GA.

## Testes e critérios de aceite

**Automatizados**
- `src/lib/tracking.test.ts`: casos novos para as funções de tracking novas (chamam `fbq`/`gtag`
  quando presentes; não quebram quando ausentes).
- `npx tsc --noEmit`, `npm run lint`, `npm run build` limpos; `npm test` sem regressão nova.

**QA manual (browser real)**
- `/para-fornecedores` abre **deslogado** (sem redirect pro `/login`) e também logado.
- 390 / 1024 / 1366 / 1920px: sem scroll horizontal, imagens carregando, mockups legíveis.
- Todos os CTAs levam a `/fornecedores/cadastro`; âncora `#politicas` funciona; link no footer da
  `/landing` funciona; link novo em `/fornecedores/cadastro` leva à seção de políticas.
- Eventos do Pixel/GA disparam no clique do CTA e no cadastro concluído.
- Fluxo de cadastro/pagamento de fornecedor idêntico ao atual (regressão).
- Revisão do texto de políticas contra a tabela "Políticas → comportamento verificado".
- Preview do link (Open Graph) correto ao colar a URL no WhatsApp.

## Fora de escopo (registrado como backlog)

1. **[TASK-286](../../../roadmap/tasks/TASK-286.md)** — manter o fornecedor visível até o fim do
   período já pago após revogar o Pix Automático (hoje sai na hora). Quando entrar, atualizar o texto
   de cancelamento desta página.
2. **[TASK-287](../../../roadmap/tasks/TASK-287.md)** — persistir UTM/origem no cadastro de fornecedor
   (backend: migration + `SelfRegisterSupplierRequest`) para medir conversão por campanha no próprio
   banco, independente do Meta/GA.
3. Subprojeto B — kanban de pedidos de orçamento do fornecedor ([TASK-280](../../../roadmap/tasks/TASK-280.md)).
4. Qualquer número de prova social na página.

## Riscos

- **Baixo** no geral — página nova e aditiva, sem backend.
- Esquecer a allowlist do `Shell.tsx` (histórico de recorrência) — mitigado por checagem explícita
  no QA.
- Texto de política divergir do sistema no futuro — mitigado pela tabela de rastreabilidade acima e
  pela nota na TASK-286.
