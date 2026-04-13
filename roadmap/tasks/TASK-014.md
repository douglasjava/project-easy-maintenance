# TASK-014 — Restrição CORS para domínio de produção

## Tipo
Segurança / Configuração

## Categoria
Backend / Segurança

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-003 — Multi-tenancy e Autorização

## Descrição
A configuração CORS do backend precisa ser verificada e restringida ao domínio de produção do frontend. Se `Access-Control-Allow-Origin: *` estiver configurado, qualquer origem pode fazer requisições autenticadas ao backend, incluindo sites maliciosos que convençam o usuário a visitar uma página que faz requests em seu nome.

## Problema
CORS muito permissivo + cookies (após TASK-002) seria o cenário mais arriscado. Mas mesmo com token em header, um CORS `*` permite que qualquer página carregue recursos do backend.

## Dependências
- Conhecer o domínio de produção do frontend

## Critérios de Aceite
- [ ] `Access-Control-Allow-Origin` configurado explicitamente para o domínio de produção (ex: `https://app.easymaintenance.com.br`)
- [ ] `Access-Control-Allow-Origin: *` NÃO presente em ambiente de produção
- [ ] Origens de desenvolvimento (localhost:3000) permitidas apenas em profiles não-produção
- [ ] Verificar que preflight OPTIONS funciona corretamente para o domínio permitido

## Subtasks
- [ ] Localizar onde CORS está configurado no backend (WebMvcConfigurer ou Spring Security)
- [ ] Configurar allowed origins via variável de ambiente `ALLOWED_ORIGINS`
- [ ] Separar origens por profile (local: localhost, prod: domínio real)
- [ ] Testar requisição de origem não permitida → deve ser bloqueada

## Esforço
Pequeno (1-2h)

## Risco de não fazer
Qualquer site pode fazer requests autenticados em nome dos usuários logados.

## Status
Concluído
