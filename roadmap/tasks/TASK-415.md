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
- [x] Cada papel vê só o que pode fazer (teste por papel)
- [x] Atalho numérico corresponde à linha exibida para aquele papel
- [x] "Nova empresa" só aparece dentro de "Trocar condomínio" e só para ADMIN
- [x] Limites do WhatsApp respeitados (10 linhas, títulos)

## Dependências
[TASK-414](TASK-414.md).

## Riscos
Lista do WhatsApp tem limites rígidos: menu com mais de 10 linhas quebra o envio.

## Implementação (10/11/2026)
Mesma branch da TASK-414 (depende dela), commit `efce4ee` · PR [api#191](https://github.com/douglasjava/easy-maintenance-api/pull/191).
- `AssistantMenu`: lista gerada pela política, com atalhos novos para histórico (pergunta o item e espera, sem IA),
  receita ou despesa e conformidade.
- O número é a linha que a pessoa vê. Esperando o valor do financeiro, um número continua sendo valor.
- D17: com mais de um condomínio, "Nova empresa" fica no fim da lista de "Trocar de condomínio", só para o titular.
  Com um condomínio só, aparece como linha própria para o titular. **Ajuste em relação ao critério:** sem isso, o
  titular com um condomínio não teria onde achar a opção.
- Testes: `AssistantMenuTest`, `IntentStepTest`, `AwaitingInputHandlerTest`, `AssistantOrganizationSelectorTest`.

## Status
🔵 Em Validação — [api#191](https://github.com/douglasjava/easy-maintenance-api/pull/191) → `staging` (junto com a TASK-414).
