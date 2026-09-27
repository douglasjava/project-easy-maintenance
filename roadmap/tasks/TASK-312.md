# TASK-312 — QA manual + automação do assistente (fluxos e segurança)

## Tipo
QA

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 3**

## Depende de
TASK-305, TASK-306

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-312-<descricao-curta>`.

**Escopo**: plano de QA manual (em produção, com o usuário controlado do piloto) + testes
automatizados.
- Fluxos: ativação, consultas, registro com foto, correção, expiração, onboarding, relatórios.
- Segurança: número não verificado, organização alheia, conta em somente leitura, `READER`,
  tentativa de manipular a IA, rajada de mensagens e revogação com "PARAR".

**Critérios de aceite**
- [ ] Todos os cenários de segurança com evidência.
- [ ] Automação dos cenários de segurança na suíte do backend.

**Prompt**: `execute a TASK-312 (EPIC-031): plano de QA manual e testes automatizados de
segurança do assistente.`

## Status
Backlog
