# TASK-005 — Desabilitar Swagger/OpenAPI em produção

## Tipo
Segurança

## Categoria
Backend / Segurança / Configuração

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
O `OpenApiConfig.java` configura SpringDoc para expor a documentação da API em `/swagger-ui.html` e `/v3/api-docs`. Se não houver restrição por perfil ou autenticação, qualquer pessoa pode acessar o schema completo da API em produção.

## Problema
Swagger exposto em produção fornece a um atacante:
- Mapa completo de todos os endpoints
- Parâmetros esperados por cada endpoint
- Modelos de dados (incluindo campos internos)
- Headers requeridos (incluindo `X-Org-Id`)
- Exemplos de request/response

## Impacto
- Redução significativa da barreira de entrada para ataques direcionados
- Exposição de lógica de negócio via schema

## Dependências
- Nenhuma

## Critérios de Aceite
- [ ] Em ambiente de produção (`spring.profiles.active=prod`), `/swagger-ui.html` retorna 404 ou 403
- [ ] Em ambiente de produção, `/v3/api-docs` retorna 404 ou 403
- [ ] Swagger continua funcionando em ambientes de desenvolvimento e homologação
- [ ] Profile de produção configurado nas variáveis de ambiente do Railway

## Subtasks
- [ ] Criar `application-prod.properties` (se não existir) com:
  ```properties
  springdoc.swagger-ui.enabled=false
  springdoc.api-docs.enabled=false
  ```
- [ ] Verificar que `SPRING_PROFILES_ACTIVE=prod` está configurado no Railway
- [ ] Testar acesso a `/swagger-ui.html` em produção após deploy

## Esforço
Pequeno (30 min - 1h)

## Risco de não fazer
Qualquer pessoa pode mapear toda a API de produção sem nenhuma autenticação.

## Status
Concluído
