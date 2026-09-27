# TASK-306 — Registro rápido com confirmação

## Tipo
FULL_STACK

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 2**

## Depende de
TASK-302, TASK-303, TASK-304

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-306-<descricao-curta>`.

**Escopo**
- Identificar o item pelo tipo (+ identificação/local); vários candidatos → lista; nenhum →
  proposta de item novo pelo catálogo curado (sem inventar norma, regra da TASK-212).
- Campos assumidos (data = hoje, tipo = Preventiva) aparecem no resumo.
- Ação pendente em `assistant_conversations` com expiração de 30 min; botões Confirmar/Corrigir/
  Cancelar; "corrigir" reinterpreta só os campos citados.
- Fotos/PDF recebidos durante a ação pendente → anexo (foto/laudo) via `MaintenanceAttachmentService`
  **após** confirmar (método novo que aceita bytes, sem `MultipartFile`).
- Gravação via `MaintenanceService.register` (regras existentes valem) com `source = WHATSAPP` +
  `audit_logs`.

**Critérios de aceite**
- [x] Nada é gravado sem Confirmar (teste `AssistantRegistrationServiceTest`).
- [x] Expiração apaga a foto temporária: não existe foto temporária. Só o id de mídia da Meta fica no rascunho, e o download acontece após Confirmar.
- [x] Data duplicada, somente leitura e papel sem permissão retornam as mensagens do próprio serviço (`checkWrite` no início e no commit; exceção de domínio → `REGISTER_FAILED` e o rascunho é mantido).
- [x] Item novo e manutenção são criados juntos e de forma atômica (`TransactionTemplate` único).
- [~] Detalhe da manutenção no web mostra a origem (selo já existente) e a foto. Validar no piloto em produção.

**Prompt**: `execute a TASK-306 (EPIC-031): registro de manutenção pelo WhatsApp com resumo,
confirmação por botões, anexos após confirmar e origem auditada.`

## Notas de execução (27/09/2026)
- Branch `feature/TASK-306-assistente-registro-manutencao` · PR [api#130](https://github.com/douglasjava/easy-maintenance-api/pull/130) → staging.
- Pendência de 30 min em `assistant_conversations` (`RegistrationStep` @Order 48, antes da IA). Correções parciais por texto.
- **Decisão:** item novo só com tipo do catálogo **regulatório** (periodicidade da norma). Para os demais, lista de itens + link `/items/new`.
- **Decisão:** anexos são baixados da Meta só após Confirmar e passam pelo mesmo `MaintenanceAttachmentService` (`InMemoryMultipartFile`), sem método novo.
- `AssistantWriteGuardCoverageTest`: toda escrita do assistente exige `guard.checkWrite`.
- Suíte: 1278/1278. Fluxo por texto livre e upload real só são testáveis em produção (IA/S3); o roteiro está na PR.

## Status
In Validation
