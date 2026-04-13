# TASK-009 — Validar X-Org-Id contra claims do JWT

## Tipo
Segurança

## Categoria
Backend / Segurança / Multi-tenancy

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-003 — Multi-tenancy e Autorização

## Descrição
O frontend injeta o header `X-Org-Id` em todas as requisições autenticadas via `apiClient.ts`. O backend usa esse header para popular o `TenantContext`. Se o backend não verificar que o usuário autenticado (presente no JWT) realmente pertence à organização indicada no header, qualquer usuário pode trocar o valor de `X-Org-Id` e potencialmente acessar dados de outra organização.

## Problema
Se a validação for apenas "o header existe" sem verificar "o usuário pertence a essa org", temos um IDOR (Insecure Direct Object Reference) que permite escalonamento lateral entre tenants.

## Impacto
- Um usuário autenticado pode acessar dados de qualquer organização apenas trocando o header
- Data leak entre tenants — violação de privacidade e confiança

## Dependências
- Entender o fluxo atual de `TenantContext` e onde o X-Org-Id é validado

## Critérios de Aceite
- [ ] A cada request autenticado, verificar que o `orgCode` do `X-Org-Id` está na lista de organizações do usuário autenticado (presente no JWT ou consultada do banco)
- [ ] Request com `X-Org-Id` de organização à qual o usuário não pertence retorna 403
- [ ] Validação ocorre em filtro/interceptor global, não em cada controller individualmente
- [ ] Teste: usuário da org A com `X-Org-Id` da org B recebe 403

## Subtasks
- [ ] Mapear onde `X-Org-Id` é processado atualmente (filtro, interceptor ou diretamente no `TenantContext`)
- [ ] Verificar se o JWT contém a lista de organizações do usuário
- [ ] Implementar validação cruzada no filtro de autenticação/tenant
- [ ] Adicionar teste de integração cobrindo o cenário de acesso indevido

## Esforço
Pequeno (2-4h)

## Risco de não fazer
IDOR entre tenants — brecha que permite qualquer usuário acessar dados de qualquer organização.

## Status
Concluído
