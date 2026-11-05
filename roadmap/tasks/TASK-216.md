# TASK-216 — FULL_STACK: "Próxima manutenção" no registro deixa de ser decorativa

## Tipo
FULL_STACK

## Categoria
Backend + Frontend / Registro de manutenção

## Prioridade
🟡 Médio

## Épico
Sem épico — comportamento incorreto encontrado por Douglas ao validar a TASK-215 em ambiente local,
30/08/2026.

## QA obrigatório
Sim — QA manual: registrar manutenção de um item REGULATORY (campo deve estar ausente/read-only,
`nextDueAt` do item sempre vem da norma) e de um item OPERATIONAL (campo editável, se preenchido
deve virar o `nextDueAt` real do item; se vazio, cai no cálculo automático `performedAt + período`).

---

## Contexto

Douglas registrou uma manutenção pro item 60 (EXTINTOR, REGULATORY, norma de 12 meses) e preencheu
"Data da Próxima manutenção" = `2026-10-29` no formulário. O item ficou com `next_due_at =
2027-08-11` (12 meses a partir do `performed_at`, calculado pela norma) — o valor que ele digitou
foi salvo só no registro histórico da manutenção (`maintenances.next_due_at`), sem nenhum efeito no
item. A tela sugere que a data informada é o que vai valer; não é.

## Causa raiz

`MaintenanceService.applyPerformedMaintenance` (chamada por `register()`) sempre recalcula
`item.nextDueAt` a partir de `performedAt + serviceBase.resolvePeriod(item)`, ignorando
`RegisterMaintenanceRequest.nextDueAt` por completo. Esse campo só é persistido no registro
histórico (`IMaintenanceMapper.toMaintenance`, `maintenance.setNextDueAt(req.nextDueAt())`) — vira
uma anotação sem função, mas a UI não deixa isso claro (campo editável, rotulado como se fosse a
data que vale).

## Decisão de produto (discutida com Douglas antes de abrir esta task)

O comportamento correto depende da categoria do item — mesmo princípio da TASK-212 (não deixar
input livre furar uma garantia central do produto):

- **REGULATORY**: a data é uma obrigação legal (norma + tolerância). Não pode ser sobrescrita por
  digitação livre — isso reabriria exatamente o risco que a TASK-212 fechou (usuário empurrando um
  prazo legal). Campo sai do formulário (ou vira preview somente-leitura da data que a norma vai
  calcular).
- **OPERATIONAL**: não há obrigação legal. O campo continua editável e passa a **valer de verdade**:
  se preenchido, define `item.nextDueAt` diretamente; se vazio, cai no cálculo automático
  (`performedAt + customPeriod`), como já acontece hoje.

## Escopo (proposto, a confirmar no `/execute-task`)

### Backend
- `MaintenanceService.applyPerformedMaintenance`: recebe o `nextDueAt` opcional do request.
  - Item REGULATORY com `nextDueAt` informado no request → rejeitar com `RuleException` clara
    ("Data da próxima manutenção não pode ser definida manualmente para itens regulatórios — é
    calculada automaticamente pela norma."). Falhar explícito em vez de ignorar silenciosamente —
    mesma filosofia da TASK-212 (backend autoritativo, sem fingir aceitar o que não usa).
  - Item OPERATIONAL com `nextDueAt` informado → usa esse valor direto pra `item.nextDueAt` (pula o
    cálculo por período).
  - Item OPERATIONAL sem `nextDueAt` → comportamento atual (calcula por `customPeriod`).
- Revisar se `resetToNeverPerformedState` (cancelamento de manutenção, RN-016) precisa de ajuste
  correspondente — a re-derivação após cancelar uma manutenção com override manual deve voltar pro
  cálculo automático, não tentar reaplicar o valor manual antigo.

### Frontend (`maintenances/new/page.tsx`)
- Campo "Próxima manutenção" (linha ~559) só aparece pra `selectedItem.itemCategory ===
  "OPERATIONAL"`. Pra REGULATORY, remover o campo do formulário (a tela já mostra "Vence:
  {formatDate(selectedItem.nextDueAt)}" na linha 475 com o valor real do item, que já cumpre o papel
  de mostrar a próxima data).

## Critérios de Aceite

- [x] `register()` rejeita `nextDueAt` manual pra item REGULATORY, com mensagem clara
- [x] `register()` aplica `nextDueAt` manual como `item.nextDueAt` pra item OPERATIONAL quando
      informado
- [x] `register()` sem `nextDueAt` continua calculando automaticamente (sem regressão pro
      comportamento atual)
- [x] Frontend: campo "Próxima manutenção" só aparece pra itens OPERATIONAL
- [x] Teste cobrindo os 3 casos (REGULATORY rejeita, OPERATIONAL usa o manual, OPERATIONAL sem
      valor cai no automático) — confirmados falhando sem o fix antes de reaplicar
- [x] `mvn clean test` (864/864, 0 falhas) e typecheck/lint do frontend sem regressão
- [ ] QA manual em produção pós-deploy (pendente)

## Dependências
Nenhuma (achada durante validação da TASK-215, independente dela).

## Riscos
Baixo — muda comportamento visível (campo sai do formulário pra REGULATORY; erro novo se a API for
chamada direto com `nextDueAt` nesse caso), mas fecha uma inconsistência que hoje já é confusa/sem
efeito real. Sem migração de dado necessária.

## Esforço
Baixo-Médio

## Status
✅ Implementado, PRs abertas contra `staging`:
[api#63](https://github.com/douglasjava/easy-maintenance-api/pull/63) e
[web#62](https://github.com/douglasjava/easy-maintenance-web/pull/62). Branch
`feature/TASK-216-operational-manual-next-due-date` nos dois repos. Suíte completa da API:
864/864, 0 falhas. Typecheck/lint do frontend sem regressão.
