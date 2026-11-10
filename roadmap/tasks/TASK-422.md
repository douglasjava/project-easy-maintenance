# TASK-422 — Fornecedor: conta global reivindicada + contatos gerenciados pelo fornecedor

## Tipo
FULL_STACK

## Categoria
Fornecedores / Identidade

## Prioridade
🟠 Alto — base do fornecedor em N condomínios.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Decisão de 10/11/2026 (substitui a D20 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md)): o fornecedor é **uma conta global por CNPJ** que
presta serviço para N condomínios. Hoje o fornecedor cadastrado por um condomínio não tem acesso nenhum, e o
`Supplier.phone` global (primeiro cadastro, muitas vezes do Google Places) não serve como identidade.

## Escopo
- Reivindicação da conta: pelo link enviado ao e-mail cadastrado (TASK-413) ou pelo convite de um condomínio.
  Depois de reivindicada, os vínculos de outros condomínios aparecem sozinhos.
- No portal do fornecedor, o dono cadastra os **contatos** (técnicos); cada telefone entra no bot por código de convite
  (mesmo mecanismo da TASK-418).
- Alcance de cada contato: **todos os condomínios** por padrão; restringir por condomínio fica para depois.
- Condomínio desliga o fornecedor → contatos perdem a visão daquele condomínio.

## Critérios de Aceite
- [x] Conta reivindicada só por quem comprova o e-mail ou recebe convite de condomínio
- [x] Contato ativado vê dados de todos os condomínios vinculados e de nenhum outro
- [x] Desligar o vínculo remove a visão daquele condomínio na hora
- [x] `Supplier.phone` global não identifica ninguém no bot

## Dependências
[TASK-413](TASK-413.md), [TASK-417](TASK-417.md).

## Riscos
Multi-tenant: o `Supplier` é compartilhado; toda consulta filtra pelos condomínios vinculados.

## Implementação (10/11/2026)
[api#199](https://github.com/douglasjava/easy-maintenance-api/pull/199) e [web#142](https://github.com/douglasjava/easy-maintenance-web/pull/142), mergeadas em `staging`.
- `supplier_contacts` (V141): técnicos do fornecedor. O fornecedor cadastra no portal (aba WhatsApp, link válido da TASK-413), ou um condomínio vinculado convida um técnico (`POST /suppliers/{id}/contacts/assistant-invite`).
- Convite pelo mesmo mecanismo da TASK-418 (persona `SUPPLIER_CONTACT`). Remover o contato revoga o acesso na hora.
- Resolução: o contato vê todos os condomínios vinculados ao fornecedor naquele momento; desvincular tira a visão. O `Supplier.phone` global não identifica ninguém.
- Pendente: o botão do lado do condomínio no web fica para a TASK-437.
- `mvn test` 1945, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — atrás de `ASSISTANT_PERSONAS_ENABLED`; aguarda a validação de Douglas.
