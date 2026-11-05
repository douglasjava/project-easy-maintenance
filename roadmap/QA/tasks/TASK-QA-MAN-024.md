# TASK-QA-MAN-024 — QA Manual: release de fornecedores (staging → main)

## Tipo
QA Manual — **execução manual** em homologação (`staging`), antes de promover pra `main`

## Categoria
Full-Stack / Marketplace de Fornecedores / Billing

## Prioridade
🔴 Alto — inclui mudança no ciclo de cobrança do fornecedor (TASK-288) e exposição de dado pessoal
(TASK-280)

## Tasks cobertas (o que está em `staging` e ainda não está em `main`)

| Task | O que entrega | PRs |
|---|---|---|
| [TASK-285](../../tasks/TASK-285.md) | Página pública `/para-fornecedores` + refactor da allowlist de rotas públicas (`isPublicPath`) + eventos de tracking | web#94 |
| [TASK-280](../../tasks/TASK-280.md) | Kanban de pedidos de orçamento na tela do link mágico + aviso LGPD no modal da organização | api#116, web#95 |
| [TASK-288](../../tasks/TASK-288.md) | Fornecedor com débito falho é suspenso após tolerância e reativado ao pagar (V116) | api#117, web#96 |

Fora deste plano (já em `main`): agendamento Cal.com (TASK-175/176) e ajuste da navbar da landing.

---

## Pré-condições

- Deploy de `staging` com as PRs acima: API em `https://api-staging.easymaintenance.com.br`
  (profile `hml`, **Asaas sandbox**) e o front de homologação.
- Migrations `V115` e `V116` aplicadas no boot — conferir no log da API:
  `Successfully applied … now at version v116`.
- Acesso ao banco de staging (pros cenários de billing, que simulam "o tempo passar" via SQL).
- Um usuário de **organização** em staging (pra solicitar orçamento).
- Token de admin pra disparar o job sem esperar o cron das 02:15:
  `GET https://api-staging.easymaintenance.com.br/easy-maintenance/api/v1/run-jobs/execute-supplier-billing`.
- Painel do Asaas **sandbox** aberto (cobranças e logs de webhook).
- Nomes de teste prefixados com `QA-024-` pra facilitar limpeza.

**Ordem sugerida:** Bloco A (rápido, pega regressão de rota) → B → C → D (billing, mais longo).

---

## Bloco A — Rotas públicas e privadas (regressão do refactor `isPublicPath`) 🔴 CRÍTICO

O guard de rotas públicas foi extraído do `Shell.tsx` pra `src/lib/publicPaths.ts`. Esse guard já
quebrou 4 vezes no passado (TASK-272/273/274, `/agendar`).

### A1 — Rotas públicas abrem **deslogado** (janela anônima)
Abrir cada uma e confirmar que **não** redireciona pro `/login` e não mostra sidebar/topbar:
`/landing`, `/agendar`, `/blog`, `/blog/nbr-5674-responsabilidade-sindico`, `/termos`, `/privacidade`,
`/fornecedores/cadastro`, `/fornecedores/gerenciar/<token-válido>`, `/para-fornecedores`,
`/para-fornecedores#politicas`, `/indicador/novo`, `/obrigado`.

**Esperado:** todas renderizam normalmente.

### A2 — Rotas privadas continuam protegidas (janela anônima)
Abrir `/items`, `/fornecedores` (marketplace logado), `/users`, `/private/admin/leads`.

**Esperado:** redirecionam pro login (as de `/private` pro `/private/login`).

### A3 — Logado como organização
Navegar em `/items`, `/fornecedores` e depois abrir `/para-fornecedores`.

**Esperado:** telas privadas com sidebar; `/para-fornecedores` abre em tela cheia, sem sidebar.

**Evidência:** print de 2–3 rotas públicas em janela anônima + print do redirect de uma privada.

---

## Bloco B — Página `/para-fornecedores` (TASK-285) 🟠 ALTO

### B1 — Conteúdo e navegação (desktop, ~1366px)
1. Abrir `/para-fornecedores` deslogado.
2. Conferir: hero com foto, "Por que participar" (4 cards), "Como funciona" (3 passos com mockup do
   card e da mensagem de WhatsApp), card de preço **R$ 15,99/mês · cerca de R$ 0,53 por dia**,
   seção de políticas (9 itens), FAQ (6 perguntas abrindo/fechando), CTA final.
3. Clicar em cada botão "Quero me cadastrar" (navbar, hero, preço, CTA final).
4. Clicar em "Como funciona" no hero.

**Esperado:** todos os botões levam a `/fornecedores/cadastro`; "Como funciona" rola até a seção
sem o título ficar escondido atrás da navbar.

### B2 — Texto das políticas bate com o sistema
Ler a seção de políticas. Conferir em especial:
- "Se o débito falhar": **"você tem 3 dias de tolerância após o vencimento… volta automaticamente
  assim que o pagamento for confirmado"** (depende da TASK-288 — validado no Bloco D).
- "Cancelamento": revogar no app do banco → perfil sai do marketplace (sai **na hora**).
- Nenhum número de prova social ("X prédios", "Y fornecedores").

### B3 — Mobile (390px, ou celular de verdade)
**Esperado:** sem scroll horizontal (arrastar pro lado não mexe a página); navbar mostra
"Cadastrar" numa linha só com o logo; preço "R$ 15,99/mês" não quebra; FAQ abre/fecha.

### B4 — Links de entrada
1. Footer da `/landing` → "Para fornecedores" → abre a página. **A navbar da landing não mudou.**
2. `/fornecedores/cadastro` → link "Como funciona e políticas" → abre `/para-fornecedores` já na seção
   de políticas.

### B5 — SEO / compartilhamento
1. `https://<front-staging>/sitemap.xml` contém `/para-fornecedores`.
2. `https://<front-staging>/para-fornecedores/opengraph-image` abre uma imagem 1200×630.
3. (Opcional) Colar o link da página no WhatsApp → preview com título e imagem.

### B6 — Tracking (se o Meta Pixel estiver configurado em staging)
Com a extensão **Meta Pixel Helper**: clicar em "Quero me cadastrar" → evento
`SupplierSignupClick`; concluir um cadastro em `/fornecedores/cadastro` → `CompleteRegistration`.
Se o Pixel não estiver configurado em staging, **validar em produção após o deploy** pelo Events
Manager.

**Evidência:** prints desktop + mobile; print do Pixel Helper (ou anotação "validar em prod").

---

## Bloco C — Kanban de pedidos do fornecedor (TASK-280) 🟠 ALTO

Pré-condição: um fornecedor **auto-cadastrado e ativo** em staging (tem link de gerenciamento) na
mesma cidade de uma organização de teste.

### C1 — Aviso LGPD e criação do pedido (lado da organização)
1. Logado como organização, `/fornecedores` → buscar o fornecedor → "Solicitar orçamento".
2. Conferir o texto abaixo do campo: *"Seu nome, e-mail e WhatsApp serão compartilhados com o
   fornecedor pra ele retornar o contato."*
3. Escrever `QA-024 pedido 1` e enviar.

**Esperado:** aviso visível; WhatsApp abre como antes; nenhum erro.

### C2 — Pedido aparece no kanban (lado do fornecedor)
1. Abrir `/fornecedores/gerenciar/<token>` do fornecedor (deslogado).

**Esperado:** abre na aba **"Pedidos (N)"**; o pedido está em **Novo** com nome da organização,
bairro/cidade, resumo, "hoje", nome de quem pediu, botões **WhatsApp** e **E-mail**.

### C3 — Mover entre colunas
1. "Mover para…" → Em contato → Orçamento enviado → Fechado → Perdido → Novo.
2. Recarregar a página (F5).

**Esperado:** o card muda de coluna na hora a cada passo, contadores atualizam, e depois do F5 o
status continua o último escolhido.

### C4 — Botões de contato
**Esperado:** WhatsApp abre `wa.me/55…` do solicitante com mensagem de retorno; E-mail abre o cliente
de e-mail com o endereço de quem pediu. Se o usuário da organização **não tem telefone** cadastrado,
o botão de WhatsApp não aparece (e-mail continua).

### C5 — Mobile (390px)
**Esperado:** filtros por coluna com rolagem lateral ("Novo 1 · Em contato 0 …"), lista da coluna
escolhida, sem scroll horizontal da página.

### C6 — Fornecedor sem pedidos / "Meus dados"
1. Link de gerenciamento de outro fornecedor sem pedidos.

**Esperado:** abre em **"Meus dados"**; aba "Pedidos (0)" mostra explicação + botão "Revisar meus
dados"; salvar alteração em "Meus dados" funciona como antes; se o pagamento estiver pendente, o QR
continua aparecendo **acima** das abas.

### C7 — Segurança: um fornecedor não mexe no pedido de outro 🔴
Com o token do fornecedor A e o `id` de um pedido do fornecedor B (pegar via
`GET …/manage/<token-B>/budget-requests`):
```bash
curl -i -X PATCH -H "Content-Type: application/json" -d '{"status":"WON"}' \
  https://api-staging.easymaintenance.com.br/easy-maintenance/api/v1/public/suppliers/manage/<TOKEN_A>/budget-requests/<ID_DO_B>
```
**Esperado:** `404`; o pedido do B continua com o status original.

Também: `{"status":"XYZ"}` no próprio pedido → `422`; token inválido → `404`.

**Evidência:** prints do kanban (desktop + mobile) e saída dos `curl`.

---

## Bloco D — Ciclo de cobrança do fornecedor (TASK-288) 🔴 CRÍTICO

Regra nova: `current_period_end` = "pago até" (só avança quando o pagamento do ciclo chega);
`last_charged_period_end` = período já cobrado. Suspensão: ciclo cobrado e **não pago** até
**fim do período + 6 dias** (3 de vencimento + 3 de tolerância) → `PAST_DUE` + fora do marketplace.

Use um fornecedor de teste **ACTIVE com autorização Pix Automático real no sandbox**
(`external_authorization_id` preenchido). Consulta de apoio:
```sql
SELECT s.supplier_id, s.status, s.current_period_end, s.last_charged_period_end,
       s.external_payment_id, s.external_authorization_id, sp.marketplace_enabled
FROM supplier_subscriptions s JOIN suppliers sp ON sp.id = s.supplier_id
WHERE s.supplier_id = <ID>;
```

### D1 — Cobrança do ciclo não avança o período
1. `UPDATE supplier_subscriptions SET current_period_end = CURDATE(), last_charged_period_end = NULL WHERE supplier_id = <ID>;`
2. Disparar o job `execute-supplier-billing`.

**Esperado:** nova cobrança no painel do Asaas sandbox (vinculada à autorização);
`external_payment_id` = id dessa cobrança; `last_charged_period_end` = hoje;
**`current_period_end` continua hoje** (antes avançava +1 mês).

### D2 — Sem cobrança dupla
Disparar o job de novo no mesmo dia.

**Esperado:** **nenhuma** cobrança nova no Asaas; nada muda no banco.

### D3 — Suspensão por falta de pagamento
1. `UPDATE supplier_subscriptions SET current_period_end = CURDATE() - INTERVAL 7 DAY, last_charged_period_end = CURDATE() - INTERVAL 7 DAY, status = 'ACTIVE' WHERE supplier_id = <ID>;`
   (e `UPDATE suppliers SET marketplace_enabled = 1 WHERE id = <ID>;`)
2. Disparar o job.

**Esperado:** `status = PAST_DUE`, `marketplace_enabled = 0`; o fornecedor **some** da busca em
`/fornecedores` (logado como organização da mesma cidade); a tela de gerenciamento mostra "Não
visível" / "Pagamento pendente"; log `[SupplierBilling] Supplier <ID> suspenso do marketplace…`.
**Nenhuma cobrança nova** é criada pra `PAST_DUE`.

### D4 — Ainda dentro da tolerância não suspende
Igual ao D3 mas com `CURDATE() - INTERVAL 5 DAY` nos dois campos.

**Esperado:** continua `ACTIVE` e visível.

### D5 — Ciclo nunca cobrado não suspende (falha nossa não pune o fornecedor)
`current_period_end = CURDATE() - INTERVAL 10 DAY`, `last_charged_period_end = NULL`,
`external_authorization_id = NULL` (num fornecedor de teste descartável) → job.

**Esperado:** continua `ACTIVE`/visível; log de "ACTIVE sem externalAuthorizationId — pulando
cobrança". (Restaurar o `external_authorization_id` depois, se for reaproveitar o fornecedor.)

### D6 — Pagamento do ciclo renova o período
1. A partir do estado do D1 (cobrança criada, `last_charged_period_end = current_period_end`),
   marcar a cobrança como paga no **Asaas sandbox** (simular pagamento da cobrança) de modo que
   chegue o webhook `PAYMENT_RECEIVED` com `externalReference = SUPPLIER-<ID>`.

**Esperado:** `current_period_end` = período anterior **+1 mês**; status `ACTIVE`; **nenhum** e-mail
de "cadastro ativo" reenviado; log `Ciclo pago pro supplierId=<ID> -- pago até …`.

⚠️ Se o sandbox não permitir simular o pagamento dessa cobrança de forma que gere
`PAYMENT_RECEIVED`, anotar e validar o D6/D7 no **primeiro ciclo real em produção** acompanhando o
log `[SupplierBilling]` (risco registrado abaixo).

### D7 — `PAST_DUE` que paga volta pro marketplace
Repetir o D6 a partir do estado do D3 (fornecedor `PAST_DUE` com a cobrança do ciclo pendente).

**Esperado:** `ACTIVE`, `marketplace_enabled = 1`, volta a aparecer na busca; `current_period_end`
+1 mês; log com "reativado no marketplace"; sem e-mail de ativação.

### D8 — Webhook duplicado não renova duas vezes
No painel do Asaas sandbox, **reenviar** o webhook `PAYMENT_RECEIVED` do D6.

**Esperado:** `current_period_end` **não** avança de novo.

### D9 — Regressão: cadastro novo continua ativando (fluxo da TASK-278)
Cadastrar `QA-024-fornecedor-novo` em `/fornecedores/cadastro`, pagar o QR no sandbox.

**Esperado:** fica `ACTIVE`, aparece no marketplace, recebe o e-mail "Seu cadastro no marketplace
está ativo" com o link de gerenciamento (igual antes).

### D10 — Assinaturas existentes não são afetadas
Antes de rodar qualquer UPDATE, anotar as assinaturas ACTIVE reais de staging
(`last_charged_period_end` = NULL). Rodar o job.

**Esperado:** nenhuma é suspensa; só as com `current_period_end <= hoje` recebem cobrança (como já
acontecia).

**Evidência:** saídas do SELECT antes/depois de cada cenário, prints das cobranças/webhooks no
Asaas sandbox, trecho do log `[SupplierBilling]`.

---

## Limpeza
- Pedidos de teste: `DELETE FROM supplier_budget_requests WHERE summary LIKE 'QA-024%';`
- Fornecedores `QA-024-*`: revogar autorização no sandbox / remover conforme o padrão dos QAs
  anteriores.
- Restaurar `current_period_end`/`status`/`marketplace_enabled` de fornecedores reaproveitados.

## Critério de aprovação pra promover `staging` → `main`
Blocos **A**, **C7** e **D1–D5, D9, D10** passando são obrigatórios. D6–D8 podem ser aprovados com a
ressalva de validação no primeiro ciclo real em produção, caso o sandbox não gere o
`PAYMENT_RECEIVED`. B6 pode ficar pra produção se o Pixel não existir em staging.

## Riscos conhecidos
- **D6–D8 dependem do sandbox gerar `PAYMENT_RECEIVED`** pra uma cobrança de Pix Automático. Se não
  gerar, a renovação só é provada em produção — acompanhar o primeiro ciclo de cada fornecedor.
- Fornecedor suspenso não tem caminho self-service pra pagar a cobrança atrasada se o Asaas não
  retentar o débito (hoje: admin reativa). Fora do escopo desta release.
- Link mágico não expira e agora dá acesso a contatos de quem pediu orçamento (risco aceito no spec
  da TASK-280).

## Status
Backlog — aguardando execução manual pelo Douglas em staging
