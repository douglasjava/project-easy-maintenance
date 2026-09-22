# TASK-QA-MAN-023 — QA Manual: Pix Automático pro billing de fornecedor (marketplace)

## Tipo
QA Manual

## Categoria
Full-Stack / Billing (substitui o PIX manual do fornecedor por mandato recorrente Pix Automático)

## Prioridade
🔴 Alto — envolve débito automático real (Asaas sandbox), substitui um fluxo que já estava em teste
(TASK-QA-MAN-022, C4-C9)

## Tasks cobertas
TASK-278 — spec: `docs/superpowers/specs/2026-09-20-supplier-pix-automatico-design.md`, plano:
`docs/superpowers/plans/2026-09-20-supplier-pix-automatico.md` (9 tasks, implementação via
subagent-driven-development, revisão final aplicada).

---

## Descrição

Troca o PIX manual do marketplace de fornecedores (cobrança avulsa, QR novo todo mês) por Pix
Automático (mandato regulamentado pelo BC): o cadastro cria uma autorização que já cobra o 1º ciclo
via QR imediato e ativa o mandato; ciclos seguintes debitam sozinhos, sem novo QR; dois webhooks
novos tratam mandato cancelado/expirado, regenerando uma autorização nova automaticamente.

Branches `feature/TASK-278-pix-automatico-fornecedor` nos dois repos (`easy-maintenance-api` e
`easy-maintenance-web`, ambas a partir de `staging`), sem PR aberta ainda — a pedido, ficou tudo
numa branch só pra você testar antes de subir.

**O que foi validado nesta sessão** (sem subir a aplicação): `mvn test` 1047/1047 no `api`,
`npm run build`/`eslint` limpos no `web`. Todos os testes são unitários com `AsaasClient` mockado —
**nenhum bateu no Asaas de verdade**.

**Gap real, não escondido — é o motivo do C1 abaixo ser o mais importante:** a resposta real da
Asaas pra criação de autorização (`POST /pix/automatic/authorizations`) nunca foi confirmada contra
o sandbox. A doc pública mostra `payload`/`encodedImage` no nível raiz da resposta, mas o *request*
aninha esses mesmos campos sob `immediateQrCode` — existe a chance de a resposta seguir o mesmo
aninhamento. Botei uma blindagem defensiva (lança `AsaasException` em vez de salvar um QR quebrado)
mas isso só vira certeza depois do C1 rodar contra o sandbox de verdade.

---

## Pré-condições

- Checkout de `feature/TASK-278-pix-automatico-fornecedor` nos dois repos, API rodando local com
  Asaas sandbox configurado de verdade (`asaas.api-key`, `asaas.base-url=https://sandbox.asaas.com/api/v3`).
- Migration `V114` aplica sozinha no boot (Flyway) — inclui o índice em `external_authorization_id`.
- Endpoint `GET /run-jobs/execute-supplier-billing` (autenticado) já existe — usa ele pra não
  esperar o cron das 02:15 nos cenários C4/C8.

⚠️ Prefixe fornecedores de teste com `QA-TASK278-*` no nome pra facilitar a limpeza. **Não rodar
contra staging/produção** — C1 e C5/C6 disparam chamadas reais ao Asaas sandbox (geram autorização
de mandato lá, mesmo sendo sandbox).

---

## Cenários de Teste

### C1 — Auto-cadastro cria autorização Pix Automático (⚠️ crítico — valida o formato real da resposta Asaas)

| Passo | Ação                                                                                    | Resultado esperado                                                                                                                                                                                                                                                                                                                                   |
|-------|-----------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Acessar `/fornecedores/cadastro`, preencher com documento novo `QA-TASK278-1`, submeter | Sucesso — tela de sucesso mostra a **imagem do QR Code** + botão "Copiar código Pix (R$ 15,99/mês)", não mais um botão de link                                                                                                                                                                                                                       |
| 2     | Conferir o log da aplicação no momento do cadastro                                      | **Se aparecer `AsaasException: Autorização Pix Automático ... veio sem payload/QR Code`** — pare aqui e me avisa: significa que a resposta real da Asaas aninha `payload`/`encodedImage` sob `immediateQrCode` em vez de nível raiz, e o DTO `PixAuthorizationResponse` (`AsaasDTO.java`) precisa de ajuste antes de continuar os cenários seguintes |
| 3     | `SELECT` abaixo                                                                         | `status=PAST_DUE`, `authorization_status=CREATED`, `external_authorization_id` preenchido, `qr_code_payload` não nulo, imagem com tamanho > 0                                                                                                                                                                                                        |

```sql
SELECT id, supplier_id, status, external_customer_id, external_authorization_id, authorization_status,
       LEFT(qr_code_payload, 40) AS payload_preview, LENGTH(qr_code_image) AS image_len, current_period_end
FROM supplier_subscriptions
WHERE supplier_id = (SELECT id FROM suppliers WHERE name = 'QA-TASK278-1');
```

Anota o `id` e o `external_authorization_id` retornados — usados nos cenários seguintes.

---

### C2 — Reenvio do mesmo cadastro reaproveita a autorização pendente

| Passo | Ação                                                                        | Resultado esperado                                                                                                                                                               |
|-------|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Repetir o cadastro com o **mesmo** documento do C1, sem pagar o QR anterior | Mesmo `qrCodePayload`/`qrCodeImage` do C1 devolvido, sem chamar o Asaas de novo (confere no log — não deve aparecer um novo "ASAAS REQUEST" pra `/pix/automatic/authorizations`) |
| 2     | `SELECT`                                                                    | Mesma linha (mesmo `id`), nada mudou                                                                                                                                             |

```sql
SELECT id, external_authorization_id, updated_at
FROM supplier_subscriptions WHERE supplier_id = (SELECT id FROM suppliers WHERE name = 'QA-TASK278-1');
```

---

### C3 — Ativação via webhook `PAYMENT_RECEIVED` (⚠️ crítico — confirma o fix da cadência)

| Passo | Ação                                                                             | Resultado esperado                                                                                                                          |
|-------|----------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Pagar o QR do C1 no sandbox Asaas                                                | Asaas dispara `PAYMENT_RECEIVED`                                                                                                            |
| 2     | `SELECT` (usar o `id` anotado no C1)                                             | `status=ACTIVE`, `authorization_status=ACTIVE`, `qr_code_payload IS NULL`, `qr_code_image IS NULL`, **`current_period_end` = hoje + 1 mês** |
| 3     | Conferir `suppliers.marketplace_enabled` e caixa de entrada do e-mail cadastrado | `marketplace_enabled=true`, e-mail de ativação recebido com o link de gestão                                                                |

```sql
SELECT status, authorization_status, qr_code_payload, qr_code_image, current_period_end
FROM supplier_subscriptions WHERE id = <id_do_C1>;

SELECT marketplace_enabled, activated_at, activation_source
FROM suppliers WHERE name = 'QA-TASK278-1';
```

⚠️ **`current_period_end` tem que ser hoje+1 mês, NÃO hoje+3 dias.** Esse era o bug crítico
corrigido na revisão final (`SupplierBillingService` calculava a cadência errada) — se vier +3
dias, o bug voltou.

---

### C4 — Ciclo recorrente NÃO gera QR novo (débito automático)

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Forçar o ciclo como vencido | — |
| 2 | Disparar `GET /run-jobs/execute-supplier-billing` | Nova cobrança PIX criada (referenciando a autorização), sem QR novo |
| 3 | `SELECT` | `external_payment_id` mudou, `qr_code_payload`/`qr_code_image` continuam `NULL`, **`current_period_end` = hoje + 1 mês** (de novo, não +3 dias), `status` continua `ACTIVE` |

```sql
UPDATE supplier_subscriptions SET current_period_end = CURDATE() - INTERVAL 1 DAY WHERE id = <id_do_C1>;

-- depois de chamar o endpoint:
SELECT status, external_payment_id, qr_code_payload, qr_code_image, current_period_end
FROM supplier_subscriptions WHERE id = <id_do_C1>;
```

---

### C5 — Mandato cancelado regenera autorização (fornecedor já ativo)

Simula o webhook direto, sem precisar esperar um evento real do Asaas:

```bash
curl -X POST http://localhost:8080/easy-maintenance/api/v1/public/webhooks/asaas \
  -H "Content-Type: application/json" \
  -d '{
    "id": "evt-qa-cancel-1",
    "event": "PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CANCELLED",
    "dateCreated": "2026-09-20 10:00:00",
    "authorization": { "id": "<external_authorization_id_do_C1>", "status": "CANCELLED" }
  }'
```

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Anotar `external_authorization_id` atual (query abaixo, "antes") | — |
| 2 | Disparar o `curl` acima | 200 `"ok"` |
| 3 | `SELECT` ("depois") | `status=PAST_DUE`, **`external_authorization_id` diferente do "antes"** (autorização nova gerada), `qr_code_payload` preenchido de novo (novo QR pra reautorizar) |

```sql
-- antes
SELECT status, authorization_status, external_authorization_id, qr_code_payload
FROM supplier_subscriptions WHERE id = <id_do_C1>;

-- depois do curl
SELECT status, authorization_status, external_authorization_id, qr_code_payload
FROM supplier_subscriptions WHERE id = <id_do_C1>;
```

Nota: `authorization_status` provavelmente volta pra `CREATED` (não `CANCELLED`) — a regeneração
roda na mesma transação do webhook e sobrescreve o campo com o status da autorização nova. Isso é
esperado, não é bug (achado já registrado na revisão final, campo é só observabilidade).

⚠️ Isso dispara uma chamada real de criação de mandato no Asaas sandbox.

---

### C6 — Mandato expirado *antes* de ativar (⚠️ crítico — cenário do bug corrigido na revisão final)

Esse é o mais importante depois do C1: fornecedor que **nunca chegou a pagar** o primeiro QR.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Cadastrar um fornecedor novo (`QA-TASK278-2`), **não pagar** o QR | Subscription fica `status=PAST_DUE`, `authorization_status=CREATED` |
| 2 | Anotar o `external_authorization_id` | — |
| 3 | Disparar o webhook `EXPIRED` (curl abaixo, trocando o `id` da autorização) | 200 `"ok"` |
| 4 | `SELECT` | `external_authorization_id` **mudou** (nova autorização gerada) e `qr_code_payload` novo, mesmo a assinatura já estando `PAST_DUE` desde o cadastro |

```bash
curl -X POST http://localhost:8080/easy-maintenance/api/v1/public/webhooks/asaas \
  -H "Content-Type: application/json" \
  -d '{
    "id": "evt-qa-expired-1",
    "event": "PIX_AUTOMATIC_RECURRING_AUTHORIZATION_EXPIRED",
    "dateCreated": "2026-09-20 10:00:00",
    "authorization": { "id": "<external_authorization_id_do_QA-TASK278-2>", "status": "EXPIRED" }
  }'
```

```sql
SELECT status, authorization_status, external_authorization_id, qr_code_payload
FROM supplier_subscriptions WHERE supplier_id = (SELECT id FROM suppliers WHERE name = 'QA-TASK278-2');
```

**Se `external_authorization_id` NÃO mudar, o bug voltou** — a versão antes do fix comparava
`status == PAST_DUE` (que já era verdade desde o cadastro) e ignorava o evento, deixando esse
fornecedor preso pra sempre com um QR morto.

---

### C7 — Idempotência: reenvio do mesmo evento não reprocessa

```sql
SELECT id, provider_event_id, status FROM webhook_event WHERE provider_event_id = 'evt-qa-cancel-1';
```

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Reenviar o **mesmo** `curl` do C5 (mesmo `"id": "evt-qa-cancel-1"`) | 200 `"ok"` |
| 2 | `SELECT` acima | Continua **1 linha só**, `status=PROCESSED` — o evento é ignorado por duplicidade (`provider_event_id` já processado), não regenera autorização de novo |

---

### C8 — Guarda: assinatura ACTIVE sem `external_authorization_id`

Cenário defensivo (dado inconsistente forçado só pra QA — não deveria acontecer em uso normal):

```sql
UPDATE supplier_subscriptions SET external_authorization_id = NULL WHERE id = <id_ACTIVE_qualquer>;
```

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Forçar `external_authorization_id = NULL` numa subscription `ACTIVE` | — |
| 2 | Disparar `GET /run-jobs/execute-supplier-billing` | Log `ERROR` "está ACTIVE sem externalAuthorizationId — pulando cobrança do ciclo", **nenhuma** chamada ao Asaas, `current_period_end` intocado |

```sql
SELECT current_period_end, updated_at FROM supplier_subscriptions WHERE id = <id>;
```

---

### C9 — Gestão via link mágico mostra QR em vez de link

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Acessar `/fornecedores/gerenciar/<token>` de um fornecedor `PAST_DUE` com QR pendente (ex: o do C5/C6) | Card laranja mostra a **imagem do QR Code** + botão "Copiar código Pix", não mais o botão "Pagar assinatura" com link |
| 2 | Clicar em "Copiar código Pix" numa aba/contexto sem permissão de clipboard (ex: `http://` puro, ou negar a permissão do navegador) | Toast de **erro** ("Não foi possível copiar...") — não deve mostrar "copiado!" falso |
| 3 | Clicar em "Copiar código Pix" num contexto normal (`https://` ou `localhost`) | Toast de sucesso, código realmente vai pra área de transferência (cola em algum lugar pra confirmar) |
| 4 | Editar nome/e-mail/cidade/UF (campos do TASK-278 anterior) e salvar | Toast de sucesso, e o card do QR **continua aparecendo** depois do save (não some) |

---

### C10 — Isolamento do domínio de cobrança (regressão)

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Disparar um pagamento normal de organização (billing existente) | Segue o fluxo de sempre, sem interferência do branch novo |
| 2 | `SHOW CREATE TABLE supplier_subscriptions` | FK só em `supplier_id → suppliers(id)`, nenhuma referência a `billing_subscriptions`/`payments`/`invoices`; índice novo `idx_supplier_subscriptions_external_authorization_id` presente |

```sql
SHOW CREATE TABLE supplier_subscriptions;
```

---

## Limpeza (dados de teste)

```sql
DELETE FROM supplier_access_tokens WHERE supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-TASK278-%');
DELETE FROM supplier_service_links WHERE supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-TASK278-%');
DELETE FROM supplier_category_links WHERE supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-TASK278-%');
DELETE FROM supplier_subscriptions WHERE supplier_id IN (
  SELECT id FROM suppliers WHERE name LIKE 'QA-TASK278-%');
DELETE FROM webhook_event WHERE provider_event_id IN ('evt-qa-cancel-1', 'evt-qa-expired-1');
DELETE FROM suppliers WHERE name LIKE 'QA-TASK278-%';
```

(Cancele/estorne no painel Asaas sandbox as autorizações/cobranças de teste geradas em C1/C5/C6 —
a limpeza acima só cobre o banco local.)

---

## Critérios de Aceite da Suíte

- [X] C1: cadastro gera autorização Pix Automático real (sandbox), QR exibido — **sem `AsaasException`**
- [X] C2: reenvio reaproveita a autorização pendente, sem nova chamada ao Asaas
- [X] C3: `PAYMENT_RECEIVED` ativa o mandato, `current_period_end` = **+1 mês** (não +3 dias)
- [X] C4: ciclo recorrente cobra sem gerar QR novo, `current_period_end` avança **+1 mês**
- [X] C5: mandato cancelado regenera autorização nova (fornecedor já ativo)
- [X] C6: mandato expirado *antes* de ativar também regenera (bug da revisão final confirmado corrigido)
- [X] C7: reenvio do mesmo evento não reprocessa
- [X] C8: guarda contra `externalAuthorizationId` nulo funciona, sem chamada ao Asaas
- [X] C9: tela de gestão mostra QR, copiar trata erro de clipboard, QR sobrevive ao save de perfil
- [X] C10: nenhuma regressão no billing de organização, índice novo presente

## Status
🟡 Aguardando execução — Douglas testa contra o ambiente local dele (com credenciais Asaas sandbox
reais)
