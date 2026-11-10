# TASK-434 — Samu: registro com modelo de exemplo, itens sugeridos e anexo depois do registro

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Registro

## Prioridade
🟡 Médio.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Fluxo A, passos 1 e 5, da [Parte B](../QA/registro-usabilidade-producao.md). Os passos 2 a 4 (item com busca aproximada, data nunca presumida,
cartão com a próxima data e Corrigir) já foram entregues na Onda 1 (TASK-400 a 407).

## Escopo
- Ao pedir o registro: modelo com os dados e um exemplo, mais lista curta de itens sugeridos (vencidos e mais usados).
- Depois de confirmar: "Quer anexar foto ou nota?"; fotos nos 10 minutos seguintes vão para esse registro, com
  confirmação. "posso anexar uma imagem?" → "Pode! Mande agora".

## Critérios de Aceite
- [ ] Foto enviada até 10 min depois do registro é anexada a ele, com confirmação
- [ ] Foto fora da janela cai no anexo sem contexto ([TASK-438](TASK-438.md))
- [ ] Itens sugeridos tocáveis levam ao registro com o item preenchido

## Dependências
Relaciona com a [TASK-339](TASK-339.md) (evidência obrigatória para itens críticos).

## Riscos
Anexar no registro errado: a janela de 10 min vale só para o último registro da persona.

## Implementação (10/11/2026)
[api#210](https://github.com/douglasjava/easy-maintenance-api/pull/210), mergeada em `staging`.
- "Registrar" responde com o modelo e um exemplo, mais até 5 itens sugeridos (vencidos, depois os da semana). Tocar num item espera a descrição com o item já escolhido.
- A confirmação oferece anexo. Foto ou documento até 10 min depois é anexado ao último registro da persona, com confirmação. "posso anexar uma imagem?" recebe "Pode! Mande agora".
- Fora da janela, a foto segue o fluxo de antes; o anexo sem contexto é da TASK-438.
- "Mais usados" ficou de fora da sugestão; ela usa só o vencimento.
- `mvn test` 1985, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas; o critério da foto fora da janela depende da TASK-438.
