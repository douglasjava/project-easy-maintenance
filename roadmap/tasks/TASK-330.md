# TASK-330 — Registrar receita/despesa pelo WhatsApp + refactor do pipeline de rascunhos pendentes

## Tipo
BACKEND (assistente, EPIC-031 Onda 2)

## Prioridade
🟢 Melhoria de produto — pedido do Douglas em 05/10/2026, depois de validar o EPIC-032
(controle financeiro simples) em produção.

## QA obrigatório
Sim — toca um fluxo de produção já validado (registro de manutenção pelo WhatsApp, TASK-306) e
adiciona uma gravação nova (lançamento financeiro) a um canal que já atende clientes reais.

## Contexto
Depois de aprovar o EPIC-032 (controle financeiro: `/financeiro` + Prestação de Contas), o Douglas
perguntou se o assistente de WhatsApp (EPIC-031) também poderia registrar receitas/despesas, do
mesmo jeito que já registra manutenção (TASK-306).

Investigação confirmou duas coisas:
1. **Separação de responsabilidade está sólida**: o assistente nunca duplica regra de negócio —
   `AssistantRegistrationService`/`AssistantNewOrganizationService` chamam direto os services reais
   (`MaintenanceService`, `OrganizationsService`...) dentro de `AssistantUserContext.runAs(...)`,
   mesmo caminho que o controller REST usa.
2. **Falta uma abstração pro "rascunho pendente"**: hoje `RegistrationStep` (manutenção) e
   `NewOrganizationStep` (empresa nova) são duas classes de pipeline quase idênticas — cada uma com
   sua própria lógica de "tem rascunho? expirou? descarta ou continua". Adicionar lançamento
   financeiro como está hoje seria uma TERCEIRA cópia desse bloco.

Decisão: fazer o refactor (`PendingActionHandler` + `PendingActionStep` genérico) ANTES de construir
a capacidade nova, pra ela nascer já no formato certo e não aumentar a dívida.

## Plano de implementação
[docs/superpowers/plans/2026-10-05-whatsapp-financial-entry.md](../../docs/superpowers/plans/2026-10-05-whatsapp-financial-entry.md)
— 7 tasks, TDD em cada uma. Resumo:
1-3. Refactor: `PendingActionHandler` (interface nova) + `AssistantRegistrationService` e
   `AssistantNewOrganizationService` implementam ela + `PendingActionStep` único substitui
   `RegistrationStep`/`NewOrganizationStep`.
4-6. Capacidade nova: `AssistantIntent.REGISTRAR_LANCAMENTO_FINANCEIRO` + prompt da IA + parser de
   tipo (receita/despesa por palavra-chave) + `AssistantFinancialEntryService` (rascunho →
   escolher tipo → escolher categoria por botão → confirmar → chama `FinancialEntryService.create`
   já existente, sem mudança no módulo `finance`).
7. Liga no `IntentStep`.

## Reaproveitamento (sem mudança)
- `FinancialEntryService.create` (EPIC-032) — zero mudança, só é chamado.
- `AssistantAccessGuard.checkWrite`, `AssistantUserContext.runAs`, `AuditService.log`,
  `AssistantConversation.pending_action_json`/`pending_expires_at` (schema já existe, nenhuma
  coluna nova).
- `RegistrationParser.parseCostCents`/`.parseDate` (genéricos, não específicos de manutenção).

## Critérios de aceite
- [ ] `RegistrationStep`/`NewOrganizationStep` removidos; `PendingActionStep` único cobre os dois
  fluxos existentes sem mudar o comportamento observável deles (mesmos testes, adaptados).
- [ ] Usuário consegue dizer "gastei 200 com a conta de luz" (ou variação) e o assistente
  pergunta categoria (se precisar), mostra resumo pra confirmar, e só grava no "Confirmar".
- [ ] Permissão: só ADMIN/SYNDIC conseguem confirmar (mesma regra do `/financeiro`); TECH recebe
  mensagem de erro clara, sem crash.
- [ ] Troca de organização com rascunho pendente descarta o rascunho (mesma trava do registro de
  manutenção).
- [ ] Suíte completa do pacote `assistant` verde antes e depois do refactor.

## Status
Plano aprovado (05/10/2026) — pronto para execução.
