# EPIC-042 — Matriz de papéis no assistente (menus, personas e permissões)

## Status
⬜ Backlog — criado em 10/11/2026.

## Objetivo
Fazer o bot respeitar o papel de cada pessoa e abrir o WhatsApp para quem não tem login (Morador, Zelador, Conselheiro e Fornecedor), com identidade segura e a "prova de manutenção" enviada por quem executou.

## Descrição
Spec: [`2026-11-06-assistant-role-matrix-design.md`](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md) (D1 a D22, revisada em 10/11/2026 com a Parte B do
Tiago). Decisão adicional de 10/11/2026: o fornecedor é uma **conta global** que atende N condomínios (substitui a D20).
Ordem: política (414) → menu (415) e TECH (416) → identidade (417) → convite (418) e morador/desconhecido (419)
→ personas (420, 421, 425, 426) com fornecedor (422, 423, 427) e execução (424) → avisos (428) e limite de IA (429) → QA (430).

## Tasks
| ID | Título | Tipo | Prioridade | Depende de |
|---|---|---|---|---|
| [TASK-414](../tasks/TASK-414.md) | Política única de permissões | BACKEND | 🟠 | — |
| [TASK-415](../tasks/TASK-415.md) | Menu por papel (lista do WhatsApp) | BACKEND | 🟠 | 414 |
| [TASK-416](../tasks/TASK-416.md) | Remover o TECH | FULL_STACK | 🟡 | 414 |
| [TASK-417](../tasks/TASK-417.md) | Identidade por persona | BACKEND | 🔴 | 414 |
| [TASK-418](../tasks/TASK-418.md) | Convite por código + termo + revogação | FULL_STACK | 🔴 | 417 |
| [TASK-419](../tasks/TASK-419.md) | Morador aprovado vira persona + número desconhecido | BACKEND | 🟠 | 417 |
| [TASK-420](../tasks/TASK-420.md) | Persona Morador | BACKEND | 🟠 | 419, 429 |
| [TASK-421](../tasks/TASK-421.md) | Persona Conselheiro | BACKEND | 🟡 | 418 |
| [TASK-422](../tasks/TASK-422.md) | Fornecedor: conta global + contatos | FULL_STACK | 🟠 | 413, 417 |
| [TASK-423](../tasks/TASK-423.md) | Manutenção ↔ fornecedor responsável | FULL_STACK | 🟠 | — |
| [TASK-424](../tasks/TASK-424.md) | Execução enviada (📝) validada pelo síndico | FULL_STACK | 🔴 | 417 |
| [TASK-425](../tasks/TASK-425.md) | Persona Zelador | BACKEND | 🟠 | 418, 424 |
| [TASK-426](../tasks/TASK-426.md) | Persona Fornecedor no bot | BACKEND | 🟠 | 422, 423, 424, 346 |
| [TASK-427](../tasks/TASK-427.md) | Portal do fornecedor: Meus serviços | FULL_STACK | 🟡 | 413, 422, 423 |
| [TASK-428](../tasks/TASK-428.md) | Avisos do prédio | FULL_STACK | 🟡 | 417, 419 |
| [TASK-429](../tasks/TASK-429.md) | Limite de IA por persona | BACKEND | 🟠 | 417 |
| [TASK-430](../tasks/TASK-430.md) | QA do EPIC-042 | QA | 🟠 | todas |

## Critério de Conclusão do Épico
- Toda linha da matriz coberta por teste automatizado (positivo e negativo).
- Cada persona ativada só por convite ou aprovação, com aceite do termo registrado.
- QA manual aprovado.

## Fora de Escopo
- Papel por organização (D6).
- Reserva de área comum.
- SUBSINDICO, ADMINISTRADORA e CONSTRUTORA como personas.
- `GET /me/capabilities` no web.

## Riscos
- Regressão na identidade derruba o bot inteiro (TASK-417 atrás de flag).
- Custo de WhatsApp (avisos) e de IA (morador).
- Vazamento entre personas e entre condomínios do mesmo fornecedor.
