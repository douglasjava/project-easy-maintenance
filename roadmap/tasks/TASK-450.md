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
- [x] Upload e download só para a própria organização
- [x] Limites de tipo, tamanho e quantidade
- [x] PDF de prestação de contas com nº e indicação de comprovante

## Dependências
—

## Riscos
URL do anexo não pode ser pública.

## Implementação (11/11/2026)
[api#225](https://github.com/douglasjava/easy-maintenance-api/pull/225) e [web#158](https://github.com/douglasjava/easy-maintenance-web/pull/158), mergeadas em `staging`.
- A migração V156 cria `document_number` (até 60 caracteres) e a tabela `financial_entry_attachments`. ⚠️ Ainda não foi executada num MySQL.
- O comprovante vai por URL pré-assinada direto ao S3 e depois é confirmado na API, no mesmo storage dos anexos de manutenção. Aceita PDF, JPG, PNG ou WebP, até 10 MB e no máximo 5 por lançamento. O download é sempre pela API.
- Isolamento por organização: lançamento de outra organização dá 404, e a confirmação só aceita a chave do próprio lançamento.
- A lista devolve `attachmentCount`, usado no selo "sem comprovante". O comprovante não é obrigatório (D7).
- Web: campo Nº do documento, modal de comprovantes e coluna "Documento" na prestação de contas, na tela e no PDF.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
