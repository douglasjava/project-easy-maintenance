# TASK-173 — Backend: fornecedores no e-mail de notificação

## Tipo
BACKEND

## Categoria
Notificações / Fornecedores

## Prioridade
🟠 Alto

## Épico
[EPIC-023](../epics/EPIC-023.md) — Fornecedores nas Notificações de Vencimento

## QA obrigatório
Sim — QA manual com dado real (mesma classe de bloqueio de secrets locais já registrada em tasks
anteriores do projeto, se aplicável) + testes automatizados do HTML gerado.

---

## Contexto

Diferente do WhatsApp, o e-mail não depende de aprovação externa (template HSM da Meta) — é HTML
gerado por concatenação de string em Java (`EmailTemplateHelper`), então pode ir pro ar assim que
implementado. Detalhe completo em
`docs/superpowers/specs/2026-08-18-supplier-notifications-design.md`.

## Objetivo

O e-mail de notificação de item/manutenção **vencida** (`OVERDUE` — único evento que dispara
e-mail hoje) passa a incluir um bloco com os fornecedores próximos encontrados, quando houver.

## Escopo

- `BusinessEmailNotificationService.buildPayload()` chama
  `SupplierLookupService.findNearbyByCityState(...)` (TASK-172) usando cidade/estado da
  `Organization` do evento e a categoria do item/manutenção referenciado.
- Sem limite fixo de quantidade — usa quantos a busca retornar (tipicamente 2-3, dado o `limit`
  já praticado no fluxo interativo existente).
- `EmailTemplateHelper.generateNotificationEventHtml` ganha um parâmetro novo (lista de
  fornecedores: nome, telefone, endereço/link do Maps) e um bloco HTML condicional — **só
  renderiza a seção se a lista não estiver vazia**, sem alterar o restante do e-mail.

## Critérios de Aceite

- [ ] E-mail de evento `OVERDUE` inclui bloco de fornecedores quando `SupplierLookupService`
      retorna 1 ou mais resultados
- [ ] E-mail sem fornecedor encontrado renderiza normalmente, sem a seção (sem espaço em branco
      estranho nem erro)
- [ ] Testes cobrindo HTML gerado com 0, 1 e 3 fornecedores
- [ ] `mvn test` sem regressão

## Dependências
TASK-172 (`SupplierLookupService`).

## Riscos
Baixo — canal sem restrição de aprovação externa, mudança aditiva no template HTML já existente.

## Esforço
Baixo

## Status
Pronto para implementar (depende da TASK-172 estar concluída).
