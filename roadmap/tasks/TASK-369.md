# TASK-369 — FRONTEND: Categoria e protocolo no fluxo público do morador

## Tipo
FRONTEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — abrir chamado escolhendo cada uma das 3 categorias, confirmar protocolo exibido na
confirmação e na listagem "Meus chamados", responsividade mobile (público final acessa via QR code
no celular).

---

## Contexto

Parte frontend da extensão do EPIC-027 pedida por Douglas após conversa com a síndica Aliria
Emanuela (28/10/2026). Detalhe completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

- No formulário de abertura (`/chamados/[orgCode]`, tela 2): novo campo obrigatório de categoria
  (Sugestão/Reclamação/Manutenção — radio ou select, decisão de UI na implementação).
- Tela de confirmação após abrir: exibir o número de protocolo em destaque (ex. "Protocolo nº 12").
- Listagem "Meus chamados": cada item mostra categoria e protocolo.
- Estados de loading/erro consistentes com o resto do fluxo público já existente.

## Critérios de Aceite

- [ ] Não é possível enviar o formulário sem escolher uma categoria
- [ ] Protocolo retornado pela API aparece na tela de confirmação
- [ ] Protocolo e categoria aparecem em cada item da listagem "Meus chamados"
- [ ] Funciona em viewport mobile (público final acessa majoritariamente via QR code no celular)
- [ ] `npm run build`/`tsc --noEmit` sem regressão

## Dependências
TASK-367 (contrato de API com `category`/`protocolNumber`). Independente de TASK-370/371.

## Riscos
Baixo — extensão de tela já existente, sem mudança estrutural de rota.

## Esforço
Pequeno

## Status
📋 Backlog
