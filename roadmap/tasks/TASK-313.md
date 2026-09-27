# TASK-313 — Assistente no WhatsApp: ajustes do piloto em produção (logs e transcrição de áudio)

## Tipo
BUGFIX (BACKEND)

## Prioridade
🟡 Médio — piloto em produção com o usuário do Douglas (27/09/2026)

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp

## Contexto
Primeiro teste real em produção (27/09/2026). A ativação por código funcionou e a resposta "Pronto, Douglas! ✅" chegou.
Durante o teste apareceram dois pontos:

1. **Log poluído:** cada resposta do assistente gera 3–4 `WARN ... não corresponde a nenhum dispatch conhecido`.
   São os status (sent/delivered/read) das próprias respostas do bot, que não ficam em
   `business_whatsapp_dispatches`. É esperado e não tem utilidade hoje → rebaixar para DEBUG.
2. **Áudio não transcrito:** um áudio curto ("o que vence essa semana") caiu em "Não consegui ouvir o áudio".
   O download funcionou; a falha foi na chamada do Whisper. Causa a confirmar pelo log
   `[Assistant] Falha ao transcrever áudio: <motivo>`. **Causa:** `response_format must not be null` — no Spring AI
   1.0.0-M5 o modelo de transcrição criado à mão exige `responseFormat` (padrão JSON só na autoconfiguração).

Também registrado: a Meta entrega como `type=unsupported` mensagens de texto enviadas numa conversa com
**mensagens temporárias** ligadas (resolvido desligando na conversa; hoje o motivo que vem no campo
`errors` do payload não é registrado).

## Critérios de Aceite
- [x] Status de mensagens do assistente não geram WARN (DEBUG)
- [x] Causa da falha de transcrição identificada e corrigida (`AssistantConfigTest` RED→GREEN)
- [ ] Áudio de voz do WhatsApp transcrito em produção (confirmar após deploy)

## Status
🟡 Em validação — PR [api#125](https://github.com/douglasjava/easy-maintenance-api/pull/125) → `staging`
