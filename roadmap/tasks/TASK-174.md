# TASK-174 — Backend: fornecedores no WhatsApp — template v3 (depende de aprovação Meta)

## Tipo
BACKEND

## Categoria
Notificações / Fornecedores

## Prioridade
🟡 Médio

## Épico
[EPIC-023](../epics/EPIC-023.md) — Fornecedores nas Notificações de Vencimento

## QA obrigatório
Sim, mas com uma pendência estrutural: o template `vencimento_manutencao_v3` precisa estar
aprovado pela Meta pra QA de envio real acontecer — sem isso, só dá pra validar o payload/lógica
localmente (mock), igual ao caminho que o `v2` percorreu no EPIC-015.

---

## Contexto

O template atual (`vencimento_manutencao_v2`) já está aprovado pela Meta e em produção — mas é um
template HSM com exatamente 5 variáveis de corpo fixas, e templates aprovados **não podem ser
editados**. Pra incluir fornecedores no corpo da mensagem, é preciso um template **novo**, que
passa pelo mesmo processo (e risco de demora) de aprovação que já atrasou o `v2` antes dele entrar
no ar. Detalhe completo em `docs/superpowers/specs/2026-08-18-supplier-notifications-design.md`.

## Objetivo

WhatsApp de notificação (`NEAR_DUE` dia 1 e `OVERDUE`) passa a incluir 2 fornecedores fixos
(nome + telefone) no corpo da mensagem, via novo template `vencimento_manutencao_v3`.

## Escopo

### 1. Submissão do template à Meta (ação do Douglas, fora do código)
Novo template HSM `vencimento_manutencao_v3`, 9 variáveis de corpo: as 5 atuais
(`recipientName, itemName, companyName, dueDate` + o que mais o `v2` já usa) +
`supplier1Name, supplier1Phone, supplier2Name, supplier2Phone`. Precisa ser submetido e aprovado
antes do rollout em produção — **isso não é código, é uma ação externa do Douglas** no painel da
Meta, com o mesmo risco de demora documentado no EPIC-015 pro `v2`.

### 2. Código (pode ser implementado e testado antes da aprovação)
- `BusinessWhatsAppNotificationService.buildPayload()` chama
  `SupplierLookupService.findNearbyByCityState(...)` (TASK-172) usando cidade/estado da
  `Organization` e a categoria do item/manutenção referenciado.
- Se a busca retornar **menos de 2 fornecedores**, o envio por WhatsApp desse evento específico é
  **pulado** — mesmo caminho de fallback já existente hoje pra outras falhas de envio (decisão de
  escopo explícita, não é bug: template exige as 2 vagas preenchidas, Meta não aceita variável de
  corpo vazia).
- Se retornar 2 ou mais, monta o payload com 9 variáveis (usa só os 2 primeiros resultados).
- `infrastructure/notification/provider/WhatsAppNotificationProvider.java`
  (`extractBodyParams`/`extractButtonParam`) precisa ser atualizado pra extrair as 4 variáveis
  novas na ordem correta do template aprovado.
- Config `whatsapp.default-template-name` **só migra de `v2` pra `v3` depois do template estar
  aprovado pela Meta** — até lá, o código do `v3` fica pronto/testado mas inativo em produção
  (mesma config continua no `v2`, sem fornecedor).

## Critérios de Aceite

- [ ] Template `vencimento_manutencao_v3` submetido à Meta (Douglas)
- [ ] `buildPayload()` monta 9 variáveis corretamente quando `SupplierLookupService` retorna 2+
      fornecedores
- [ ] Envio pulado (mesmo fallback já existente) quando retorna menos de 2
- [ ] `WhatsAppNotificationProvider` extrai as 4 variáveis novas na ordem certa
- [ ] Testes cobrindo os cenários de 0/1/2+ fornecedores encontrados
- [ ] Config só migra pra `v3` depois da aprovação confirmada — documentar isso claramente no PR
- [ ] `mvn test` sem regressão

## Dependências
TASK-172 (`SupplierLookupService`). Aprovação do template pela Meta é pré-requisito pro rollout em
produção, mas não bloqueia a implementação/testes do código em si.

## Riscos
- **Aprovação da Meta** é dependência externa fora do controle da implementação — mesmo risco que
  já atrasou o `v2`. Esta task pode ficar "Em Validação" (código pronto) por um tempo até a
  aprovação sair e a config poder migrar pra `v3` de fato.
- Se o texto exato aprovado pela Meta divergir do que foi planejado aqui (Meta pode pedir ajuste de
  redação/formatação durante a revisão), a ordem/quantidade de variáveis pode precisar de ajuste
  fino depois da aprovação — normal nesse tipo de processo, mesmo padrão do `v2`.

## Esforço
Médio (mais a incerteza de tempo da aprovação externa, fora do esforço de código em si)

## Status
Pronto para implementar (código depende da TASK-172; rollout em produção depende da aprovação
externa da Meta).
