# TASK-106 — Full-Stack: notificações escopadas por org (bug: clique em notificação de outra org causa erro)

## Tipo
FULL_STACK (BUGFIX)

## Categoria
Bug / Multi-tenant / UX

## Prioridade
🟠 Alto

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Contexto

### O bug

O sino de notificações exibe notificações de **todas as organizações** do usuário. Ao clicar em uma notificação da org Y enquanto a org X está ativa, o frontend navega para `/items/{referenceId}` enviando o `X-Org-Id` da org X. O backend retorna `"Item não pertence a essa organização"`, porque o item pertence à org Y.

### Diagnóstico técnico

O campo `orgCode` já existe e é corretamente persistido em `InAppNotification.orgCode`:

```java
// InAppNotification.java — o campo já existe
@Column(name = "org_code", length = 100)
private String orgCode;
```

`saveForOrg()` já popula o campo. `saveForUser()` não (notificações pessoais como `SUBSCRIPTION_BLOCKED` ficam com `orgCode = null`).

**Problema:** o repositório e o service ignoram o `orgCode` ao listar/contar:

```java
// InAppNotificationRepository — consultas atuais (sem filtro de org)
findTop20ByUserIdOrderByCreatedAtDesc(userId)           // retorna TODAS as orgs
countByUserIdAndReadAtIsNull(userId)                    // conta TODAS as orgs
markAllReadByUserId(userId)                             // marca TODAS as orgs como lidas
```

`InAppNotificationResponse` também não expõe `orgCode`, então o frontend não tem como saber a qual org pertence cada notificação.

---

## Regra de filtro

| Tipo de notificação    | `orgCode` no banco | Deve aparecer quando |
|------------------------|-------------------|----------------------|
| `ITEM_DUE`             | `orgCode = X`     | org X está ativa     |
| `MAINTENANCE_DUE`      | `orgCode = X`     | org X está ativa     |
| `SUBSCRIPTION_BLOCKED` | `null`            | sempre (pessoal)     |

Filtro: **`orgCode = :currentOrg OR orgCode IS NULL`**

---

## O que fazer

### Backend

#### 1. `InAppNotificationRepository` — novos métodos

```java
// Listagem: org ativa + pessoais (orgCode IS NULL)
@Query("""
    SELECT n FROM InAppNotification n
    WHERE n.userId = :userId
      AND (n.orgCode = :orgCode OR n.orgCode IS NULL)
    ORDER BY n.createdAt DESC
    LIMIT 20
""")
List<InAppNotification> findTop20ForUserAndOrg(
    @Param("userId") Long userId,
    @Param("orgCode") String orgCode
);

// Contagem: mesmo critério
@Query("""
    SELECT COUNT(n) FROM InAppNotification n
    WHERE n.userId = :userId
      AND n.readAt IS NULL
      AND (n.orgCode = :orgCode OR n.orgCode IS NULL)
""")
long countUnreadForUserAndOrg(
    @Param("userId") Long userId,
    @Param("orgCode") String orgCode
);

// Mark all read: escopado por org + pessoais
@Modifying
@Transactional
@Query("""
    UPDATE InAppNotification n
    SET n.readAt = CURRENT_TIMESTAMP
    WHERE n.userId = :userId
      AND n.readAt IS NULL
      AND (n.orgCode = :orgCode OR n.orgCode IS NULL)
""")
void markAllReadForUserAndOrg(
    @Param("userId") Long userId,
    @Param("orgCode") String orgCode
);
```

> Manter os métodos antigos (`findTop20ByUserIdOrderByCreatedAtDesc`, `countByUserIdAndReadAtIsNull`, `markAllReadByUserId`) — ainda são usados internamente se orgCode for null. Não deletar.

#### 2. `InAppNotificationService` — usar `TenantContext`

```java
// Inject TenantContext (ou ler via TenantContext.get())
public List<InAppNotificationResponse> listForUser(Long userId) {
    String orgCode = TenantContext.get();
    if (orgCode != null) {
        return repository.findTop20ForUserAndOrg(userId, orgCode)
                .stream().map(this::toResponse).toList();
    }
    // fallback: sem org → apenas pessoais (ou legado — retornar tudo para compatibilidade)
    return repository.findTop20ByUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toResponse).toList();
}

public long countUnread(Long userId) {
    String orgCode = TenantContext.get();
    if (orgCode != null) {
        return repository.countUnreadForUserAndOrg(userId, orgCode);
    }
    return repository.countByUserIdAndReadAtIsNull(userId);
}

public void markAllRead(Long userId) {
    String orgCode = TenantContext.get();
    if (orgCode != null) {
        repository.markAllReadForUserAndOrg(userId, orgCode);
    } else {
        repository.markAllReadByUserId(userId);
    }
}
```

#### 3. `InAppNotificationResponse` — expor `orgCode`

```java
public record InAppNotificationResponse(
        Long id,
        String title,
        String body,
        InAppNotificationType type,
        Long referenceId,
        String referenceLabel,
        boolean read,
        Instant createdAt,
        String orgCode          // ← campo novo (nullable)
) {}
```

Ajustar `toResponse()` em `InAppNotificationService` para incluir `n.getOrgCode()`.

#### 4. `GET /me/notifications` — precisa de X-Org-Id

O endpoint atualmente exige `X-Org-Id` (está no filtro padrão, não no bypass). Já está correto — `TenantContext.get()` sempre terá valor nesse endpoint. Não precisa alterar o `NotificationController` nem o `TenantFilter`.

---

### Frontend

#### `NotificationBell.tsx` — adicionar `orgCode` ao tipo

```tsx
type NotificationItem = {
  id: number;
  title: string;
  body: string | null;
  type: "ITEM_DUE" | "MAINTENANCE_DUE" | "SUBSCRIPTION_BLOCKED";
  referenceId: number | null;
  referenceLabel: string | null;
  read: boolean;
  createdAt: string;
  orgCode: string | null;   // ← campo novo
};
```

**Com o backend filtrando por org, o bug principal já estará resolvido.** O `orgCode` no frontend é útil para defesa em profundidade: se por algum motivo uma notificação de org diferente escapar, o frontend pode detectar e exibir aviso ao invés de navegar.

> Nenhuma outra mudança de UI necessária no frontend — o bell passará a mostrar apenas notificações da org ativa automaticamente.

---

## Critérios de Aceite

- [ ] `GET /me/notifications` retorna apenas notificações da org ativa (`orgCode = currentOrg OR orgCode IS NULL`)
- [ ] Badge de não-lidas conta apenas notificações da org ativa + pessoais
- [ ] "Marcar todas como lidas" afeta apenas notificações da org ativa + pessoais (não de outras orgs)
- [ ] Clicar em uma notificação navega corretamente (item/manutenção pertencem à org ativa)
- [ ] `SUBSCRIPTION_BLOCKED` (sem orgCode) continua aparecendo independente da org
- [ ] `InAppNotificationResponse` inclui campo `orgCode` (nullable)
- [ ] Testes unitários: listagem com orgCode presente, listagem sem orgCode (fallback), countUnread, markAllRead escopado

## Esforço Estimado
Médio — backend cirúrgico (repository queries + service) + ajuste mínimo de frontend

## Dependências
Nenhuma — `orgCode` já existe na tabela e é preenchido pelo `saveForOrg()`

## Risco
- `markAllRead` atual marcava todas as orgs — depois da fix, marcará apenas a org ativa. Comportamento correto mas mudança de semântica a comunicar.
- `saveForUser()` persiste `orgCode = null` — garantir que essas notificações continuem aparecendo (cobertas pelo `OR orgCode IS NULL`)
