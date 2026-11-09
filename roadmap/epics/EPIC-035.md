# EPIC-035 — Prestador no fluxo (evidência enviada pelo fornecedor)

## Status
📝 Backlog — criado em 15/10/2026. Só iniciar depois de piloto da Fase 1 do EPIC-033.

Origem: avaliação de produto feita por um dos sócios (10 e 11/10/2026: PRD de reposicionamento, diretrizes do agente de onboarding via WhatsApp e comparação com a Facilitat), consolidada com leitura do código em 14/10/2026 (documento interno, fora do repositório).

## Objetivo
Boa parte das falhas nasce na execução do prestador, e a conclusão hoje depende do síndico digitar
depois. O fornecedor passa a enviar foto, nota fiscal e laudo **por um link com token, sem login**
(mesmo padrão do QR de chamados do EPIC-027) e recebe um **comprovante de execução** — o ganho dele
para participar.

## Achados do código
- Fluxo público sem login com upload no S3 já existe (EPIC-027) — reaproveitar o padrão.
- Depende do vínculo item ↔ fornecedor (TASK-346).

## Fora do escopo
- Fornecedor como papel autenticado no WhatsApp (avaliar depois; envolve identidade por telefone).
- Pagamento ao fornecedor.

## Decisões em aberto
- [ ] Mensagem ao fornecedor sai do número do produto (custo de template + consentimento) ou o síndico encaminha o link?

## Tasks

| ID | Título | Prioridade | Fase | Tipo |
|----|--------|------------|------|------|
| [TASK-352](../tasks/TASK-352.md) | Link público com token para o fornecedor enviar a evidência | 🟠 Alto | Fase 3 | FULL_STACK |
| [TASK-353](../tasks/TASK-353.md) | Comprovante de execução para o fornecedor | 🟡 Médio | Fase 3 | BACKEND |
| [TASK-354](../tasks/TASK-354.md) | Pedido de evidência ao fornecedor (WhatsApp/e-mail) | 🟡 Médio | Fase 3 | BACKEND |
