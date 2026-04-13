# TASK-010 — Auditar e rotacionar secrets no repositório

## Tipo
Segurança

## Categoria
Backend / Segurança / DevOps

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
Arquivos de configuração como `application.properties` e `application-local.properties` podem conter chaves de API (OpenAI, MailerSend, Asaas, Firebase, AWS) que foram commitadas no repositório ao longo do desenvolvimento. Mesmo que atualmente estejam em `.gitignore`, o histórico do git pode conter versões com secrets expostos.

Secrets identificados em risco:
- Chave de API OpenAI
- Chave de API Asaas
- Chave de API MailerSend
- Credenciais AWS (S3)
- Service Account JSON do Firebase
- Variáveis de banco de dados

## Problema
Qualquer pessoa com acesso ao repositório (colaboradores passados, vazamento de repositório) tem acesso a todas as chaves de API históricas.

## Impacto
- Uso não autorizado de OpenAI (custo)
- Acesso indevido ao Asaas (dados financeiros dos clientes)
- Acesso ao banco de dados de produção
- Acesso ao S3 (dados de anexos)

## Dependências
- Acesso ao repositório git
- Acesso às plataformas para rotacionar as chaves

## Critérios de Aceite
- [ ] `git log --all --full-history -- "*/application*.properties"` revisado para secrets
- [ ] Todas as chaves encontradas no histórico foram rotacionadas nas plataformas correspondentes
- [ ] `application-local.properties` adicionado ao `.gitignore` se não estiver
- [ ] `.env.example` (ou equivalente) documenta quais variáveis são necessárias sem expor valores
- [ ] Novo arquivo `application-prod.properties` usa apenas `${ENV_VAR_NAME}` para todos os secrets
- [ ] Ferramenta como `git-secrets` ou `truffleHog` executada para confirmar que não há secrets no histórico

## Subtasks
- [ ] Instalar e executar `truffleHog` ou `git-secrets` no repositório
- [ ] Documentar todos os secrets encontrados no histórico
- [ ] Rotacionar: chave OpenAI
- [ ] Rotacionar: token Asaas
- [ ] Rotacionar: chave MailerSend
- [ ] Rotacionar: credenciais AWS IAM
- [ ] Rotacionar: service account Firebase
- [ ] Rotacionar: senha do banco de dados
- [ ] Verificar `.gitignore` para arquivos de configuração local
- [ ] Atualizar `application-prod.properties` para usar placeholders

## Esforço
Pequeno (2-4h)

## Risco de não fazer
Chaves de API expostas no git history são um vazamento de credenciais — mesmo que o repositório seja privado hoje, pode não ser amanhã.

## Status
Concluído
