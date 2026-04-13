# TASK-026 — Testes de integração — billing e auth completos

## Tipo
Qualidade / Testes

## Categoria
Backend / Testes

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-008 — Qualidade e Testes

## Descrição
Complemento à TASK-004 (testes mínimos pré-lançamento). Após o lançamento, expandir a cobertura de testes para os fluxos completos de billing e autenticação, garantindo confiança para iterações e hotfixes.

## Critérios de Aceite
- [ ] Cobertura de 70%+ nos módulos `billing`, `auth`, `org_users` e `kernel`
- [ ] Testes de integração para todos os webhooks do Asaas (pagamento confirmado, cancelado, vencido)
- [ ] Teste de mudança de plano (upgrade e downgrade) com verificação de features
- [ ] Teste de ciclo de billing completo (geração de invoice → pagamento → renovação)
- [ ] Testes E2E básicos para onboarding (Playwright ou equivalente)
- [ ] Pipeline de CI bloqueante em caso de falha de teste

## Esforço
Grande (1 semana)

## Risco de não fazer
Sem cobertura adequada, refatorações e novas features comprometem a confiabilidade do sistema de billing.

## Status
Backlog
