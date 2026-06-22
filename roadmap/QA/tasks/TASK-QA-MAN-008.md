# TASK-QA-MAN-008 — Validação End-to-End do Sistema de Indicação (EPIC-012)

## Tipo
QA Manual

## Categoria
Full-Stack / Afiliados / Comissões

## Prioridade
🟠 Alto

## Épico
EPIC-012 — Sistema de Indicação (Affiliate Referral)

---

## Descrição

Validação completa do fluxo de indicação de afiliados, do cadastro ao pagamento da comissão. Cobre os 8 passos do ciclo de vida: registro do afiliado → rastreio via landing page → criação de organização com atribuição → primeiro pagamento → geração da comissão → pagamento manual pelo admin.

---

## Pré-condições

- Acesso ao sistema em ambiente de staging/produção
- Acesso ao painel admin (`/private/admin`)
- Acesso ao banco de dados (DBeaver, TablePlus ou psql/mysql)
- Acesso a dois e-mails distintos: um para o afiliado, um para o prospect
- Webhook do Asaas configurado e funcional em staging

---

## Fluxo Completo — Visão Geral

```
1. Afiliado se cadastra → recebe link único
2. Prospect acessa o link → cookie em_ref setado
3. Prospect envia e-mail no form da landing → LandingLead salvo com affiliateCode
4. Admin cria a conta do prospect → referralCode auto-preenchido (ou manual)
5. Prospect faz onboarding + escolhe plano
6. Prospect realiza o primeiro pagamento (cycleNumber=1)
7. Webhook PAYMENT_RECEIVED → ReferralCommission gerada (PENDING)
8. Admin vê a comissão, paga o PIX e marca como PAID
```

---

## Passo 1 — Cadastro do Afiliado

**URL:** `/indicador/novo`

### Ações
1. Acessar `/indicador/novo`
2. Preencher: Nome = "Afiliado Teste", E-mail = `afiliado@teste.com`, WhatsApp = `31999999999`
3. Clicar em "Gerar meu link de indicação"

### Verificações
- [ ] Botão exibe spinner durante o submit
- [ ] Estado de sucesso exibido com ícone 🎉
- [ ] Link gerado no formato `https://easymaintenance.com.br/landing?ref=XXXXXX` (6 chars uppercase)
- [ ] Botão "Copiar link" copia para a área de transferência
- [ ] Link "Ver meu painel de indicações" navega para `/indicador/XXXXXX`

### Verificação no banco
```sql
SELECT id, name, email, code, commission_rate, status, created_at
FROM affiliates
WHERE email = 'afiliado@teste.com';
```
Esperado: 1 registro com `status = 'ACTIVE'`, `commission_rate = 0.2000`, `code` com 6 chars.

### Erro: e-mail duplicado
1. Tentar cadastrar novamente com o mesmo e-mail
2. Verificar que o botão não trava e que mensagem de erro inline aparece (não crash)

---

## Passo 2 — Rastreio na Landing Page (cookie)

**URL:** `/landing?ref=XXXXXX` (substituir pelo código gerado no Passo 1)

### Ações
1. Abrir uma aba anônima
2. Acessar `/landing?ref=XXXXXX`

### Verificações
- [ ] Cookie `em_ref=XXXXXX` setado com 30 dias de expiração
  - DevTools → Application → Cookies → verificar `em_ref`
- [ ] Página carrega normalmente (layout, seções, CTA)
- [ ] Nenhum erro no console

### Teste sem código (orgânico)
1. Acessar `/landing` sem `?ref=`
2. Verificar que **nenhum** cookie `em_ref` é criado

---

## Passo 3 — Submissão do Lead com Código de Afiliado

**Ainda na aba anônima com cookie `em_ref` setado**

### Ações
1. Preencher o campo de e-mail com `prospect@teste.com`
2. Clicar em "Solicitar Demonstração"

### Verificações
- [ ] Alert de sucesso exibido
- [ ] Request para `POST /landing/leads` inclui `affiliateCode` no body (verificar no Network do DevTools)

### Verificação no banco
```sql
SELECT id, email, affiliate_code, created_at
FROM landing_leads
WHERE email = 'prospect@teste.com'
ORDER BY created_at DESC
LIMIT 1;
```
Esperado: `affiliate_code = 'XXXXXX'` (o código do afiliado).

### Teste sem cookie
1. Abrir nova aba anônima **sem** `?ref=`
2. Enviar e-mail `organic@teste.com`
3. Verificar no banco: `affiliate_code IS NULL`

---

## Passo 4 — Criação da Organização (Admin) com Auto-match

**URL:** `/private/admin` → Criação de empresa

### Cenário A — Auto-match (prospect passou pela landing com o link)

1. Como admin, criar nova organização para o prospect
2. No campo **"E-mail do usuário"** (`userEmail`), informar `prospect@teste.com`
3. Verificar que o campo **"Indicado por"** é preenchido automaticamente com o nome do afiliado (ou que `referralCode` fica salvo)

### Cenário B — Manual (prospect veio por WhatsApp, sem passar pela landing)

1. Criar organização para `whatsapp-prospect@teste.com` (sem lead cadastrado)
2. No campo **"Código do afiliado"** (`referralCode`), informar manualmente `XXXXXX`

### Verificação no banco
```sql
SELECT code, name, referral_code
FROM organizations
WHERE code IN ('ORG-PROSPECT-A', 'ORG-PROSPECT-B');
```
Esperado: `referral_code = 'XXXXXX'` em ambos os casos.

### Cenário C — Sem afiliado (orgânico)
1. Criar organização para `organic@teste.com` sem informar `referralCode`
2. Verificar que `referral_code IS NULL` — sem erro

---

## Passo 5 — Painel do Afiliado (pré-conversão)

**URL:** `/indicador/XXXXXX`

### Verificações
- [ ] Nome do afiliado exibido no cabeçalho
- [ ] Card KPI "Leads indicados" mostra ≥ 1 (do Passo 3)
- [ ] Card KPI "Convertidos" mostra 0 (ainda não pagou)
- [ ] Card KPI "A receber" = R$ 0,00
- [ ] Tabela exibe `prospect@...` com e-mail mascarado (ex: `pr***@teste.com`)
- [ ] Badge "Lead" cinza na linha do prospect
- [ ] Botão "Copiar" funcional

### Código inválido
1. Acessar `/indicador/INVALIDO`
2. Verificar mensagem de erro amigável com link para cadastro

---

## Passo 6 — Primeiro Pagamento do Prospect (cycleNumber = 1)

> **Nota:** Este passo depende do fluxo de billing funcional. Em staging, pode ser simulado via webhook manual ou pelo painel Asaas.

### Ações
1. O prospect (conta criada no Passo 4) faz o onboarding e escolhe um plano
2. Realiza o primeiro pagamento (PIX ou cartão)
3. O webhook `PAYMENT_RECEIVED` é recebido com `cycleNumber = 1`

### Verificação no banco — comissão gerada
```sql
SELECT rc.id, rc.affiliate_id, rc.organization_id,
       rc.plan_name, rc.plan_price, rc.commission_rate,
       rc.commission_amount, rc.status, rc.created_at
FROM referral_commissions rc
JOIN affiliates a ON a.id = rc.affiliate_id
WHERE a.email = 'afiliado@teste.com';
```
Esperado:
- 1 registro com `status = 'PENDING'`
- `commission_amount = plan_price * 0.20` (ex: plano R$ 299,00 → comissão R$ 59,80)
- `plan_name` preenchido corretamente

### Idempotência — segundo pagamento NÃO gera comissão
1. Simular `PAYMENT_RECEIVED` com `cycleNumber = 2` para a mesma organização
2. Verificar que **nenhuma** nova linha foi inserida em `referral_commissions`
3. O UNIQUE constraint em `organization_id` deve garantir isso

---

## Passo 7 — Painel do Afiliado (pós-conversão)

**URL:** `/indicador/XXXXXX` (recarregar)

### Verificações
- [ ] Card KPI "Convertidos" agora mostra ≥ 1
- [ ] Card KPI "A receber" mostra o valor da comissão (ex: R$ 59,80)
- [ ] Badge do prospect mudou de "Lead" para "Convertido" (verde)

---

## Passo 8 — Painel Admin de Comissões

**URL:** `/private/admin/affiliates`

### Verificações gerais
- [ ] Tabela carrega com todas as comissões
- [ ] Linha do afiliado mostra: nome, e-mail, WhatsApp clicável, org ID, plano, valor, comissão, badge "Pendente"

### Filtros
- [ ] Filtro "Pendentes" exibe apenas comissões com status PENDING
- [ ] Filtro "Pagas" exibe lista vazia (ainda não pagamos)
- [ ] Filtro "Todas" retorna tudo

### Total a pagar
- [ ] Cabeçalho exibe "Total a pagar: R$ 59,80" (ou o valor correto)
- [ ] Badge mostra a contagem de pendentes

### Marcar como pago
1. Clicar em "Marcar pago" na linha do afiliado
2. Confirmar o `confirm()` de confirmação
3. Verificar que botão exibe spinner durante o PATCH
4. Verificar que tabela recarrega após confirmação
5. Badge muda de "Pendente" para "Pago"
6. Data de pagamento aparece abaixo do badge

### Verificação no banco
```sql
SELECT id, status, paid_at
FROM referral_commissions
WHERE affiliate_id = (SELECT id FROM affiliates WHERE email = 'afiliado@teste.com');
```
Esperado: `status = 'PAID'`, `paid_at IS NOT NULL`

### Após marcar pago
- [ ] "A receber" no painel do afiliado zerou (ou badge Pago aparece)
- [ ] "Recebido" no painel do afiliado exibe o valor pago

---

## Cenários de Borda

| Cenário | Comportamento esperado |
|---|---|
| Afiliado INACTIVE tenta gerar comissão | Nenhuma comissão gerada (guard no handler) |
| Org sem `referralCode` faz pagamento | Nenhuma comissão gerada (sem erro) |
| Mesmo `organization_id` recebe dois pagamentos cycleNumber=1 | Apenas 1 comissão (UNIQUE constraint) |
| Código de afiliado inválido na URL do dashboard | Mensagem de erro amigável, sem crash |
| Submit do form sem cookie `em_ref` | `affiliateCode = null` no backend, sem erro |

---

## Evidências Necessárias

- [ ] Screenshot de `/indicador/novo` — estado de sucesso com link gerado
- [ ] Screenshot das DevTools (cookie `em_ref` setado)
- [ ] Screenshot do Network mostrando `affiliateCode` no body do POST `/landing/leads`
- [ ] Screenshot da query SQL: `landing_leads` com `affiliate_code` preenchido
- [ ] Screenshot da query SQL: `organizations` com `referral_code` preenchido
- [ ] Screenshot da query SQL: `referral_commissions` com `status = PENDING`
- [ ] Screenshot do painel do afiliado pós-conversão (badge "Convertido")
- [ ] Screenshot do painel admin antes e depois de marcar pago
- [ ] Screenshot da query SQL: `referral_commissions` com `status = PAID` e `paid_at`

---

## Status
Backlog — aguardando validação humana do EPIC-012
