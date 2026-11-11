# TASK-450 — Financeiro v2: nº do documento + anexos do lançamento + prestação de contas

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🟡 Médio

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção 3.4 e D7), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- `document_number` opcional (até 60).
- Tabela `financial_entry_attachments` (mesmo storage de `maintenance_attachments`): PDF ou imagem, até 10 MB, máximo 5.
- Selo "sem comprovante" (D7: anexo não obrigatório).
- PDF de prestação de contas lista o nº e indica "📎 com comprovante"; despesa de manutenção mostra os anexos da manutenção.

## Critérios de Aceite
- [ ] Upload e download só para a própria organização
- [ ] Limites de tipo, tamanho e quantidade
- [ ] PDF de prestação de contas com nº e indicação de comprovante

## Dependências
—

## Riscos
URL do anexo não pode ser pública.

## Status
⬜ Backlog
