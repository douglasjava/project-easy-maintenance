# EPIC-027 — Chamados de Moradores

## Status
💡 Ideia registrada (07/09/2026), **não desenhada, não priorizada**. Aguardando sessão de brainstorm
calma com Douglas antes de qualquer detalhamento técnico ou task.

## Objetivo (macro)
Dar aos moradores (usuários finais das edificações atendidas, hoje sem esse canal) uma forma de
abrir um chamado/solicitação e acompanhar o andamento dele — hoje o fluxo do produto é centrado em
quem administra a manutenção (síndico/gestor), sem um canal estruturado para o morador reportar um
problema e ver o que está acontecendo com ele.

## Descrição (nível macro, como Douglas trouxe)

> "Uma funcionalidade para os moradores abrirem chamados e ter uma forma de acompanhar os mesmos."

Sem escopo técnico definido ainda: não há decisão sobre autenticação de morador (login próprio? sem
login, via link/token?), relação com o modelo multi-tenant atual (`X-Org-Id` é por organização —
como um morador individual se encaixa nisso), integração ou não com o fluxo de manutenção existente,
nem sobre notificação de status pro morador. Tudo isso fica para a sessão de brainstorm.

## Fora de escopo (por ora)
Qualquer detalhamento de arquitetura, modelo de dados ou telas — propositalmente, a pedido do
Douglas ("deixar anotado... pra analisar mais friamente" depois).

## Riscos conhecidos (nível macro)
- Multi-tenant: hoje o produto não modela "morador" como um tipo de usuário/acesso — precisa
  decisão de produto antes de qualquer código.
- Pode ter sobreposição conceitual com o fluxo de manutenção/anexos já existente — vale checar se
  "chamado" é uma entidade nova ou uma variação de algo que já existe, na sessão de brainstorm.
