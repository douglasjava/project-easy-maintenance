# TASK-020 — Schema formal para features JSON em billing_plans

## Tipo
Débito técnico / Segurança

## Categoria
Backend / Billing / Banco de Dados

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-004 — Banco de Dados e Persistência

## Descrição
A coluna `features` na tabela `billing_plans` armazena dados como JSON (maxUsers, maxItems, aiEnabled, aiMonthlyCredits, emailMonthlyLimit, reportsEnabled, supportLevel). Sem schema formal, uma mudança na estrutura desse JSON (renomear campo, adicionar campo novo) pode quebrar a desserialização silenciosamente ou retornar valores `null` sem aviso.

## Problema
Exemplos de cenários problemáticos:
- Migration renomeia `maxItems` para `itemsLimit` → código que usa `maxItems` passa a retornar null e não bloqueia criação de itens
- Novo plano criado sem campo `aiEnabled` → feature gate não funciona para esse plano
- Mudança no tipo de dado de um campo → ClassCastException em runtime

## Impacto
Feature gates podem falhar silenciosamente, permitindo acesso a recursos de plano superior sem pagamento.

## Dependências
- Levantamento de todos os locais no código que deserializam o JSON de features

## Critérios de Aceite
- [x] Classe Java `BillingPlanFeatures` (DTO) tem todos os campos mapeados com `@JsonProperty` explícito
- [x] Campos têm valores default para backward compatibility (ex: `aiEnabled` default `false`)
- [x] Teste unitário que valida desserialização do JSON de cada plano existente
- [x] Documentação do schema dentro do código (JavaDoc ou comentário na classe)

## Subtasks
- [x] Mapear todos os campos do JSON de features atualmente em uso
- [x] Criar/atualizar classe `BillingPlanFeatures` com todos os campos e defaults
- [x] Adicionar validação ao deserializar features de plano
- [x] Escrever testes unitários de desserialização
- [x] Documentar processo de adicionar nova feature a um plano

## Esforço
Médio (4-8h)

## Risco de não fazer
Feature gate silenciosamente quebrado por mudança estrutural no JSON — cliente acessa recurso sem pagar.

## Status
Concluído
