# TASK-415 — Assistente: menu por papel em lista do WhatsApp, gerado pela política

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Menu

## Prioridade
🟠 Alto — resolve WA-11 e WA-21 do Tiago (menu com o que o papel não pode, atalho "4" fixo).

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Item 3 da "Proposta técnica" da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md) e seção 5.3 da [Parte B](../QA/registro-usabilidade-producao.md). O menu passa a ser
exatamente o que a política (TASK-414) permite.

## Escopo
- Mensagem de lista do WhatsApp (até 10 linhas, em seções, título até 24 caracteres) gerada da política.
- Atalhos numéricos derivados do menu exibido, não fixos.
- "Nova empresa" sai do menu e fica dentro de "Trocar condomínio" (D17).
- "Trocar condomínio" só aparece para quem tem mais de 1 organização.

## Critérios de Aceite
- [ ] Cada papel vê só o que pode fazer (teste por papel)
- [ ] Atalho numérico corresponde à linha exibida para aquele papel
- [ ] "Nova empresa" só aparece dentro de "Trocar condomínio" e só para ADMIN
- [ ] Limites do WhatsApp respeitados (10 linhas, títulos)

## Dependências
[TASK-414](TASK-414.md).

## Riscos
Lista do WhatsApp tem limites rígidos: menu com mais de 10 linhas quebra o envio.

## Status
⬜ Backlog
