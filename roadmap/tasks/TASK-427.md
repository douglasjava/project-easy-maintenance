# TASK-427 — Portal do fornecedor: "Meus serviços" por condomínio

## Tipo
FULL_STACK

## Categoria
Fornecedores / Portal

## Prioridade
🟡 Médio.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Decisão de 10/11/2026: o portal de serviços é **grátis** para todo fornecedor vinculado (alimenta a prova de
manutenção, EPIC-035); o marketplace pago continua sendo a vitrine para conseguir clientes novos.

## Escopo
- Aba "Meus serviços" no portal: por condomínio, manutenções em que é o responsável, próximos serviços e
  execuções enviadas com status.
- Depois de desligado de um condomínio, continua vendo só as execuções que **ele mesmo** registrou (data e serviço).
- Estados de loading, vazio e erro; mobile.

## Critérios de Aceite
- [x] Fornecedor vê os condomínios vinculados e nenhum outro
- [x] Desligado: só as próprias execuções (data e serviço), sem dados novos
- [x] Acesso só pelo link seguro da TASK-413

## Dependências
[TASK-413](TASK-413.md), [TASK-422](TASK-422.md), [TASK-423](TASK-423.md).

## Riscos
Dado do condomínio exposto a terceiro: só o que está ligado ao fornecedor.

## Implementação (10/11/2026)
[api#204](https://github.com/douglasjava/easy-maintenance-api/pull/204) e [web#144](https://github.com/douglasjava/easy-maintenance-web/pull/144), mergeadas em `staging`.
- `GET /public/suppliers/manage/{token}/services` (link válido): por condomínio vinculado, os itens com execução dele (última e próximo vencimento) e as execuções enviadas com o status e o motivo da recusa. Dos desvinculados, só as próprias execuções (data e serviço).
- Web: aba "Meus serviços" no portal (estados de carregando, vazio e erro; mobile).
- `mvn test` 1961, 0 falhas; `tsc` limpo.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas.
