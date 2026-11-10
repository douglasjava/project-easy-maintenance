# TASK-413 — SEGURANÇA: acesso ao portal do fornecedor exige comprovação por e-mail

## Tipo
BUGFIX — BACKEND (segurança)

## Categoria
Fornecedores / Segurança

## Prioridade
🔴 Crítico — base da identidade do fornecedor no bot (EPIC-042). Sem uso real do fluxo ainda (10/11/2026), por isso entra depois da quebra das tasks.

## Épico
Fornecedores (EPIC-027/028) · pré-requisito do [EPIC-042](../epics/EPIC-042.md)

## QA obrigatório
Sim.

---

## Contexto
Revisão de 10/11/2026 do módulo de fornecedor, feita para a matriz de papéis: a forma como o link de
gerenciamento (`/suppliers/gerenciar/{token}`) é emitido e entregue não comprova que quem o recebe controla a conta do
fornecedor. **O detalhe técnico não fica neste repositório (público)**: ele vai só na PR da `easy-maintenance-api`.

## Escopo
- O acesso ao portal passa a depender de comprovação pelo **e-mail já cadastrado** do fornecedor.
- Os links de gerenciamento existentes são rotacionados e passam a ter validade.
- Repetir o cadastro de uma conta que já existe não gera cobrança nova.
- Testes de regressão do cadastro e do portal.

## Critérios de Aceite
- [ ] Só quem tem acesso ao e-mail cadastrado do fornecedor consegue entrar no portal
- [ ] Links antigos deixam de funcionar depois da rotação; os novos expiram
- [ ] Cadastro repetido de conta existente não gera cobrança nem expõe dado da conta
- [ ] Fluxo de auto-cadastro novo e ativação pelo pagamento sem regressão
- [ ] `mvn test` sem regressão; detalhe técnico registrado só na PR da API

## Dependências
Nenhuma. Bloqueia a [TASK-422](TASK-422.md) e a [TASK-427](TASK-427.md).

## Riscos
Fornecedor que perdeu o acesso ao e-mail fica sem portal: definir o caminho de suporte (troca manual pelo admin).

## Status
⬜ Backlog
