# TASK-428 — Avisos do prédio: entidade, destinatários, custo antes de enviar, teto mensal

## Tipo
FULL_STACK

## Categoria
Assistente WhatsApp (Samu) / Avisos

## Prioridade
🟡 Médio — tem custo por mensagem.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D7 e D13 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md) e seção "Custo de mensagens WhatsApp". Aviso é entidade própria, **só enviada** (proativa),
paga por destinatário.

## Escopo
- Entidade de aviso por organização (título, texto, período, destinatários).
- O síndico escolhe os destinatários (todos, bloco, unidade, papel) e vê o **custo estimado antes** de confirmar.
- Teto mensal de envio por organização.
- Envio em fan-out por template HSM de utilidade, com registro de entrega.

## Critérios de Aceite
- [x] Custo estimado aparece antes de confirmar e bate com o número de destinatários
- [x] Envio bloqueado acima do teto mensal
- [x] Só destinatários ativos e com opt-in recebem

## Dependências
[TASK-417](TASK-417.md), [TASK-419](TASK-419.md). Conferir o rate card oficial da Meta antes.

## Riscos
Custo cresce com o número de moradores, não com a receita.

## Implementação (10/11/2026)
[api#205](https://github.com/douglasjava/easy-maintenance-api/pull/205) e [web#145](https://github.com/douglasjava/easy-maintenance-web/pull/145), mergeadas em `staging`.
- `building_notices` e as entregas (V144). `/building-notices`: estimar (destinatários, custo e teto), enviar e listar.
- Destinatários: ativos, com celular e opt-in. Filtro por todos, papel, unidade ou andar. **Por bloco depende do cadastro de Locais.**
- Custo de 4 centavos por mensagem (utilidade, R$ 0,035, tabela da Meta de out/2026). Teto mensal configurável (500).
- Web: página `/notices` com o custo antes de confirmar e o histórico.
- **Ação do Douglas:** aprovar na Meta o template `aviso_predio_v1` (utilidade; variáveis: condomínio, título e texto) e então ligar `NOTICES_WHATSAPP_ENABLED`.
- `mvn test` 1965, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — envio desligado até o template ser aprovado pela Meta; aguarda a validação de Douglas.
