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
- [ ] Nada é gravado sem Confirmar.
- [ ] Expiração apaga a foto temporária.
- [ ] Data duplicada, somente leitura e papel sem permissão retornam as mensagens do próprio serviço.
- [ ] Item novo e manutenção são criados juntos e de forma atômica.
- [ ] Detalhe da manutenção no web mostra a origem e a foto.

**Prompt**: `execute a TASK-306 (EPIC-031): registro de manutenção pelo WhatsApp com resumo,
confirmação por botões, anexos após confirmar e origem auditada.`

## Status
Backlog
