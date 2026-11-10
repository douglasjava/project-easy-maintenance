# TASK-436 — Samu: cadastro completo de item novo pelo chat

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Itens

## Prioridade
🟡 Médio — WA-22.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Fluxo E da [Parte B](../QA/registro-usabilidade-producao.md). Cadastrar item é de ADMIN/SYNDIC (D16); o zelador sugere pelo fluxo 📝.

## Escopo
- Modelo: tipo (catálogo), local, última manutenção, fornecedor habitual.
- Tipo com norma: informa "Regulatório, anual pela NBR X" e não pergunta a periodicidade; sem norma, pergunta com sugestões.
- Local: sugere os locais já usados no condomínio (até existir o cadastro de Locais).
- Cartão do item antes de criar; item novo nunca é criado em silêncio.

## Critérios de Aceite
- [x] Item criado só depois do cartão confirmado
- [x] Item com norma não pergunta periodicidade
- [x] Zelador vê "sugerir" em vez de "cadastrar"

## Dependências
[TASK-414](TASK-414.md). Foto da etiqueta pela [TASK-347](TASK-347.md)/[TASK-349](TASK-349.md); habitual pela [TASK-346](TASK-346.md).

## Riscos
Grafias diferentes de local enquanto não houver cadastro de Locais.

## Implementação (10/11/2026)
[api#212](https://github.com/douglasjava/easy-maintenance-api/pull/212), mergeada em `staging`.
- `AssistantItemCreateService`: tipo (só do catálogo) → periodicidade (só sem norma) → local (sugere os já usados) → última manutenção → cartão → [Criar item]. Nada é criado antes do cartão.
- Item com norma é criado como REGULATORY com o `normId`, sem perguntar periodicidade.
- O zelador recebe "sugerir" em vez de "cadastrar"; assinatura em somente leitura é barrada por `checkWrite`.
- **Fora do escopo:** "Cadastrar item" não entrou no menu, porque o do ADMIN já tem as 10 linhas máximas; o acesso é pelo texto. Decisão pendente de Douglas sobre qual linha sai. Fornecedor habitual depende da TASK-346.
- `mvn test` 1999, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas, mais a decisão sobre a linha do menu.
