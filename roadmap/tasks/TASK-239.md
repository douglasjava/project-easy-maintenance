# TASK-239 — FRONTEND: Fluxo público de chamados em 2 telas (`/c/[orgCode]`)

## Tipo
FRONTEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — testar o fluxo completo (entrar com CPF → ver lista → abrir novo chamado com e sem foto) num
navegador real, incluindo responsividade mobile (é o cenário de uso principal — morador escaneando
QR code no celular).

---

## Contexto

Tela pública que o morador usa, sem login/conta — entrada via QR code (`/c/{orgCode}`). Detalhe
completo do fluxo em `docs/superpowers/specs/2026-09-08-resident-tickets-design.md`.

## Escopo

- Nova rota `src/app/c/[orgCode]/`, **fora do layout autenticado normal** (sem sidebar/navbar
  interna — tela pública própria, visual simples).
- Tela 1 (`page.tsx`): campo de CPF + botão "Entrar". Valida `orgCode` da URL contra a API (TASK-237)
  — erro claro se organização não existir.
- Tela 2 (lista): "Meus chamados" — status de cada um (`SOLICITADO`/`EM_ANDAMENTO`/`CONCLUIDO`),
  visualmente distinto por status. Botão "Abrir novo chamado".
- Formulário de abertura: nome, telefone (obrigatório), descrição (texto livre), foto (opcional —
  upload via presigned URL da TASK-237).
- Responsivo mobile-first — público majoritário acessa via QR code no celular.
- Componentes próprios da feature, isolados (não reaproveita componentes das telas internas de
  manutenção — contextos visuais/funcionais diferentes).

## Critérios de Aceite

- [ ] Tela 1 aceita CPF e avança pra tela 2 com a lista correta daquele CPF
- [ ] `orgCode` inválido na URL mostra erro claro, não tela quebrada
- [ ] Abrir chamado sem foto funciona (foto é opcional)
- [ ] Abrir chamado com foto funciona (upload via presigned URL)
- [ ] Telefone/descrição obrigatórios validados no formulário antes de enviar
- [ ] Layout responsivo, testado em viewport mobile
- [ ] `npm run build` sem erro
- [ ] Validado num navegador real (não só build limpo) — fluxo completo ponta a ponta

## Dependências
TASK-237 (endpoints públicos) precisa estar pronta antes de integrar de verdade.

## Riscos
Baixo — tela nova, isolada, não altera nenhuma tela existente.

## Esforço
Médio

## Status
🔴 Não iniciada
