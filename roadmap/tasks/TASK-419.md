# TASK-419 — Assistente: morador aprovado vira persona + resposta a número desconhecido

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Identidade

## Prioridade
🟠 Alto.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D21 e D22 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md). O morador aprovado no EPIC-040 (em produção) ainda não conversa com o bot, e hoje
número desconhecido recebe "ative em Minha Conta", que não serve para quem não tem login.

## Escopo
- Morador aprovado (`CondoPerson` MORADOR do EPIC-040) é persona ativa; na primeira conversa aceita o termo.
- Número desconhecido: mensagem neutra, sem IA, no máximo 1 por dia por número (texto da D22).

## Critérios de Aceite
- [x] Morador aprovado é reconhecido; pendente ou reprovado não
- [x] Número desconhecido recebe a mensagem neutra uma vez por dia, sem consumir crédito de IA
- [x] Usuário com login continua recebendo o fluxo atual

## Dependências
[TASK-417](TASK-417.md).

## Riscos
Spam: o limite diário evita resposta em laço e custo.

## Implementação (10/11/2026)
[api#195](https://github.com/douglasjava/easy-maintenance-api/pull/195), mergeada em `staging`.
- D21: quando um número desconhecido escreve, o bot procura um morador aprovado (EPIC-040) com esse celular. Achando, abre um vínculo pendente de 1 dia, sem código, e envia o termo. O aceite ativa a persona, inclusive em mais de um condomínio.
- D22: a mensagem neutra lista QR Code, convite do síndico e Minha Conta. No máximo 1 por dia, sem IA.
- `mvn test` 1921, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — atrás de `ASSISTANT_PERSONAS_ENABLED`; aguarda a validação de Douglas.
