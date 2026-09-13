# TASK-QA-MAN-022 — QA Manual: EPIC-028 Fase 2 (Marketplace de Fornecedores)

## Tipo
QA Manual

## Categoria
Full-Stack / Monetização (novo domínio de cobrança + 2 páginas públicas novas)

## Prioridade
🔴 Alto — envolve dinheiro real (cobrança Asaas) e páginas públicas novas, sem login

## Tasks cobertas
[TASK-260](../../tasks/TASK-260.md) (CPF/CNPJ + campos de marketplace) /
[TASK-261](../../tasks/TASK-261.md) (entidades de cobrança) /
[TASK-262](../../tasks/TASK-262.md) (gating de visibilidade) /
[TASK-263](../../tasks/TASK-263.md) (Solicitar Orçamento) /
[TASK-264](../../tasks/TASK-264.md) (auto-cadastro + PIX) /
[TASK-265](../../tasks/TASK-265.md) (ativação via webhook) /
[TASK-266](../../tasks/TASK-266.md) (gestão via link mágico) /
[TASK-267](../../tasks/TASK-267.md) (job mensal de cobrança) /
[TASK-268](../../tasks/TASK-268.md) (ativação manual admin) /
[TASK-269](../../tasks/TASK-269.md) (frontend `/fornecedores`) /
[TASK-270](../../tasks/TASK-270.md) (frontend auto-cadastro) /
[TASK-271](../../tasks/TASK-271.md) (frontend gestão via link) — [EPIC-028](../../epics/EPIC-028.md)
Fase 2

---

## Descrição

Abre o cadastro de fornecedores (EPIC-028 v1, já em produção) como marketplace pago: o cadastro
feito pelo síndico continua 100% livre e funcionando como sempre; um fornecedor só fica visível
pra **outras** organizações se pagar R$15,99/mês (PIX) ou for ativado manualmente pela equipe
(fechou por fora). Fornecedor pago pode ser "chamado" direto pelo grid — botão "Solicitar
Orçamento" abre o WhatsApp com mensagem pronta.

Toda a implementação está nas branches `feature/EPIC-028-fase2-marketplace` (nos dois repos,
`easy-maintenance-api` e `easy-maintenance-web`, ambas criadas a partir de `staging`), sem PR
aberta ainda — mesmo padrão dos épicos anteriores, esperando esta aprovação antes de abrir.

**Nada foi validado contra um ambiente rodando de verdade nesta sessão** — sem credenciais Asaas
(sandbox) nem SMTP real configuradas aqui. O que foi validado sem subir a aplicação:
- Backend: `mvn test` sem regressão em nenhuma das 9 tasks (suíte completa rodada várias vezes ao
  longo da implementação, sempre verde). Migrations `V111`/`V112` validadas contra o MySQL real do
  seu docker local (aplicadas e revertidas) — inclusive um bug real de collation encontrado e
  corrigido nesse processo (FK de `supplier_budget_requests.organization_code`).
- Frontend: `npm run build`/`eslint` limpos nas 3 tasks; `npm test` sem regressão nova (107/110 —
  as 3 falhas de `middleware.test.ts` são pré-existentes, não relacionadas).
- Testes unitários novos: 9 classes de teste no backend (services + o branch novo do webhook),
  todos mockados (Asaas, e-mail, repositórios) — nenhum bateu no Asaas de verdade nem enviou e-mail
  real.

**Gaps reais, não escondidos:**
1. Todo o fluxo de pagamento (cobrança PIX gerada, webhook confirmando, e-mail de ativação
   enviado) depende de credenciais Asaas + SMTP reais — **nada disso rodou de ponta a ponta nesta
   sessão**. É o ponto mais crítico pra você validar (ver C4/C5 abaixo).
2. O job `SupplierBillingJob` (cobrança do próximo ciclo + suspensão por atraso) não tem endpoint
   de disparo manual — só roda pelo cron (`02:15`) ou você chama os métodos do serviço direto numa
   ferramenta de admin/console, se preferir não esperar o horário.
3. Nenhuma das 3 páginas novas/alteradas do frontend foi aberta num navegador real nesta sessão —
   só `npm run build`/`eslint` (compilação e lint, não renderização).

---

## Pré-condições

- Checkout de `feature/EPIC-028-fase2-marketplace` nos dois repos, API e frontend rodando local
  (perfil com credenciais reais — Asaas sandbox e SMTP, pra C4/C5/C7 funcionarem de verdade).
- Migrations `V111`/`V112` aplicam sozinhas no boot (Flyway) — já validadas contra o MySQL real do
  seu docker nesta sessão, revertidas depois pra não conflitar com o Flyway do boot real.
- Pra C1/C2 (visibilidade entre organizações), usar duas organizações de teste distintas — a que
  cadastrou o fornecedor e uma segunda, sem vínculo.

⚠️ Se criar dado novo manualmente, prefixe fornecedores de teste com `QA-EPIC028F2-*` no nome pra
facilitar a limpeza depois. **Não rodar contra staging/produção**, e cuidado especial aqui porque
C4 dispara uma cobrança PIX real no Asaas (mesmo em sandbox, gera registro lá).

---

## Cenários de Teste

### C1 — Suítes automatizadas, sem regressão

| Passo | Ação                                                                               | Resultado esperado                                                                                                                                                                         |
|-------|------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | `mvn test` na branch `feature/EPIC-028-fase2-marketplace` (`easy-maintenance-api`) | PASS, sem regressão em nenhum módulo (inclusive `PaymentReceivedHandlerTest` já existente — fluxo de organização intocado)                                                                 |
| 2     | `npm run build` e `npm test` na branch equivalente (`easy-maintenance-web`)        | Build limpo (rotas `/fornecedores`, `/fornecedores/cadastro`, `/fornecedores/gerenciar/[token]` geradas); jest 107/110 (3 falhas pré-existentes em `middleware.test.ts`, não relacionadas) |
| 3     | `npx eslint src/app/fornecedores/` (`easy-maintenance-web`)                        | Sem erros                                                                                                                                                                                  |

Já executado e confirmado durante a implementação.

---

### C2 — Cadastro pelo síndico continua livre (regressão do EPIC-028 v1)

| Passo | Ação                                                                                                                             | Resultado esperado                                                                                                                                                                                        |
|-------|----------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Logado numa organização A, ir em `/fornecedores`, cadastrar um fornecedor novo com CPF válido (ex: gerar um CPF de teste válido) | Cadastra normalmente, sem cobrança, `registrationCount = 1`, aparece na lista da própria organização                                                                                                      |
| 2     | Repetir o cadastro com um CNPJ válido                                                                                            | Também aceita — campo agora é "CPF ou CNPJ", máscara ajusta sozinha ao tamanho digitado                                                                                                                   |
| 3     | Logado numa organização B (diferente, mesma cidade/estado), cadastrar o **mesmo** documento do passo 1                           | Não duplica — só cria o vínculo, mesmo comportamento já existente da TASK-242; `registrationCount` sobe pra 2                                                                                             |
| 4     | Ainda em B, ir em `/fornecedores` e buscar por essa região                                                                       | **Não aparece** o fornecedor do passo 1 pra B, a menos que B tenha sido quem cadastrou ou vinculou — é o gating novo (TASK-262): só aparece pra quem cadastrou/vinculou, ou se `marketplace_enabled=true` |
| 5     | Voltar pra organização A                                                                                                         | O fornecedor cadastrado por A continua aparecendo normalmente pra A, mesmo sem pagar                                                                                                                      |

---

### C3 — "Solicitar Orçamento"

| Passo | Ação                                                                                                            | Resultado esperado                                                                                           |
|-------|-----------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| 1     | Na lista de fornecedores (`/fornecedores`), clicar "Solicitar Orçamento" num fornecedor com telefone cadastrado | Abre modal pedindo o resumo da necessidade                                                                   |
| 2     | Preencher o resumo e confirmar                                                                                  | Toast/fechamento do modal, e uma nova aba abre com `wa.me/55<telefone>?text=...` com a mensagem pronta       |
| 3     | Conferir no backend (`supplier_budget_requests`)                                                                | Linha nova gravada com `organization_code`/`requested_by_user_id`/`summary` corretos                         |
| 4     | Repetir com um fornecedor **sem** telefone cadastrado                                                           | Solicitação é registrada normalmente, mas não tenta abrir o WhatsApp (sem `phone`, o `window.open` é pulado) |
| 5     | Testar no mobile (viewport estreito)                                                                            | Botão aparece no card, mesmo comportamento                                                                   |

---

### C4 — Auto-cadastro público + cobrança PIX (⚠️ crítico — dinheiro real/sandbox)

> **🔴 Bug bloqueante encontrado por Douglas (13/09/2026) e corrigido:** `/fornecedores/cadastro`
> redirecionava pro `/login` em vez de renderizar publicamente. Causa raiz: `Shell.tsx` guarda toda
> rota fora de uma allowlist (`isAuth`) atrás de login client-side (`middleware.ts` não protege
> nada — é só client-side, ver comentário no próprio arquivo). As páginas novas
> `/fornecedores/cadastro` e `/fornecedores/gerenciar/[token]` não estavam nessa allowlist. Corrigido
> em `feature/EPIC-028-fase2-marketplace` (repo `web`), commit `TASK-272` — adicionadas as duas
> rotas na allowlist, mesmo padrão já usado pra `/chamados/`.
>
> **🔴 Segundo bug bloqueante, mesma sessão de teste:** com o frontend destravado, `POST
> /public/suppliers/register` retornava `403 Forbidden` do backend. Causa raiz: `SecurityConfig`
> nunca foi atualizado com `/public/suppliers/**` na lista de rotas liberadas. Corrigido em
> `feature/EPIC-028-fase2-marketplace` (repo `api`), commit `TASK-273`. **Repita o teste do C4/C6 a
> partir desta correção.**

| Passo | Ação                                                                                    | Resultado esperado                                                                                                     |
|-------|-----------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| 1     | Acessar `/fornecedores/cadastro` (sem estar logado, aba anônima)                        | Formulário público: CPF/CNPJ, nome, e-mail, telefone, categoria                                                        |
| 2     | Preencher com dados válidos e um documento **novo** (nunca cadastrado antes) e submeter | Cria o `Supplier`, gera cliente + cobrança PIX no Asaas, mostra tela "Quase lá!" com o link de pagamento (R$15,99/mês) |
| 3     | Abrir o link de pagamento                                                               | Deve ser um checkout PIX válido do Asaas (sandbox), vencimento em 3 dias                                               |
| 4     | Repetir o cadastro com o **mesmo** documento do passo 2                                 | Reaproveita o `Supplier` existente (não duplica), gera uma nova cobrança pro mesmo fornecedor                          |
| 5     | Tentar submeter 6 vezes seguidas do mesmo IP em menos de 1 hora                         | A partir da 6ª, deve ser bloqueado pelo rate limit (`supplier-self-register`: 5/hora/IP)                               |
| 6     | Tentar submeter com CPF/CNPJ inválido                                                   | Erro de validação no campo, sem chamar o backend                                                                       |

---

### C5 — Ativação via webhook (⚠️ crítico — depende de pagamento confirmado)

| Passo | Ação                                                                                                         | Resultado esperado                                                                                                                                            |
|-------|--------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Pagar a cobrança PIX gerada no C4 (sandbox Asaas)                                                            | Asaas dispara o webhook `PAYMENT_RECEIVED` pra sua API                                                                                                        |
| 2     | Conferir o `Supplier` no banco                                                                               | `marketplace_enabled = true`, `activated_at` preenchido, `activation_source = SELF_REGISTERED`                                                                |
| 3     | Conferir a caixa de entrada do e-mail cadastrado                                                             | E-mail de boas-vindas recebido, com o link `/fornecedores/gerenciar/<token>`                                                                                  |
| 4     | Logado numa organização diferente da que cadastrou (se aplicável) ou em qualquer organização da mesma região | O fornecedor agora **aparece** na busca — confirma que o gating do C2 realmente libera após a ativação                                                        |
| 5     | Reenviar o mesmo webhook (simular reentrega do Asaas)                                                        | Idempotente — não duplica o token de acesso nem reenvia o e-mail (`SupplierPaymentActivationServiceTest` cobre isso via mock, mas vale confirmar no log real) |

---

### C6 — Gestão via link mágico

| Passo | Ação                                                                                               | Resultado esperado                                                          |
|-------|----------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| 1     | Acessar `/fornecedores/gerenciar/<token>` com o token recebido no C5                               | Mostra nome, badge "Visível no marketplace", status da assinatura ("Ativa") |
| 2     | Alterar telefone e categoria, salvar                                                               | Toast de sucesso, dados refletem na tela                                    |
| 3     | Conferir em `/fornecedores` (organização que enxerga o fornecedor)                                 | Telefone/categoria atualizados aparecem na busca                            |
| 4     | Acessar `/fornecedores/gerenciar/token-invalido-qualquer-coisa`                                    | Mensagem "Link inválido ou expirado", sem quebrar a página                  |
| 5     | Tentar mais de 30 requisições em 1 minuto pro mesmo endpoint (script simples ou recarregar rápido) | Rate limit (`supplier-manage`: 30/min/IP) bloqueia a partir da 31ª          |

---

### C7 — Job mensal de cobrança + suspensão por atraso

| Passo | Ação                                                                                                                     | Resultado esperado                                                                                                                                                     |
|-------|--------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Com a assinatura `ACTIVE` do C5, adiantar manualmente `current_period_end` no banco pra ontem (ou aguardar o ciclo real) | No próximo disparo do `SupplierBillingJob` (cron `02:15`, ou chamando `processDueCycles()` manualmente), gera nova cobrança PIX, `currentPeriodEnd` avança             |
| 2     | Simular uma assinatura `PAST_DUE` com `current_period_end` há mais de 3 dias (prazo de graça)                            | `suspendOverdueSubscriptions()` desliga `marketplace_enabled` — fornecedor some da busca de outras organizações (mas continua visível pra quem cadastrou, regra do C2) |
| 3     | Conferir os logs do job                                                                                                  | `[SupplierBillingJob] Lock adquirido...`/`Execução concluída` — shedlock evita execução duplicada se rodar em mais de uma instância                                    |

---

### C8 — Ativação/desativação manual (admin)

| Passo | Ação                                                                                                                             | Resultado esperado                                                                                                       |
|-------|----------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| 1     | Com um fornecedor cadastrado pelo síndico (sem pagar), chamar `POST /private/admin/suppliers/{id}/activate` com o token de admin | `marketplace_enabled = true`, `activation_source = MANUALLY_ACTIVATED`, `activated_at` preenchido — sem cobrança nenhuma |
| 2     | Conferir que o fornecedor passa a aparecer pra outras organizações                                                               | Sim, mesmo gating do C2/C5                                                                                               |
| 3     | Chamar `POST /private/admin/suppliers/{id}/deactivate`                                                                           | `marketplace_enabled = false` — volta a só aparecer pra quem cadastrou                                                   |
| 4     | Chamar qualquer um dos dois endpoints sem o header de autenticação admin                                                         | Bloqueado pelo filtro de admin (mesmo comportamento do resto do `/private/admin/`)                                       |
| 5     | Chamar com um `id` inexistente                                                                                                   | 404 (`NotFoundException`)                                                                                                |

---

### C9 — Isolamento do domínio de cobrança (regressão do billing de organização)

| Passo | Ação                                                                                                                                          | Resultado esperado                                                                                                                                      |
|-------|-----------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Disparar um pagamento normal de organização (billing existente, cartão ou PIX)                                                                | Segue o fluxo de sempre, sem nenhuma interferência do branch novo (`externalReference` não começa com `SUPPLIER-`)                                      |
| 2     | Conferir que nenhuma tabela de billing de organização (`billing_subscriptions`, `payments`, etc.) foi tocada pelas migrations/entidades novas | Domínio `supplier_billing` é isolado — tabelas próprias (`supplier_subscriptions`, `supplier_access_tokens`), sem FK cruzada com billing de organização |

---

## Limpeza (dados de teste)

```sql
-- Ajuste os IDs/documentos conforme o que você usou nos cenários
DELETE FROM supplier_budget_requests WHERE summary LIKE 'QA-EPIC028F2%' OR supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-EPIC028F2%');
DELETE FROM supplier_access_tokens WHERE supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-EPIC028F2%');
DELETE FROM supplier_subscriptions WHERE supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-EPIC028F2%');
DELETE FROM supplier_organization_links WHERE supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-EPIC028F2%');
DELETE FROM suppliers WHERE name LIKE 'QA-EPIC028F2%';
```
(Cancele/estorne no painel Asaas sandbox as cobranças de teste geradas no C4, se aplicável — a
limpeza acima só cobre o banco local.)

---

## Critérios de Aceite da Suíte

- [X] C1: suítes automatizadas sem regressão (backend + frontend build/eslint/test)
- [X] C2: cadastro do síndico continua livre; gating de visibilidade funciona nos dois sentidos
- [X] C3: "Solicitar Orçamento" registra a solicitação e abre o WhatsApp corretamente
- [ ] C4: auto-cadastro público gera cobrança PIX real (sandbox), rate limit funciona
- [ ] C5: webhook de pagamento ativa o marketplace + envia o e-mail com o link mágico
- [ ] C6: gestão via link mágico funciona, token inválido tratado, rate limit funciona
- [ ] C7: job mensal gera nova cobrança e suspende por atraso além do prazo de graça
- [ ] C8: ativação/desativação manual pelo admin funciona, autenticado corretamente
- [ ] C9: nenhuma regressão no billing de organização existente

## Status
🟡 Aguardando execução — Douglas testa contra o ambiente real dele (com credenciais Asaas
sandbox/SMTP verdadeiras), igual ao padrão dos épicos anteriores. Sem PR aberta até esta aprovação.
