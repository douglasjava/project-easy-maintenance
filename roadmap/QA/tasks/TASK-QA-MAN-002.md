# TASK-QA-MAN-002 — Teste de Isolamento Multi-Tenant com X-Org-Id Manipulado

## Tipo
QA Manual

## Categoria
Segurança / Multi-tenancy

## Prioridade
🔴 Crítico

## Épico
EPIC-003 — Multi-tenancy e Autorização

## Flow relacionado
[FLOW-002](../Flow/FLOW-002.md)

## Documento de Teste
[MTD-002](../MTD/MTD-002.md)

## Descrição
Validação manual do isolamento entre tenants. Verificar que um usuário autenticado não consegue acessar, listar ou modificar dados de outra organização substituindo manualmente o header `X-Org-Id` nas requisições.

Esta validação cobre o risco de IDOR (Insecure Direct Object Reference) entre tenants, implementado nas tasks TASK-009 e TASK-017.

## Pré-condições
- Duas organizações distintas criadas no ambiente: Org A e Org B
- Cada organização com pelo menos 5 itens, 5 manutenções e 2 usuários criados
- Anotar o `orgCode` de cada organização (visível nas requests do frontend)
- Ferramenta de API instalada: Postman, Insomnia ou similar
- Usuário autenticado na Org A com cookie JWT válido

## Passos

### Passo 1 — Capturar headers válidos da Org A
1. Autenticar como usuário da Org A no frontend
2. Abrir DevTools → Network → localizar request para `/items`
3. Copiar o valor do header `X-Org-Id` (será o código da Org A)
4. Copiar também o cookie de sessão

### Passo 2 — Tentar acessar dados da Org B
1. No Postman, criar request: `GET {API_URL}/items`
2. Adicionar headers: Cookie (token da Org A) + `X-Org-Id: {orgCode_OrgB}`
3. Enviar a request
4. Anotar o código HTTP da resposta

### Passo 3 — Verificar em múltiplos endpoints
Repetir o Passo 2 para:
- `GET /maintenances`
- `GET /users`
- `POST /items` (com body de item válido)
- `DELETE /items/{id_item_da_OrgA}`

### Passo 4 — Confirmar que X-Org-Id correto funciona (regressão)
1. Com o mesmo cookie da Org A, usar `X-Org-Id` correto da Org A
2. Verificar que `GET /items` retorna HTTP 200 com dados da Org A

### Passo 5 — Verificar filtro de repositório
1. Autenticar como usuário da Org A com X-Org-Id correto
2. Fazer `GET /items` e anotar a quantidade retornada
3. Verificar no banco: `SELECT COUNT(*) FROM maintenance_items WHERE org_code = '{orgCode_A}'`
4. Confirmar que a contagem é idêntica

## Resultado Esperado
- HTTP 403 em todos os endpoints com X-Org-Id de outra organização
- Zero dados da Org B retornados em qualquer circunstância
- HTTP 200 mantido com X-Org-Id correto (sem regressão)
- Contagem de itens no endpoint = contagem SQL com filtro de tenant

## Evidências Necessárias
- [ ] Screenshot das respostas 403 no Postman para cada endpoint testado
- [ ] Screenshot da resposta 200 com dados corretos da Org A (regressão)
- [ ] Resultado da query SQL vs contagem do endpoint

## Status
Pendente — executar antes do lançamento
