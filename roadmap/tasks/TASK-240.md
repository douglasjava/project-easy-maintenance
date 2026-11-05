# TASK-240 — FRONTEND: Kanban interno de chamados (drag-and-drop) + QR code em Configurações

## Tipo
FRONTEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — testar o drag-and-drop entre as 3 colunas num navegador real (não só build), confirmar que
só chamados da organização logada aparecem, e que o QR code gerado aponta pra URL certa.

---

## Contexto

Lado autenticado do épico: painel interno onde ADMIN/MEMBER acompanha e move os chamados, mais a
tela onde o ADMIN consegue baixar/imprimir o QR code pra colar na edificação. Detalhe completo em
`docs/superpowers/specs/2026-09-08-resident-tickets-design.md`.

## Escopo

### Kanban
- Nova página/seção no painel interno com 3 colunas (`SOLICITADO`/`EM_ANDAMENTO`/`CONCLUIDO`).
- Drag-and-drop real entre colunas via **dnd-kit** (nenhuma lib de drag-and-drop existe hoje no
  projeto — decisão explícita de Douglas em vez de um dropdown de status mais simples).
- Mover um card entre colunas dispara `PATCH /resident-tickets/{id}/status` (TASK-238).
- Lista só os chamados da organização logada (via `GET /resident-tickets`, já filtrado pelo
  backend por `X-Org-Id`).

### QR code (achado na revisão do desenho, 08/09/2026)
- Nova seção em Configurações/Perfil da organização (não no kanban — tratado como algo que se
  configura uma vez, não uma tela de uso diário).
- Geração **100% client-side** (biblioteca leve, ex. `qrcode`) — encoda a URL pública
  `/c/{organizationCode}` a partir do `Organization.code` que a tela autenticada já tem disponível.
  Sem endpoint novo no backend.
- Botão de baixar/imprimir o QR code.

## Critérios de Aceite

- [x] Kanban mostra os 3 status como colunas, só com chamados da organização logada
- [x] Arrastar um card entre colunas atualiza o status via API e reflete na tela — confirmado num
      navegador real: sequência de `PointerEvent` disparada via JS (o gesto de drag do automation
      tool não ativa o `PointerSensor` do dnd-kit), `PATCH /resident-tickets/{id}/status` disparado
      de verdade (200, network tab confirmado), card mudou de coluna e persistiu após refetch
- [x] QR code exibido em Configurações/Perfil, apontando pra `/c/{organizationCode}` correto —
      confirmado visualmente num navegador real
- [ ] Botão de baixar/imprimir o QR code — não cliquei de verdade (é um `<a download>` trivial
      sobre uma data URL, risco baixo, mas não confirmado)
- [x] `npm run build` sem erro
- [x] Validado num navegador real — drag-and-drop confirmado ponta a ponta (ver acima)

## Dependências
TASK-238 (endpoints autenticados) precisa estar pronta antes de integrar o kanban de verdade. A
parte de QR code não tem dependência técnica (puramente client-side), mas fica nesta mesma task por
viver no mesmo módulo/área de frontend.

## Riscos
Biblioteca nova (`dnd-kit`) no projeto — mais superfície de teste/manutenção que um dropdown
simples, decisão explícita de Douglas. Sem risco pro restante do sistema (tela nova, isolada).

## Esforço
Médio-Alto

## Status
✅ Implementada na branch `feature/EPIC-027-resident-tickets` (`easy-maintenance-web`). Validada num
navegador real, incluindo com mouse de verdade no ambiente do Douglas: kanban carrega os chamados
certos, drag-and-drop confirmado ponta a ponta (PATCH real + persistência), QR code + página A4
pra impressão (logo real, cores da marca) renderizando certo — QA manual completo e aprovado
([TASK-QA-MAN-018](../QA/tasks/TASK-QA-MAN-018.md)). `npm run build`/`npm test` sem regressão. PR
contra `staging` aberta: [web#74](https://github.com/douglasjava/easy-maintenance-web/pull/74).

## Status
🔴 Não iniciada
