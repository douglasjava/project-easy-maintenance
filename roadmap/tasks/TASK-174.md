# TASK-174 — Backend: fornecedores no WhatsApp (NEAR_DUE de 30 dias, template dedicado)

## Tipo
BACKEND

## Categoria
Notificações / Fornecedores

## Prioridade
🟡 Médio

## Épico
[EPIC-023](../epics/EPIC-023.md) — Fornecedores nas Notificações de Vencimento

## QA obrigatório
Sim, mas com uma pendência estrutural: o template `vencimento_manutencao_v3` precisa estar
aprovado pela Meta pra QA de envio real acontecer — sem isso, só dá pra validar o payload/lógica
localmente (mock), igual ao caminho que o `v2` percorreu no EPIC-015. `notification.whatsapp.
supplier-template-enabled=false` por padrão garante que isso não afeta produção antes da aprovação.

---

## Contexto

Card original (18/08/2026) previa migrar de `v2` pra `v3` de vez, disparando no `NEAR_DUE` dia 1 e
em todo `OVERDUE`. Duas mudanças desde então:

1. **TASK-226** mudou o roteamento de canal: `WHATSAPP` agora dispara em todos os 4 checkpoints de
   `NEAR_DUE` (30/15/7/1), e só no dia do vencimento (`daysOffset==0`) do lado `OVERDUE` — não mais
   em todos os checkpoints de atraso.
2. **Revisão de produto (Douglas, 03/09/2026)**, mesma lógica já aplicada na TASK-173 (e-mail):
   fornecedor faz mais sentido **antes** de vencer, e só uma vez (checkpoint de 30 dias) pra não
   virar ruído nem repetir a mesma dupla de fornecedor em 4 mensagens.

Diferença chave em relação à TASK-173: aqui `v2` (aprovado, 5 variáveis) e `v3` (novo, 9 variáveis)
**coexistem** — `v2` continua sendo o template padrão pra tudo, `v3` é usado só no checkpoint de 30
dias quando a busca encontra fornecedor suficiente. Isso abre uma opção que o card original não
tinha: se a busca achar menos de 2 fornecedores, **cai pro `v2` normal** em vez de pular o envio
inteiro — decisão confirmada com Douglas em 03/09/2026 (estritamente melhor: a pessoa ainda recebe
o aviso de 30 dias, só sem a seção de fornecedor).

Detalhe original em `docs/superpowers/specs/2026-08-18-supplier-notifications-design.md` — este
card diverge dele nos pontos acima.

## Objetivo

WhatsApp do checkpoint `NEAR_DUE` de 30 dias passa a tentar incluir 2 fornecedores fixos (nome +
telefone) via template novo `vencimento_manutencao_v3`. Todos os outros checkpoints (15/7/1/dia do
vencimento) continuam no `v2`, sem mudança.

## Escopo

### 1. Submissão do template à Meta (ação do Douglas, fora do código)
Novo template HSM `vencimento_manutencao_v3`, 9 variáveis de corpo: as 5 atuais (`recipientName,
itemName, companyName, dueDate, supportPhone`) + `supplier1Name, supplier1Phone, supplier2Name,
supplier2Phone`. Precisa ser submetido e aprovado antes de ativar `notification.whatsapp.
supplier-template-enabled=true` em produção — mesmo risco de demora documentado no EPIC-015 pro `v2`.

### 2. Código (pode ser implementado e testado antes da aprovação)

- **Novo helper compartilhado** (`NotificationSupplierResolver` ou nome equivalente,
  `infrastructure/notification/service`): centraliza organização → cidade/estado, `referenceId` →
  `item_type` (via `MaintenanceItemRepository`/`MaintenanceRepository`, mesma lógica hoje duplicada
  só em `BusinessEmailNotificationService`), mapeamento pra keyword (`SupplierCategoryKeywords`) e
  chamada ao `SupplierLookupService`. `BusinessEmailNotificationService.resolveNearbySuppliers`
  refatorado pra usar esse helper (mantém sua própria guarda de `daysOffset==30`/`NEAR_DUE`, delega
  a resolução em si).
- **`BusinessWhatsAppNotificationService.buildPayload()`**: se o dispatch for `NEAR_DUE` com
  `daysOffset==30` **e** `notification.whatsapp.supplier-template-enabled=true`, chama o helper.
  - 2+ fornecedores encontrados → payload com 9 variáveis, `templateName` explícito
    (`vencimento_manutencao_v3`, via `notification.whatsapp.supplier-template-name`).
  - Menos de 2 encontrados, ou flag desligada, ou outro checkpoint → payload padrão de sempre (5
    variáveis, `v2`), **sem pular o envio**.
- **`WhatsAppNotificationProvider.extractBodyParams`**: passa a incluir as 4 variáveis novas
  (`supplier1Name/Phone`, `supplier2Name/Phone`) quando presentes em `templateData` — genérico, não
  precisa saber qual template está sendo usado.
- **Config nova**:
  - `notification.whatsapp.supplier-template-name=vencimento_manutencao_v3`
  - `notification.whatsapp.supplier-template-enabled=false` — **desligado por padrão**. Código fica
    pronto e no ar, mas só tenta usar o `v3` depois que Douglas confirmar a aprovação da Meta e
    ligar essa flag (sem precisar de redeploy).

## Critérios de Aceite

- [ ] Template `vencimento_manutencao_v3` submetido à Meta (Douglas, fora do código) — pendente
- [x] `NEAR_DUE daysOffset=30` com flag ligada e 2+ fornecedores → payload com 9 variáveis,
      `templateName=vencimento_manutencao_v3`
- [x] `NEAR_DUE daysOffset=30` com flag ligada e <2 fornecedores → payload padrão (5 variáveis,
      `v2`), envio **não** é pulado
- [x] Flag desligada (padrão) → sempre payload padrão, nunca chama `SupplierLookupService`
- [x] Outros checkpoints (`daysOffset` 15/7/1, `daysOffset=0` do `OVERDUE`) → payload padrão, nunca
      chama `SupplierLookupService`
- [x] `WhatsAppNotificationProvider` extrai as 4 variáveis novas na ordem certa quando presentes
- [x] `BusinessEmailNotificationService` continua funcionando via o helper compartilhado, sem
      regressão nos testes da TASK-173
- [x] Testes cobrindo os cenários acima
- [x] `mvn test` sem regressão (906/906)

## Dependências
TASK-172 (`SupplierLookupService`), TASK-173 (padrão de resolução de fornecedor a partir do
evento, agora extraído pro helper compartilhado). Aprovação do template pela Meta é pré-requisito
só pra ativar a flag em produção, não bloqueia implementação/testes.

## Riscos
- **Aprovação da Meta** é dependência externa fora do controle da implementação — mesmo risco que
  já atrasou o `v2`. Mitigado pela flag `supplier-template-enabled=false`: task fica pronta e
  "Em Validação" sem risco de tentar enviar com template não aprovado.
- Refatorar `BusinessEmailNotificationService` pra usar o helper compartilhado toca em código já
  coberto por testes da TASK-173 — mitigado rodando a suite completa antes/depois (TDD).
- Se o texto exato aprovado pela Meta divergir do planejado (ordem/redação), pode precisar ajuste
  fino depois da aprovação — normal nesse tipo de processo.

## Esforço
Médio (mais a incerteza de tempo da aprovação externa, fora do esforço de código em si)

## Status
✅ Código implementado, PR aberta contra `staging`: [api#80](https://github.com/douglasjava/easy-maintenance-api/pull/80).
Branch `feature/TASK-174-supplier-in-whatsapp-notification`. TDD: todos os testes tocados falharam
por erro de compilação antes da implementação, passaram depois. `mvn test` → 906/906, 0 regressão.
**Bloqueado pra produção**: falta Douglas submeter `vencimento_manutencao_v3` à Meta e ligar
`notification.whatsapp.supplier-template-enabled=true` depois da aprovação. Sem isso, o código fica
no ar mas inativo (sempre usa `v2`, sem fornecedor) — comportamento seguro por padrão. Com essa PR,
a EPIC-023 fica com todo o código pronto; só falta a aprovação externa da Meta.
