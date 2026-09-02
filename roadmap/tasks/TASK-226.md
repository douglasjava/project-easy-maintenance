# TASK-226 — BACKEND: Reestrutura canais de notificação de vencimento (WhatsApp antecipado / e-mail no atraso)

## Tipo
BACKEND

## Categoria
Backend / Notificações (canais de disparo)

## Prioridade
🟡 Médio — não é bug, é ajuste de produto motivado por feedback direto de um cliente real em call.

## Contexto

Na call de demonstração, o cliente destacou que precisa de antecedência de pelo menos um mês antes
do vencimento de um item, porque precisa de tempo para buscar e contratar fornecedor (TASK-218 item
#4, já validado nesta sessão via leitura de código).

Hoje (`NotificationChannelResolver`, TASK-130):
- **NEAR_DUE** (checkpoints 30/15/7/1 dias antes de vencer): sempre PUSH; WHATSAPP só entra dentro de
  um limiar configurável em horas (`notification.whatsapp.urgent-threshold-hours=48`) que, arredondado
  pra dias inteiros contra os checkpoints fixos, na prática só alcançava `daysOffset==1` — ou seja, o
  zap só disparava faltando 1 dia, tarde demais pra buscar fornecedor.
- **OVERDUE** (checkpoints 0/-7/-15/-30, `daysOffset` sempre em valor absoluto): sempre PUSH + EMAIL +
  WHATSAPP, incondicional, em todos os 4 checkpoints de atraso.

## Decisão (Douglas, 02/09/2026)

- **NEAR_DUE**: WHATSAPP passa a entrar em **todos** os 4 checkpoints (30/15/7/1 dias antes), não só
  no mais urgente — ataca diretamente a necessidade relatada pelo cliente. PUSH continua sempre.
- **OVERDUE**: WHATSAPP só continua no dia do vencimento em si (`daysOffset==0`, ainda é o momento de
  maior urgência). A partir do primeiro checkpoint de atraso de verdade (7/15/30 dias vencidos), some
  o WHATSAPP e a escalação segue só por PUSH + EMAIL. PUSH continua sempre em todos os casos — sem
  motivo de custo pra tirá-lo, ao contrário do WhatsApp (mensagem paga via Meta Business API).
- Confirmado com Douglas via perguntas de esclarecimento antes de implementar (ver
  AskUserQuestion desta sessão): push sempre ativo, dia 0 mantém zap.

## Escopo

- `NotificationChannelResolver.java`: `nearDueChannels` some (vira sempre PUSH+WHATSAPP direto no
  `switch`); `overdueChannels` novo, condicionando WHATSAPP a `daysOffset==0`. Remove o campo
  `urgentThresholdHours` e o método `isWithinUrgentWindow`, que ficam sem uso.
- `application.properties`: remove `notification.whatsapp.urgent-threshold-hours` (config morta) e
  atualiza o comentário de orquestração do canal WhatsApp pra refletir a regra nova.
- `NotificationChannelResolverTest.java`: reescrito do zero pra cobrir os 3 cenários (near-due sempre
  com zap em todos os checkpoints; overdue no dia 0 mantém zap; overdue além do dia 0 perde zap).

## Critérios de Aceite

- [x] NEAR_DUE (30/15/7/1 dias antes) inclui WHATSAPP em todos os checkpoints
- [x] OVERDUE no dia do vencimento (`daysOffset==0`) mantém PUSH+EMAIL+WHATSAPP
- [x] OVERDUE além do dia do vencimento (7/15/30 dias de atraso) vira PUSH+EMAIL, sem WHATSAPP
- [x] PUSH continua presente em todos os casos, sem alteração
- [x] Config morta (`urgent-threshold-hours`) removida do código e do properties
- [x] Testes cobrindo os 3 cenários, validados via TDD (rodaram vermelho contra a implementação
      antiga antes do ajuste, verde depois)

## Dependências
Nenhuma — mudança isolada em `NotificationChannelResolver` e configuração, sem migration, sem
mudança de contrato de API. `NotificationOrchestratorService` já itera sobre o `Set<NotificationChannel>`
retornado sem nenhuma suposição sobre quais canais estão presentes, então não precisou de ajuste.

## Riscos
Baixo — troca de lógica de roteamento de canal já isolada num único service, coberta por teste
unitário direto. Risco de negócio a observar: aumento de volume de mensagens WhatsApp pagas nos
checkpoints 30/15/7 (hoje só o checkpoint 1 disparava zap) — mitigado pelo rate limit já existente
(`notification.whatsapp.daily-limit-per-recipient=3`) e pela redução simétrica no lado OVERDUE (deixa
de disparar zap nos 3 checkpoints de atraso profundo).

## Esforço
Baixo

## Status
✅ Implementada e testada localmente na branch `feature/TASK-226-whatsapp-notification-channel-rework`
(api). `mvn -Dtest="com.brainbyte.easy_maintenance.infrastructure.notification.**" test` → 70/70
passando. Falta abrir PR contra `staging`.
