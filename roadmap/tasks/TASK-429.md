# TASK-429 — Limite de IA por persona (mensagens por dia + teto mensal)

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / IA

## Prioridade
🟠 Alto — pré-requisito para liberar persona sem login para todos.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D11 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md): crédito de IA sai do plano do condomínio; o morador é o público mais numeroso.

## Escopo
- (a) Máximo de mensagens pela IA por persona por dia (ex.: morador 10/dia).
- (b) Teto mensal em créditos para todas as personas sem login somadas (ex.: 30% do crédito do plano).
- Números por configuração; acima do limite o bot oferece o menu sem IA.

## Critérios de Aceite
- [x] Passou do limite diário: menu sem IA, sem consumir crédito
- [x] Teto mensal das personas respeitado sem afetar ADMIN/SYNDIC
- [x] Limites configuráveis sem deploy

## Dependências
[TASK-417](TASK-417.md).

## Riscos
Calibrar no piloto.

## Implementação (10/11/2026)
[api#206](https://github.com/douglasjava/easy-maintenance-api/pull/206), mergeada em `staging`.
- `assistant_persona_ai_usage` (V145). Limite diário por persona (10) e teto mensal somado da organização (300 chamadas), ambos configuráveis.
- Conta a classificação de texto e a transcrição de áudio. Acima do limite, o bot responde sem IA. Login não é afetado.
- O teto ficou em chamadas, não em "% do crédito do plano" (o exemplo da spec), para calibrar no piloto.
- `mvn test` 1970, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas.
