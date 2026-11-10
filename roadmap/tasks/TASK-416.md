# TASK-416 — Remover o papel TECH (migration defensiva + enum + telas do web)

## Tipo
FULL_STACK

## Categoria
Usuários e papéis

## Prioridade
🟡 Médio — limpeza; nenhum usuário usa TECH (D2).

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D2 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md): o TECH sai do sistema. O zelador ocupa esse espaço como persona (D4). Item 7 da
"Proposta técnica".

## Escopo
- Migration defensiva: `UPDATE users SET role='READER' WHERE role='TECH'` antes de o valor sair do enum.
- Enum `Role` sem TECH; checagens que citam TECH ajustadas.
- Web: `users/new`, `users/[id]/edit`, `private/users/new`, badge em `users/page.tsx` e `lib/enums/labels.ts`.

## Critérios de Aceite
- [ ] Migration aplicada sem erro mesmo com usuário TECH residual
- [ ] Nenhuma tela oferece TECH
- [ ] `mvn test` e `tsc`/`build` sem regressão

## Dependências
[TASK-414](TASK-414.md) (a política não pode mais citar TECH).

## Riscos
Usuário com valor desconhecido no enum derruba o carregamento: a migration vem antes do deploy do enum.

## Status
⬜ Backlog
