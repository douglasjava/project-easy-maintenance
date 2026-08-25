# TASK-QA-MAN-014 — QA Manual: falha silenciosa de criação de cliente Asaas (EPIC-002 Fase 3)

## Tipo
QA Manual

## Categoria
Backend + Frontend / Onboarding, Billing, Admin

## Prioridade
🟠 Alto

## Épico
[EPIC-002](../../epics/EPIC-002.md) — Confiabilidade Operacional (Fase 3)

## Tasks cobertas
[TASK-201](../../tasks/TASK-201.md) (ressincronização manual) ·
[TASK-202](../../tasks/TASK-202.md) (validação frontend) ·
[TASK-203](../../tasks/TASK-203.md) (validação backend) ·
[TASK-204](../../tasks/TASK-204.md) (alerta Sentry) ·
[TASK-205](../../tasks/TASK-205.md) (indicador visual)

---

## Descrição

Valida a correção do caso real do primeiro cliente pagante (Ricardo Cerqueira, 25/08/2026): CPF com
formato válido mas dígito verificador incorreto (`266.848.958-03`) foi aceito no onboarding e só
rejeitado pela Asaas, silenciosamente — a conta ficou sem `external_customer_id`. Os dois pontos
mais críticos: (1) o onboarding agora bloqueia CPF/CNPJ inválido antes de submeter; (2) o admin
consegue corrigir e ressincronizar sem esperar o job noturno (6h).

Toda a Fase 3 está numa branch só nos dois repos: `feature/EPIC-002-fase3-asaas-sync`
(`easy-maintenance-api` e `easy-maintenance-web`). Sem migration nova — nenhuma mudança de schema.
Ainda sem PR — testar local primeiro.

---

## Pré-condições

- Checkout da branch `feature/EPIC-002-fase3-asaas-sync` nos dois repos, rodando local (api + web
  apontando um pro outro).
- Acesso admin (`X-Admin-Token` ou usuário admin logado) pra acessar `/private/users/[id]`.
- Acesso ao DevTools (aba Network) do navegador, pra conferir requisições e mensagens de erro.
- Pra C5/C6 (ressincronização): uma conta de teste com `external_customer_id` nulo. Se não tiver
  nenhuma "quebrada" no banco local, force uma:
  ```sql
  SELECT id, user_id, doc, external_customer_id FROM billing_accounts WHERE user_id = <ID_DE_TESTE>;
  UPDATE billing_accounts SET external_customer_id = NULL WHERE user_id = <ID_DE_TESTE>;
  ```
  **Nota:** isso valida o *mecanismo* de correção — não é a mesma coisa que corrigir a conta real do
  Ricardo. Corrigir a conta dele de verdade (com o CPF certo, que só ele sabe) é uma ação separada,
  a ser feita depois que a branch for pra staging/produção (ou direto, se seu ambiente local já
  aponta pro banco onde a conta dele está).

---

## Cenários de Teste

### C1 — Onboarding bloqueia CPF inválido (passo 1, obrigatório)

| Passo | Ação                                                                                   | Resultado esperado                                                                    |
|-------|-----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| 1     | Abrir `/onboarding`, preencher o campo CPF com `266.848.958-03` (o CPF real do caso do Ricardo) e submeter o passo 1 | Formulário **não** submete; campo CPF fica com borda vermelha e mensagem "CPF inválido — confira os dígitos" |
| 2     | Conferir a aba Network                                                                  | Nenhuma chamada a `POST /me/onboarding/user` foi disparada — bloqueou antes de sair do front |
| 3     | Trocar por um CPF válido real (o seu próprio, ou qualquer CPF real) e submeter novamente | Passa normalmente, avança pro passo 2                                                  |
| 4     | Tentar um CPF com todos os dígitos iguais, ex. `111.111.111-11`                         | Bloqueado também (sequência repetida é sempre inválida, mesmo passando no cálculo)      |

---

### C2 — Onboarding bloqueia CNPJ/CPF inválido (passo 2, opcional)

| Passo | Ação                                                                                   | Resultado esperado                                                                    |
|-------|-----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| 1     | No passo 2, deixar o campo "CNPJ/CPF" vazio e submeter                                  | Passa normalmente — campo é opcional                                                    |
| 2     | Preencher com um CNPJ de dígito verificador errado (ex. `11.222.333/0001-99`)           | Bloqueado, mensagem "CNPJ/CPF inválido — confira os dígitos"                            |
| 3     | Corrigir pra um CNPJ válido real e submeter                                             | Passa normalmente, organização criada                                                   |

---

### C3 — Backend rejeita CPF/CNPJ inválido mesmo sem passar pelo formulário (defesa em profundidade)

Usar Postman/curl/Insomnia — simula alguém chamando a API direto, sem passar pela validação do
frontend.

| Passo | Ação                                                                                                              | Resultado esperado                                                              |
|-------|----------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| 1     | `POST /easy-maintenance/api/v1/me/onboarding/user` com `doc: "26684895803"` (autenticado, resto dos campos válidos) | `422` com mensagem de validação mencionando o campo `doc`                          |
| 2     | `PUT /easy-maintenance/api/v1/private/admin/users/{userId}/account` com `doc: "26684895803"` (token admin)          | `422`, mesmo comportamento                                                          |
| 3     | Repetir o passo 1 com `doc` omitido/nulo                                                                             | Passa normalmente (campo continua opcional)                                        |

---

### C4 — Onboarding completo com CPF válido continua funcionando (regressão do caminho feliz)

| Passo | Ação                                                                                     | Resultado esperado                                                              |
|-------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| 1     | Cadastrar um usuário de teste novo, completar onboarding (passo 1 e 2) com CPF/CNPJ válidos reais | Onboarding completo sem erros, redireciona normalmente                          |
| 2     | Conferir no banco: `SELECT external_customer_id FROM billing_accounts WHERE user_id = <novo_id>;` | `external_customer_id` preenchido (cliente criado na Asaas com sucesso)         |

---

### C5 — Ressincronização manual corrige uma conta com `external_customer_id` nulo

| Passo | Ação                                                                                     | Resultado esperado                                                              |
|-------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| 1     | Preparar uma conta de teste com `external_customer_id = NULL` (ver Pré-condições) e `doc` **válido** | —                                                                                |
| 2     | Abrir `/private/users/{userId}` dessa conta, aba **Pagamento**                              | Badge "⚠️ Pendente de sincronização com Asaas" aparece perto do título; botão "Ressincronizar com Asaas" visível |
| 3     | Clicar em "Ressincronizar com Asaas"                                                        | Toast de sucesso ("Cliente Asaas sincronizado com sucesso."); badge some da tela |
| 4     | Conferir no banco                                                                            | `external_customer_id` da conta agora preenchido                                |

---

### C6 — Ressincronização mostra o erro real quando a Asaas ainda rejeita

| Passo | Ação                                                                                     | Resultado esperado                                                              |
|-------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| 1     | Numa conta com `external_customer_id = NULL`, editar o campo Documento pra um CPF **inválido** (dígito verificador errado) e salvar (botão "Salvar" da aba Pagamento) | Salva normalmente — a edição admin não bloqueia CPF inválido de propósito (ver Riscos/observação abaixo) |
| 2     | Clicar em "Ressincronizar com Asaas"                                                        | Toast de **erro** com a mensagem real da Asaas (algo como "O CPF/CNPJ informado é inválido"), não uma mensagem genérica tipo "Erro interno inesperado" |
| 3     | Badge continua aparecendo                                                                   | Sim — nada foi sincronizado                                                     |

**Observação:** o passo 1 revela um ponto de atenção — a *edição* de conta pelo admin
(`PUT /admin/users/{id}/account`) já tem `@Doc` aplicado (TASK-203), então na verdade o passo 1
**deveria** bloquear o salvamento com CPF inválido, e o cenário C6 não deveria ser alcançável por
esse caminho. Se ao testar o salvamento passar mesmo com CPF inválido, é um bug a reportar — não
esperado dado o que foi implementado.

---

### C7 — Botão/badge não aparecem quando a conta já está sincronizada

| Passo | Ação                                                                                     | Resultado esperado                                                              |
|-------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| 1     | Abrir a aba Pagamento de uma conta com `external_customer_id` já preenchido                 | Nenhum badge de aviso, nenhum botão de ressincronizar — tela como era antes      |
| 2     | (Opcional) Chamar `POST /admin/billing/users/{userId}/account/sync-external-customer` direto via Postman pra essa conta | `409 Conflict`, "Esta conta já possui um cliente Asaas vinculado — nada a sincronizar." |

---

### C8 — Alerta Sentry (verificação limitada em ambiente local)

Local, `SENTRY_DSN_BACKEND` normalmente vazio → Sentry roda em modo no-op (não envia nada). Esse
cenário só é totalmente verificável em staging/produção, onde o DSN está configurado.

| Passo | Ação                                                                                     | Resultado esperado                                                              |
|-------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| 1     | (Só se `SENTRY_DSN_BACKEND` estiver setado local) Forçar falha de criação de cliente Asaas (onboarding com CPF que passe na validação do front mas falhe na Asaas, ou repetir C6) | Evento aparece no painel do Sentry, com a exceção `AsaasException` e contexto |
| 2     | Se não tiver DSN local                                                                       | Pular esse cenário — cobertura já garantida pelos testes automatizados (`mvn test`) e pela revisão de código; reconferir depois que for pra staging |

---

### C9 — Regressão automatizada

| Passo | Ação                                     | Resultado esperado                          |
|-------|-------------------------------------------|----------------------------------------------|
| 1     | `mvn test` na api                          | 809/809 passando, 0 falhas                    |
| 2     | `npm run build` no web                     | Build limpo, sem erro de TypeScript           |

---

## Critérios de Aceite da Suite

- [ ] C1: CPF inválido bloqueado no passo 1 do onboarding, CPF válido passa
- [ ] C2: CNPJ/CPF inválido bloqueado no passo 2 (quando preenchido), vazio passa (opcional)
- [ ] C3: API rejeita `doc` inválido direto (`422`), aceita `doc` nulo
- [ ] C4: onboarding com CPF válido continua criando o cliente Asaas normalmente
- [ ] C5: botão de ressincronização corrige uma conta pendente com sucesso
- [ ] C6: falha de ressincronização mostra a mensagem real da Asaas, não uma genérica
- [ ] C7: badge/botão somem quando a conta já está sincronizada; endpoint retorna 409 se chamado mesmo assim
- [ ] C8: (se aplicável local) evento aparece no Sentry
- [ ] C9: suíte automatizada sem regressão

---

## Status
Aguardando validação local do Douglas.
