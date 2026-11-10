# TASK-418 — Convite por código para Zelador e Conselheiro + aceite do termo + revogação

## Tipo
FULL_STACK

## Categoria
Assistente WhatsApp (Samu) / Identidade

## Prioridade
🔴 Crítico — sem isto nenhuma persona sem login entra com segurança (D19).

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D19 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md) e seção "Ativação e revogação das personas sem login". O WhatsApp prova o número; o convite
prova que é a pessoa certa (um número digitado errado não ativa ninguém).

## Escopo
- `/pessoas`: botão **[Convidar para o WhatsApp]** no Zelador e no Conselheiro → link `wa.me` com código (uso único,
  7 dias, um ativo por pessoa; gerar outro invalida o anterior). Status do convite visível na tela.
- Bot: mensagem "ATIVAR <código>" → confere código + telefone do cadastro → pede aceite do termo (versão registrada)
  → persona ativa.
- Limite de tentativas erradas por número (anti força bruta).
- Revogação automática: telefone do cadastro mudou, pessoa removida, mandato encerrado, "SAIR".
- Auditoria de ativação e revogação.

## Critérios de Aceite
- [x] Código certo + telefone certo ativa; código certo + outro telefone não ativa
- [x] Código expirado, usado ou substituído é recusado
- [x] Trocar o telefone no cadastro revoga a persona
- [x] Aceite do termo registrado com versão e data
- [x] Nenhum custo de template (a conversa parte da pessoa)

## Dependências
[TASK-417](TASK-417.md).

## Riscos
LGPD: o aceite precisa ser explícito e guardado; não ativar antes dele.

## Implementação (10/11/2026)
[api#194](https://github.com/douglasjava/easy-maintenance-api/pull/194) e [web#140](https://github.com/douglasjava/easy-maintenance-web/pull/140), mergeadas em `staging`.
- API: `POST` e `GET /organizations/condo-people/{id}/assistant-invite`. O código tem 5 caracteres, vale 7 dias, é de uso único e só há um por pessoa. Só vale para pessoa ativa, zelador ou conselheiro, sem login e com celular.
- Bot: "ATIVAR <código>" confere código + telefone do cadastro e pede o termo com [Aceito] e [Não aceito]. Aceitar ativa a persona com a versão do termo registrada.
- Anti força bruta: código certo de outro número 5 vezes revoga o convite; 5 códigos inválidos por dia silenciam o número.
- Auditoria da criação, da ativação e da revogação.
- Revogação automática: a resolução (TASK-417) ignora a persona se o telefone do cadastro mudou, se a pessoa saiu ou se o mandato acabou. O "SAIR" revoga o vínculo.
- Web: ação "WhatsApp" em `/pessoas` com o modal do convite (copiar ou enviar pelo WhatsApp).
- `mvn test` 1917, 0 falhas; `tsc` e `eslint` limpos.

## Status
🔵 Em `staging` (10/11/2026) — atrás de `ASSISTANT_PERSONAS_ENABLED`; aguarda a validação de Douglas.
