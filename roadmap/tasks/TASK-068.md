# TASK-068 — Enriquecer response de notificações com nome do item referenciado

## Tipo

Backend

## Categoria

Notificações / DX / UX

## Prioridade

🟡 Médio

## Fase

2 — Pré-produção / Refinamento UX

## Épico

EPIC-006 — Experiência do Usuário e Onboarding

## Descrição

O endpoint `GET /me/notifications` retorna notificações com o campo `body` genérico que referencia apenas o ID do item:

```json
{
  "id": 10,
  "title": "Item próximo do vencimento",
  "body": "Item (ID: 19) vence em 30 dia(s).",
  "type": "ITEM_DUE",
  "referenceId": 19,
  "read": true,
  "createdAt": "2026-05-23T05:00:00Z"
}
```

O ID `19` não tem significado para o usuário final. Nenhum contexto adicional (nome, tipo, categoria do item) é fornecido. Isso resulta em notificações opacas que obrigam o usuário a navegar manualmente até o item para entender do que se trata.

### Comportamento esperado

O campo `body` deve referenciar o nome do item diretamente, e o response deve incluir campos de metadados úteis para o frontend renderizar a notificação de forma rica:

```json
{
  "id": 10,
  "title": "Item próximo do vencimento",
  "body": "Extintor CO2 - Corredor B vence em 30 dia(s).",
  "type": "ITEM_DUE",
  "referenceId": 19,
  "referenceLabel": "Extintor CO2 - Corredor B",
  "read": true,
  "createdAt": "2026-05-23T05:00:00Z"
}
```

## Problema atual

- `body` usa `"Item (ID: X)"` — ID não é informação útil para o usuário
- Não há campo `referenceLabel` no DTO com o nome legível do recurso referenciado
- O frontend exibe a notificação sem contexto — o usuário não sabe qual item precisa de atenção sem clicar
- Dificulta implementações futuras de notificações ricas (push, e-mail) que dependem do nome do item

## Estratégia de implementação

### Abordagem recomendada: enriquecer no momento de criação da notificação

Atualizar o template do `body` nos jobs/serviços que geram as notificações (ex.: job de vencimento de itens) para incluir o nome do item ao persistir a mensagem. O texto é fixado no momento da criação — resiliente a renomeações posteriores do item.

Adicionalmente, adicionar `referenceLabel` ao DTO de resposta, preenchido via JOIN ou consulta auxiliar no serviço de leitura de notificações, para todos os tipos que possuem um `referenceId`.

### Tipos de notificação afetados

| `type`              | `referenceId` aponta para | `referenceLabel` esperado        |
|---------------------|--------------------------|----------------------------------|
| `ITEM_DUE`          | `items.id`               | Nome do item                     |
| `ITEM_OVERDUE`      | `items.id`               | Nome do item                     |
| `MAINTENANCE_DUE`   | `maintenances.id`        | Descrição/tipo + nome do item    |

## Impacto

- **UX**: notificações tornam-se autoexplicativas — o usuário entende o alerta sem navegar
- **Futuro**: habilita notificações push e e-mails com conteúdo rico
- **Confiança no produto**: detalhe que diferencia produto polido de MVP crú

## Critérios de Aceite

### Backend
- [ ] `body` das notificações do tipo `ITEM_DUE` e `ITEM_OVERDUE` inclui o nome do item (ex.: `"Extintor CO2 - Corredor B vence em 30 dia(s)."`)
- [ ] `NotificationResponseDTO` inclui campo `referenceLabel: String` (nullable)
- [ ] `referenceLabel` é preenchido com o nome do item para os tipos `ITEM_DUE` e `ITEM_OVERDUE`
- [ ] Jobs que geram notificações são atualizados para persistir o nome do item no `body`
- [ ] Notificações já existentes com `body` antigo não são alteradas retroativamente (campo nullable)
- [ ] Nenhum N+1 introduzido — `referenceLabel` resolvido em batch ou via JOIN

### Frontend
- [ ] Painel de notificações exibe `referenceLabel` quando disponível (ex.: badge ou linha secundária com o nome do item)
- [ ] Link "Ver item" usa `referenceId` para navegar para `/items/{id}` quando `type = ITEM_DUE | ITEM_OVERDUE`

## Subtasks

- [ ] Backend: atualizar template do `body` no job de vencimento de itens para incluir nome do item
- [ ] Backend: adicionar `referenceLabel` ao `NotificationResponseDTO`
- [ ] Backend: popular `referenceLabel` no serviço de leitura de notificações via JOIN com `items`
- [ ] Frontend: atualizar componente de notificação para exibir `referenceLabel` e link de navegação

## Arquivos afetados

**Backend:**
- `src/main/java/com/easymaintenance/notification/dto/NotificationResponseDTO.java`
- `src/main/java/com/easymaintenance/notification/service/NotificationService.java`
- Job/service responsável pela criação de notificações de vencimento de itens

**Frontend:**
- Componente de listagem de notificações no header

## Esforço

Baixo–Médio (0,5–1 dia)

## Risco de não fazer

- Notificações continuam opacas e inúteis sem navegação manual
- Retrabalho maior no futuro ao implementar push notifications ou e-mails com conteúdo rico

## Status

Done
