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
- [ ] Conta reivindicada só por quem comprova o e-mail ou recebe convite de condomínio
- [ ] Contato ativado vê dados de todos os condomínios vinculados e de nenhum outro
- [ ] Desligar o vínculo remove a visão daquele condomínio na hora
- [ ] `Supplier.phone` global não identifica ninguém no bot

## Dependências
[TASK-413](TASK-413.md), [TASK-417](TASK-417.md).

## Riscos
Multi-tenant: o `Supplier` é compartilhado; toda consulta filtra pelos condomínios vinculados.

## Status
⬜ Backlog
