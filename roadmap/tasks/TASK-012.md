# TASK-012 — Verificar e corrigir profile de e-mail em produção

## Tipo
Bug / Confiabilidade

## Categoria
Backend / E-mail / Configuração

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-002 — Confiabilidade Operacional

## Descrição
O `MailerSendServiceImpl` está configurado com `@Profile("local")`, o que significa que só é ativado quando o profile Spring é "local". Se o ambiente de produção não estiver rodando com o profile correto, ou se existir um perfil padrão diferente, nenhum e-mail será enviado silenciosamente.

E-mails críticos que seriam silenciosamente perdidos:
- E-mail de boas-vindas (onboarding)
- E-mail de trial expirando
- E-mail de cobrança gerada
- E-mail de assinatura bloqueada
- E-mail de reset de senha

## Problema
Clientes em trial não recebem aviso de expiração. Usuários que pedem reset de senha não recebem o e-mail. Nenhum erro visível — simplesmente não funciona.

## Impacto
- Churn por falta de comunicação de trial
- Usuários impossibilitados de recuperar senha
- Percepção de produto quebrado

## Dependências
- Acesso ao ambiente de produção (Railway) para verificar a variável `SPRING_PROFILES_ACTIVE`

## Critérios de Aceite
- [ ] Confirmar qual profile está ativo em produção (`SPRING_PROFILES_ACTIVE`)
- [ ] Confirmar que `MailerSendServiceImpl` está sendo instanciado em produção
- [ ] Enviar e-mail de teste em produção e confirmar recebimento
- [ ] Verificar logs do MailerSend (dashboard) para confirmar entregas
- [ ] Adicionar log explícito quando e-mail é enviado com sucesso ou falha

## Subtasks
- [ ] Verificar variável `SPRING_PROFILES_ACTIVE` no Railway
- [ ] Se profile for diferente de "local", alterar a annotation `@Profile` para o profile correto, ou usar um profile de produção que inclua o serviço de e-mail
- [ ] Enviar e-mail de teste para endereço real e confirmar
- [ ] Verificar dashboard do MailerSend para delivery rate

## Esforço
Pequeno (1-3h)

## Risco de não fazer
E-mails de trial, cobrança e reset de senha podem não estar sendo enviados em produção — problema crítico de produto descoberto somente quando clientes reclamarem.

## Status
Concluído
