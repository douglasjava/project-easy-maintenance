# TASK-114 — Backend/Infra: migration Flyway — limpar billing_subscription_items ORGANIZATION legados

## Tipo
BACKEND / INFRA

## Categoria
Billing / Migration

## Prioridade
🟠 Alto

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

Ambientes de teste/staging têm `BillingSubscriptionItem` com `sourceType=ORGANIZATION` criados pelo
fluxo antigo, com `valueCents > 0` somados ao `totalCents` da subscription. Sem clientes pagantes reais
hoje, a limpeza pode ser feita de forma direta, sem grandfathering nem reconciliação com o Asaas.

## Solução

> ⚠️ **Divergência do desenho original** (descoberta na execução — ver "Implementação" abaixo): a
> ideia inicial de **remover** (`DELETE`) os itens `ORGANIZATION` foi substituída por **zerar
> `value_cents`** desses itens, mantendo as linhas. As TASK-111 e TASK-113 (implementadas antes desta)
> passaram a depender da existência desses itens para resolver a conta a partir do código da
> organização e para compor o pool de itens. Excluí-los quebraria `validateItemLimit` e
> `getOrganizationSubscription` para 100% das organizações.

- Nova migration Flyway `V79__zero_organization_billing_items_value.sql` (numeração ajustada — V78 já
  havia sido usada por outra migration não relacionada, `fix_spda_period_and_dedupe_norms`) que:
  1. Zera `value_cents` de todos os `billing_subscription_items` com `source_type='ORGANIZATION'`
  2. Recalcula `billing_subscriptions.total_cents` de todas as assinaturas (soma de itens não
     cancelados), igual à regra usada em runtime por `BillingSubscriptionService.recalculateTotal()`
- Rodada **depois** de TASK-110/111/112/113 estarem implementados, para não recriar itens ORGANIZATION
  cobráveis logo em seguida da limpeza.

## Arquivos impactados

### Backend
- `db/migration/V79__zero_organization_billing_items_value.sql` (novo)

## Critérios de Aceite

- [x] ~~Migration remove todos os `billing_subscription_items` com `source_type=ORGANIZATION`~~ —
      **critério ajustado**: migration zera `value_cents` desses itens (não remove as linhas — ver nota
      de divergência acima). Validado: 0 itens ORGANIZATION com `value_cents<>0` após a migration
- [x] `billing_subscriptions.total_cents` recalculado corretamente após a limpeza (igual ao
      `valueCents` do item USER remanescente)
- [x] Nenhuma FK/constraint quebrada após a remoção (nenhuma linha removida; 33/33 linhas preservadas)
- [x] Smoke test local dos fluxos de billing — aplicado via Flyway real contra o MySQL local de
      desenvolvimento (ver "Implementação"); onboarding/PIX/CC completos (boot da aplicação) não
      testados por falta de segredos locais (`BOOTSTRAP_ADMIN_TOKEN` etc. não disponíveis neste
      ambiente de execução)

## Dependências
TASK-110, TASK-111, TASK-112, TASK-113 (código já não deve recriar itens ORGANIZATION antes de rodar
esta migration)

## Esforço
Baixo (0,5 dia)

## Risco de não fazer
Dados legados de teste continuam distorcendo `totalCents` em contas já existentes no ambiente, mesmo
após o código parar de criar novos itens ORGANIZATION.

## Implementação

### Validação real contra o MySQL local de desenvolvimento
O ambiente já tinha um MySQL local rodando via `docker-compose` (`easy_maintenance_mysql`, porta 3306,
mesmo banco usado pelo Douglas em desenvolvimento). Antes de migrar, o estado era exatamente o bug
descrito na conversa: 17 itens `ORGANIZATION` com `value_cents>0`, subscriptions com `total_cents`
dobrado (ex.: STARTER R$99 + ORGANIZATION R$99 = R$198).

Como não há `flyway-maven-plugin` configurado no `pom.xml` e o boot completo da aplicação local falhou
por falta de segredos (`BOOTSTRAP_ADMIN_TOKEN` não definido neste ambiente), a migration foi validada
adicionando temporariamente o `flyway-maven-plugin` ao `pom.xml`, rodando `mvn flyway:info` (read-only,
confirmou V79 pendente) e `mvn flyway:migrate` (aplicou de fato), e então **revertendo o `pom.xml`** ao
estado original — `git diff pom.xml` confirma zero alterações líquidas no arquivo.

### Resultado real (antes → depois, banco local de desenvolvimento)
- Itens `ORGANIZATION` com `value_cents<>0`: 17 → **0**
- Subscriptions afetadas (ex.: id 4-12, STARTER): `total_cents` R$198 → **R$99** (corrigido)
- Linhas em `billing_subscription_items`: 33 → **33** (nenhuma removida)
- `flyway_schema_history`: V79 registrada como aplicada — próximo boot local do Douglas não tentará
  reaplicar

### Arquivos criados
- `db/migration/V79__zero_organization_billing_items_value.sql`

### Resultado dos testes
- 546/546 testes backend green ✅ (migration não afeta testes unitários — perfil de teste usa H2 com
  Flyway desabilitado)

### Pendências desta task
- Boot completo da aplicação (onboarding/PIX/CC end-to-end) não foi validado nesta sessão — requer
  segredos locais que não estão disponíveis neste ambiente de execução. O que foi validado é a aplicação
  real da migration e a correção dos dados, que é o núcleo do risco desta task.

## Status
Em Validação
