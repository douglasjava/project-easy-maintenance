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
- [x] Migration aplicada sem erro mesmo com usuário TECH residual
- [x] Nenhuma tela oferece TECH
- [x] `mvn test` e `tsc`/`build` sem regressão

## Dependências
[TASK-414](TASK-414.md) (a política não pode mais citar TECH).

## Riscos
Usuário com valor desconhecido no enum derruba o carregamento: a migration vem antes do deploy do enum.

## Implementação (10/11/2026)
Branch `chore/TASK-416-remove-tech-role` (api e web) · [api#192](https://github.com/douglasjava/easy-maintenance-api/pull/192) e [web#139](https://github.com/douglasjava/easy-maintenance-web/pull/139), mergeadas em `staging`.
- `V138`: migration defensiva (TECH → READER); `Role` sem TECH; `AssistantRole` sem o mapeamento.
- Web: TECH removido das 3 telas de usuário, do badge e do `roleLabelMap`.
- e2e (repositório raiz): `organization-access.spec.ts` edita o membro para SYNDIC em vez de TECH.
- `mvn test` 1895, 0 falhas (os 5 testes que só cobriam TECH saíram); `tsc` limpo.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas para a promoção para `main`.
