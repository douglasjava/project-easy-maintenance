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

- [x] Tela 1 aceita CPF e avança pra tela 2 com a lista correta daquele CPF
- [x] `orgCode` inválido é tratado pela API (404 confirmado via curl); tela mostra o alerta de erro
      genérico (mesmo componente do erro de carregamento) — não travei especificamente esse caso
      no navegador, mas o tratamento existe e é o mesmo caminho já validado
- [x] Abrir chamado sem foto funciona (foto é opcional) — validado num navegador real
- [ ] Abrir chamado com foto — fluxo de request está correto (presigned URL + PUT), mas **não
      validado de ponta a ponta**: ambiente local usa credenciais AWS fake, upload real ao S3
      falharia. Mesma limitação que qualquer feature de anexo já tem nesse projeto sem S3 real.
- [x] Telefone/descrição obrigatórios (`required` no form + `@NotBlank` no backend)
- [ ] Layout responsivo — não testado em viewport mobile real, só desktop
- [x] `npm run build` sem erro
- [x] Validado num navegador real (não só build limpo) — fluxo completo ponta a ponta: CPF → lista
      vazia → abrir chamado → toast de sucesso → chamado aparece na lista com status correto

## Dependências
TASK-237 (endpoints públicos) precisa estar pronta antes de integrar de verdade.

## Riscos
Baixo — tela nova, isolada, não altera nenhuma tela existente.

## Esforço
Médio

## Status
✅ Implementada na branch `feature/EPIC-027-resident-tickets` (`easy-maintenance-web`). Validada num
navegador real contra a API local (não só build) — fluxo completo de abertura funcionando ponta a
ponta. Pendências reais antes de ir pra produção: teste de upload de foto com S3 real (ambiente
local só tem credenciais fake) e teste em viewport mobile de verdade. `npm run build`/`npm test`
sem regressão (3 falhas em `middleware.test.ts` pré-existentes, não relacionadas).
