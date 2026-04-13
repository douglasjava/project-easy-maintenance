# TASK-022 — Sentry em backend e frontend

## Tipo
Observabilidade / Operação

## Categoria
Backend / Frontend / Observabilidade

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-005 — Observabilidade e Operação

## Descrição
O sistema não possui rastreamento de erros em produção. Exceções não tratadas no backend são logadas (se há handler global), mas erros JavaScript no frontend somem completamente. Sem Sentry ou equivalente, a equipe não sabe o que está quebrando para os usuários.

## Problema
- Erros de JavaScript no frontend (ex: bug de renderização, Promise rejection) são invisíveis
- Erros de backend que chegam ao handler global são logados mas não há alerta
- Impossível priorizar bugs sem saber frequência e impacto

## Impacto
Bugs que afetam usuários em produção são descobertos somente quando o usuário reporta.

## Dependências
- Conta no Sentry (free tier disponível)

## Critérios de Aceite
- [ ] Sentry SDK integrado ao backend Spring Boot (`sentry-spring-boot-starter`)
- [ ] Sentry SDK integrado ao frontend Next.js (`@sentry/nextjs`)
- [ ] Erros não tratados no backend são automaticamente capturados pelo Sentry
- [ ] Erros JavaScript no frontend são capturados pelo Sentry
- [ ] DSN do Sentry em variável de ambiente (não hardcoded)
- [ ] Nenhum dado sensível (tokens, senhas, CPF) capturado nos eventos do Sentry

## Subtasks
- [ ] Criar conta e projeto no Sentry (ou usar Glitchtip self-hosted)
- [ ] Adicionar `sentry-spring-boot-starter` ao `pom.xml` e configurar DSN
- [ ] Configurar `sentry.properties` para filtrar dados sensíveis
- [ ] Executar `npx @sentry/wizard@latest -i nextjs` no frontend
- [ ] Configurar `sentry.client.config.ts` e `sentry.server.config.ts`
- [ ] Testar captura de erro no backend e frontend

## Esforço
Pequeno (4-8h)

## Risco de não fazer
Time cego sobre erros em produção. Bugs de UX que afetam conversão passam despercebidos por semanas.

## Status
Concluído
