# TASK-QA-MAN-020 — QA Manual: EPIC-028 (Cadastro de Fornecedores + Pontuação)

## Tipo
QA Manual

## Categoria
Full-Stack / Novo módulo autenticado (sem superfície pública)

## Prioridade
🟡 Médio

## Tasks cobertas
[TASK-241](../../tasks/TASK-241.md) (entidades/migration) / [TASK-242](../../tasks/TASK-242.md)
(endpoints) / [TASK-243](../../tasks/TASK-243.md) (tela) — [EPIC-028](../../epics/EPIC-028.md)

---

## Descrição

Valida o fluxo completo de cadastro de fornecedores compartilhados entre organizações: cadastro com
dedup por CNPJ, pontuação (`registrationCount`), busca por região/categoria, e a tela dedicada
(lista + filtro + formulário). Toda a implementação está na branch `feature/EPIC-028-supplier-registry`
(nos dois repos, `easy-maintenance-api` e `easy-maintenance-web`), sem PR aberta ainda.

**Diferente das QAs anteriores (TASK-QA-MAN-018/019), esta é a primeira rodada nenhuma parte do
fluxo foi validada contra um ambiente rodando de verdade** — nem eu nem uma sessão anterior. O que
foi validado nesta sessão, sem subir a aplicação:
- Backend: `SupplierPersistenceTest` (4 testes, H2) provando as duas constraints do banco; migration
  `V109` aplicada e testada diretamente contra o MySQL real do docker local, depois revertida;
  `SupplierRegistryServiceTest` (7 testes, Mockito) cobrindo dedup/idempotência/busca a nível de
  serviço; `mvn clean test` 949/949 no total, sem regressão.
- Frontend: `npm run build` limpo (rota `/fornecedores` gerada); `npm test` sem regressão nova
  (127/130, as 3 falhas de `middleware.test.ts` são pré-existentes).

**O que não deu pra validar sem o seu ambiente**: a API local completa não sobe nesta sessão porque
`PushNotificationProvider` exige um bean `FirebaseMessaging` real, que só existe com
`FIREBASE_SERVICE_ACCOUNT_JSON` válida — não tenho essa credencial aqui. Sem a API rodando de
verdade, não dá pra testar a tela num navegador real nem confirmar o fluxo ponta a ponta
(HTTP real, Asaas fora do caminho aqui já que `/suppliers` não toca nele, mas autenticação/JWT/
X-Org-Id sim). Essa rodada de QA cobre exatamente isso.

---

## Pré-condições

- Checkout de `feature/EPIC-028-supplier-registry` nos dois repos, API e frontend rodando local
  (perfil `local`, com suas credenciais reais — inclusive Firebase, que bloqueou o boot nesta
  sessão).
- Migration `V109__create_suppliers.sql` aplica sozinha no boot (Flyway) — nada manual aqui (já
  validada contra o MySQL real do seu docker nesta sessão, tabelas revertidas depois pra não
  conflitar com o Flyway do boot real).
- Não precisa de organização/usuário novo — dá pra usar sua própria conta/organização de teste de
  sempre pra C1-C4. Só o C5 (isolamento entre organizações/pontuação) precisa de uma segunda
  organização.

⚠️ Se criar dado novo, prefixe com `QA-EPIC028-*` — sintético, seguro de rodar local/dev. **Não
rodar contra staging/produção.**

---

## Cenários de Teste

### C1 — Suítes automatizadas, sem regressão

| Passo | Ação                                                                                     | Resultado esperado                                                                                           |
|-------|------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| 1     | `mvn clean test` na branch `feature/EPIC-028-supplier-registry` (`easy-maintenance-api`) | **949/949**                                                                                                  |
| 2     | `npm run build` e `npm test` na branch equivalente (`easy-maintenance-web`)              | Build limpo; jest sem regressão nova (3 falhas em `middleware.test.ts` são pré-existentes, não relacionadas) |

Já executado e confirmado durante a implementação (sem subir a API completa).

---

### C2 — Cadastrar fornecedor novo (CNPJ inédito)

| Passo | Ação                                                                                                                                                                                            | Resultado esperado                                                                                                                           |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Acessar `/fornecedores` (menu lateral → "Fornecedores", ícone 🧰, seção de recursos)                                                                                                            | Tela carrega, lista vazia ou com fornecedores já existentes da sua região                                                                    |
| 2     | Clicar "+ Novo Fornecedor"                                                                                                                                                                      | Formulário inline abre (CNPJ, Nome, Telefone, Categoria)                                                                                     |
| 3     | Digitar um CNPJ com formato válido mas dígito verificador errado (ex.: `11.222.333/0001-99`), tentar enviar                                                                                     | Bloqueado — campo fica com borda vermelha, mensagem "CNPJ inválido. Verifique os dígitos.", sem chamar a API                                 |
| 4     | Corrigir pra um CNPJ válido inédito (ex.: gerar um novo pra teste), preencher Nome, Telefone (conferir máscara `(11) 91234-5678` formatando em tempo real), Categoria (ex.: `EXTINTOR`), enviar | Toast "Fornecedor cadastrado com sucesso!", formulário fecha, fornecedor aparece na lista com pontuação **1 org.**                           |
| 5     | `SELECT * FROM suppliers WHERE cnpj = '<cnpj sem pontuação>'`                                                                                                                                   | 1 linha, `registration_count = 1`, `city`/`state` preenchidos com a cidade/estado da SUA organização (herdado, não foi pedido no formulário) |
| 6     | `SELECT * FROM supplier_organization_links WHERE supplier_id = <id>`                                                                                                                            | 1 linha, `organization_id` = o da sua organização ativa                                                                                      |

---

### C3 — Cadastrar o mesmo CNPJ pela mesma organização de novo (idempotência)

| Passo | Ação                                                                             | Resultado esperado                                                  |
|-------|----------------------------------------------------------------------------------|---------------------------------------------------------------------|
| 1     | Repetir o cadastro do C2 com o **mesmo CNPJ**, ainda logado na mesma organização | Toast de sucesso (sem erro), mas...                                 |
| 2     | Conferir a lista / `SELECT registration_count FROM suppliers WHERE cnpj = '...'` | **Continua 1** — não duplicou o vínculo nem somou pontuação de novo |
| 3     | `SELECT COUNT(*) FROM supplier_organization_links WHERE supplier_id = <id>`      | Continua **1** linha, não 2                                         |

---

### C4 — Filtro por categoria

| Passo | Ação                                                                                                                                     | Resultado esperado                                       |
|-------|------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| 1     | Com pelo menos 2 fornecedores de categorias diferentes cadastrados (ex.: `EXTINTOR` e `SPDA`), digitar `EXTINTOR` no filtro de categoria | Lista atualiza pra mostrar só os de categoria `EXTINTOR` |
| 2     | Limpar o filtro (botão "✕ Limpar")                                                                                                       | Lista volta a mostrar todos                              |
| 3     | Filtrar por uma categoria sem nenhum fornecedor cadastrado                                                                               | Estado vazio: "Nenhum fornecedor nessa categoria ainda"  |

---

### C5 — CNPJ já cadastrado por outra organização (o cenário mais importante do épico)

Precisa de uma segunda organização de teste — setup mínimo se não tiver uma à mão:
```sql
INSERT INTO organizations (code, name, city, state, company_type, require_2fa)
VALUES (UUID(), 'QA EPIC028 Org B', 'Rio de Janeiro', 'RJ', 'CONDOMINIO', 0);
```

| Passo | Ação                                                                                                                                                                               | Resultado esperado                                                                                                                                                                                     |
|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | Anotar o CNPJ cadastrado no C2 (org A)                                                                                                                                             | —                                                                                                                                                                                                      |
| 2     | Trocar pra Org B (ou logar como usuário da Org B), acessar `/fornecedores`, cadastrar um fornecedor **com o mesmo CNPJ do C2**, mas com Nome/Telefone **diferentes** dos originais | Toast diferente do C2: "Esse CNPJ já estava cadastrado por outra organização — vinculado à sua conta com os dados já registrados (`<nome original da Org A>`)" — não o nome que você acabou de digitar |
| 3     | Conferir a lista da Org B                                                                                                                                                          | Fornecedor aparece com o **nome/telefone originais da Org A** (dado nunca sobrescrito), pontuação agora **2 orgs.**                                                                                    |
| 4     | Conferir a lista da Org A de novo                                                                                                                                                  | Mesmo fornecedor, mesma pontuação **2 orgs.** — muda pra ambas, é global                                                                                                                               |
| 5     | `SELECT registration_count FROM suppliers WHERE cnpj = '...'`                                                                                                                      | **2**                                                                                                                                                                                                  |
| 6     | `SELECT * FROM supplier_organization_links WHERE supplier_id = <id>`                                                                                                               | **2** linhas, uma por organização                                                                                                                                                                      |

---

### C6 — Busca por região (cidade/estado)

| Passo | Ação                                                                                           | Resultado esperado                                                                        |
|-------|------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| 1     | Fornecedor cadastrado pela Org B (C5) tem `city`/`state` da Org B (Rio de Janeiro/RJ, herdado) | —                                                                                         |
| 2     | Acessar `/fornecedores` logado na Org A (São Paulo/SP, ou a cidade real da sua org de teste)   | Lista mostra só fornecedores da região de SP — o fornecedor do RJ (Org B) **não aparece** |

---

### C7 — Responsividade

| Passo | Ação                                                                  | Resultado esperado                                                                                                     |
|-------|-----------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| 1     | Abrir `/fornecedores` numa viewport mobile (DevTools ou celular real) | Lista vira cards empilhados (não a tabela), formulário e filtro continuam usáveis, botão "+ Novo Fornecedor" acessível |
| 2     | Repetir em desktop                                                    | Lista em tabela, colunas Fornecedor/Categoria/Telefone/Cidade-UF/Pontuação                                             |

---

## Limpeza (dados sintéticos, se criados)

```sql
DELETE FROM supplier_organization_links WHERE supplier_id IN (SELECT id FROM suppliers WHERE cnpj LIKE 'QA-EPIC028%' OR name LIKE 'QA-EPIC028%');
DELETE FROM suppliers WHERE cnpj LIKE 'QA-EPIC028%' OR name LIKE 'QA-EPIC028%';
DELETE FROM organizations WHERE name = 'QA EPIC028 Org B';
```

---

## Critérios de Aceite da Suíte

- [X] C1: suítes automatizadas sem regressão (backend 949/949 + frontend build/test)
- [X] C2: cadastro de CNPJ novo — cria `Supplier` + vínculo, `registrationCount = 1`, cidade/estado
      herdados da organização
- [X] C3: mesma organização recadastrando o mesmo CNPJ é idempotente — não duplica vínculo nem
      pontuação
- [X] C4: filtro por categoria funciona (com resultado e sem resultado)
- [X] C5: CNPJ já cadastrado por outra organização — só vincula, soma pontuação, **não sobrescreve**
      nome/telefone, mensagem clara na tela sobre isso
- [X] C6: busca por região não vaza fornecedor de outra cidade/estado
- [X] C7: responsivo em mobile e desktop

## Status
✅ Aprovado por Douglas (09/09/2026) — C1-C7 confirmados contra a API local rodando de verdade
(com credenciais reais, inclusive Firebase). Dois achados durante a execução, ambos endereçados:
1) [TASK-245](../../tasks/TASK-245.md) — bug não relacionado a fornecedores (`POST /organizations`
   500 por item USER duplicado da assinatura), corrigido em branch separada
   (`bugfix/TASK-245-duplicate-user-billing-item`), aguardando confirmação antes de abrir a PR
   dessa branch especificamente.
2) Pontuação exibida só como número não passava confiança — trocado por badge em faixa
   (Novo/Confiável/Muito usado), commit `45dbafe` na própria branch do EPIC-028.
PRs do EPIC-028 abertas pra `staging` (api + web).
