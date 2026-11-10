# TASK-437 — Samu: cadastro de fornecedor pelo chat e vínculo como habitual dos itens

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Fornecedores

## Prioridade
🟡 Médio.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Fluxo G da [Parte B](../QA/registro-usabilidade-producao.md), com D15/D16 e o modelo de conta global do fornecedor (10/11/2026).

## Escopo
- Cadastro por contato compartilhado do WhatsApp ou por texto com modelo (foto/contrato pela [TASK-345](TASK-345.md)).
- Busca por CNPJ ou nome para não duplicar ("Já existe X. É ele?").
- Contrato: [Sim] [Não, é avulso]; se sim, vigência e valor.
- Vínculo como **habitual** dos itens da categoria (TASK-346).
- Opcional: convite para o contato do fornecedor (TASK-422).

## Critérios de Aceite
- [x] Compartilhar contato inicia o cadastro com nome e telefone preenchidos
- [x] Fornecedor existente não é duplicado
- [x] Itens vinculados aparecem com o fornecedor habitual

## Dependências
[TASK-346](TASK-346.md), [TASK-422](TASK-422.md).

## Riscos
O telefone do contato compartilhado não identifica ninguém no bot até o convite ser aceito.

## Implementação (10/11/2026)
[api#214](https://github.com/douglasjava/easy-maintenance-api/pull/214), mergeada em `staging`. Habitual pela TASK-346 (api#213, web#149).
- Contato compartilhado (webhook `contacts`) inicia o cadastro com nome e telefone preenchidos, sem IA. Também funciona por texto ("cadastrar fornecedor …").
- Sem duplicar: mesmo nome ou CPF/CNPJ na organização gera "Já existe X. É ele?"; o registro já é idempotente por documento. CPF/CNPJ é validado.
- Contrato [Sim] [Não, é avulso], com vigência e valor; itens informados viram o fornecedor habitual (coluna no web).
- Cartão antes de salvar; `checkWrite` na gravação.
- O convite para o contato do fornecedor continua no portal (TASK-422).
- `mvn test` 2014, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas.
