# TASK-098 — Backend: endpoint `/me/team/users` — CRUD de membros com multi-org assignment

## Tipo
BACKEND

## Categoria
Backend / Equipe / Convite de Usuário

## Prioridade
🔴 Crítico

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Contexto

O fluxo de gestão de membros é de **conta** (nível do dono), não de organização. Fulano (ADMIN)
pode ter org A, org B e org C. Ao convidar João, Fulano escolhe quais dessas orgs João vai acessar.
O endpoint existente `POST /organizations/{orgCode}/users` é org-scoped e não suporta esse modelo.

Precisamos de um conjunto de endpoints no escopo `/me/team/users` que operem em cima das organizações
do usuário autenticado.

---

## Subtasks

### TASK-098-A — `GET /me/team/users` — listar membros gerenciados pelo dono

Retorna todos os usuários vinculados a **qualquer** das organizações do usuário autenticado,
desduplicados por usuário. Para cada membro:
```json
{
  "id": 42,
  "name": "João Silva",
  "email": "joao@empresa.com",
  "role": "READER",
  "status": "ACTIVE",
  "organizations": [
    { "code": "ORGABC", "name": "Empresa A" },
    { "code": "ORGDEF", "name": "Empresa B" }
  ]
}
```
- Não retorna o próprio dono (excluir o usuário autenticado da lista)
- Suporta filtros opcionais: `?name=` e `?email=`
- Requer autenticação; não requer `X-Org-Id` (opera sobre todas as orgs do dono)

---

### TASK-098-B — `POST /me/team/users` — convidar novo membro

Cria um membro e o vincula às organizações selecionadas pelo dono.

**Request:**
```json
{
  "email": "joao@empresa.com",
  "name": "João Silva",
  "role": "READER",
  "orgCodes": ["ORGABC", "ORGDEF"]
}
```

**Lógica:**
1. Verificar que o dono autenticado é dono de todas as `orgCodes` informadas → 403 se alguma não for
2. Validar `maxUsers` do plano do dono (via subscription do dono, `SOURCE_TYPE=USER`) — se atingido → RuleException
3. Se usuário com o e-mail já existe: vincular às orgs (sem criar duplicata, sem reenviar e-mail)
4. Se usuário é novo: criar com senha aleatória → `adminService.initializeUserAccess(user)` → e-mail de convite
5. Para cada `orgCode`: criar `UserOrganization` com role e status ACTIVE
6. Resposta: 201 com o DTO do membro criado + orgs vinculadas

---

### TASK-098-C — `PATCH /me/team/users/{memberId}` — atualizar membro

Permite alterar nome, role e lista de orgs vinculadas.

**Request:**
```json
{
  "name": "João Silva",
  "role": "VIEWER",
  "orgCodes": ["ORGABC"]  // nova lista completa; orgs removidas são desvinculadas
}
```

- Verifica que o `memberId` pertence à equipe do dono (dono tem pelo menos uma org em comum)
- Atualiza `UserOrganization` rows: adiciona novas, remove as que saíram da lista
- Não reenvia e-mail de convite

---

### TASK-098-D — `DELETE /me/team/users/{memberId}` — remover membro

Remove o vínculo do membro com **todas** as organizações do dono.

- Verifica que o `memberId` está na equipe do dono → 404 caso contrário
- Deleta (ou inativa) os `UserOrganization` rows do dono com aquele membro
- **Não** apaga o usuário do sistema — o membro pode existir em outras contas
- Resposta: 204 No Content

---

## Critérios de Aceite

- [ ] `GET /me/team/users` retorna membros de todas as orgs do dono, desduplicados, com orgs listadas
- [ ] `POST /me/team/users` cria o membro e vincula às orgs informadas
- [ ] `POST` verifica ownership das orgs (dono só pode usar suas próprias orgs)
- [ ] `POST` valida `maxUsers` do plano do dono antes de criar
- [ ] `POST` com e-mail já existente vincula sem reenviar convite
- [ ] `POST` com e-mail novo cria + envia e-mail de convite via `initializeUserAccess()`
- [ ] `PATCH /me/team/users/{id}` atualiza nome, role e orgs (add/remove)
- [ ] `DELETE /me/team/users/{id}` remove vínculos sem deletar o usuário do sistema
- [ ] Todos os endpoints retornam 403 se caller não é ADMIN de nenhuma org
- [ ] Testes cobrindo: convite novo, convite e-mail existente, limite atingido, remoção, orgs inválidas

## Esforço Estimado
Alto — novo módulo backend com 4 endpoints. A lógica de multi-org assignment e deduplicação são os
pontos mais complexos.

## Riscos
- `maxUsers` counter: definir claramente se é "membros únicos que o dono gerencia" ou "vínculos org-usuário". Recomendar: usuários únicos (sem contar orgs).
- Membership check: garantir que o dono não consegue editar/deletar membros de outras contas.
- Email idempotência: usuário existente vinculado a nova org não deve receber e-mail de convite duplicado.
