# TASK-275 — FULL_STACK: Categorias estruturadas + recobrança + link permanente + layout

## Tipo
FULL_STACK

## Categoria
Fornecedores / Marketplace

## Prioridade
🔴 Alto — bloqueava o fluxo real de monetização (C4 do QA) e mudava decisão de produto (categoria
única → múltipla)

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — [TASK-QA-MAN-022](../QA/tasks/TASK-QA-MAN-022.md) atualizado com os cenários novos (C2/C4/C6
revisados).

---

## Contexto

Depois de corrigir os 3 bugs de acesso público (TASK-272/273/274), Douglas testou o fluxo real e
levantou 4 melhorias de produto + 2 dúvidas técnicas (brainstorm formal via `superpowers:brainstorming`,
13/09/2026, sem spec file — mudança bounded dentro do módulo já existente):

1. Telefone não devia ser opcional no cadastro do síndico.
2. Categoria devia ser estruturada (não texto livre), permitir mais de uma por fornecedor, e ter
   serviços opcionais dentro de cada categoria.
3. Layout da página pública sem nenhuma referência visual ao produto.
4. Todos os campos deviam ser obrigatórios em `/fornecedores/cadastro`, incluindo categoria.

E 2 dúvidas que viraram bugs reais encontrados durante o brainstorm:
1. Re-tentar o auto-cadastro com o mesmo documento retornava `409 Conflict` (constraint de
   `supplier_subscriptions.supplier_id` violada — o código sempre tentava inserir uma linha nova).
   Decisão: reaproveitar a cobrança pendente em vez de gerar uma nova.
2. Depois de pagar, a tela ficava parada sem feedback nem forma de acompanhar a conta. Decisão:
   gerar o link mágico já no registro (não só na ativação) e mostrá-lo junto com o link de
   pagamento.

## Escopo

### Categorias estruturadas (a peça maior)
Taxonomia própria de fornecedor (`supplier_categories`/`supplier_services`, N:N via
`supplier_category_links`/`supplier_service_links`) — **não** reaproveita `item_types`
(taxonomia de manutenção, conceito diferente, decisão tomada explicitamente com o Douglas). Seed
de 13 categorias / 42 serviços, validado com o Douglas antes de implementar (inclui "Segurança" e
"Marcenaria e Serralheria", adicionadas por ele na revisão). Endpoint público `GET
/public/suppliers/categories`. Componente frontend `CategoryServicePicker` compartilhado entre as
3 telas de fornecedor.

### Telefone obrigatório
`RegisterSupplierRequest.phone` ganha `@NotBlank` (autenticado — já era obrigatório no público).

### Recobrança
`SupplierRegistrationService.register()` reaproveita a `SupplierSubscription` pendente (se ainda
não venceu) — sem chamada nova ao Asaas nem `INSERT` duplicado. Cobrança vencida gera uma nova,
mas **atualiza a mesma linha** (não insere outra). `SupplierSubscription.externalCustomerId`
também é reaproveitado (não recria o cliente no Asaas a cada tentativa).

### Link permanente + feedback pós-pagamento
`SupplierAccessTokenService` (novo, compartilhado) gera o token de acesso já no registro, não só
na ativação via webhook. `/fornecedores/cadastro` mostra o link de pagamento **e** o link de
gestão logo após o cadastro. `/fornecedores/gerenciar/[token]` mostra um banner com o link de
pagamento pendente quando a assinatura ainda não está `ACTIVE`.

### Layout
`/fornecedores/cadastro` e `/fornecedores/gerenciar/[token]` ganham cabeçalho com o logo real do
produto (mesmo arquivo usado em `/chamados/[orgCode]`) e cards com mais acabamento visual.

## Critérios de Aceite

- [x] Fornecedor pode selecionar mais de uma categoria, com serviços opcionais por categoria
- [x] Categoria é obrigatória (mínimo 1) no cadastro público; opcional no cadastro do síndico
- [x] Telefone obrigatório no cadastro do síndico
- [x] Re-tentar auto-cadastro com o mesmo documento não retorna mais 409; reaproveita cobrança
      pendente não vencida, sem chamar o Asaas de novo
- [x] Cobrança vencida gera uma nova, atualizando a mesma `SupplierSubscription` (não duplica)
- [x] Resposta do auto-cadastro inclui o token de gestão; tela mostra o link permanente
- [x] Tela de gestão via link mágico mostra o pagamento pendente quando aplicável
- [x] `mvn test` e `npm run build`/`eslint`/`npm test` sem regressão

## Dependências
TASK-260 a TASK-274 (todo o trabalho anterior do épico).

## Riscos
Médio — remove a coluna `category` de `suppliers` (sem dado em produção, marketplace ainda não
lançado) e muda o contrato de 4 endpoints já implementados nesta mesma sessão (nenhum em produção
ainda). Mitigado: suíte completa (backend + frontend) sem regressão, migration validada contra o
MySQL real.

## Esforço
Grande

## Implementação

### Arquivos criados (backend)
`SupplierCategory`/`SupplierService`/`SupplierCategoryLink`/`SupplierServiceLink` (entidades) +
repositórios, `SupplierCategoryAssembler` (monta/grava tags, compartilhado), `SupplierTaxonomyService`
(lista a taxonomia aninhada), `SupplierAccessTokenService` (token compartilhado entre registro e
ativação), `CategoryTag`/`ServiceTag`/`SupplierCategoryTaxonomyResponse` (DTOs), migration `V113`.

### Arquivos modificados (backend)
`Supplier` (remove `category`), `RegisterSupplierRequest`/`SelfRegisterSupplierRequest` (categoryIds/
serviceIds, phone obrigatório), `SupplierRegistryResponse`/`SupplierManageResponse` (categories/
services em lista), `SelfRegisterSupplierResponse` (manageToken), `UpdateSupplierProfileRequest`,
`SupplierRepository.findByRegionVisibleTo` (categoryId em vez de string), `SupplierRegistryService`,
`SupplierRegistrationService` (recobrança), `SupplierSelfManageService`, `SupplierPaymentActivationService`
(usa o token service compartilhado), `SupplierBillingService` (persiste `paymentLink`),
`SupplierSubscription` (campo `paymentLink`), `SupplierPublicController`/`SupplierRegistryController`.

### Arquivos criados/modificados (frontend)
`CategoryServicePicker.tsx` (novo, compartilhado), `publicSupplierApi.ts` (taxonomia + tipos novos),
`/fornecedores/page.tsx`, `/fornecedores/cadastro/page.tsx`, `/fornecedores/gerenciar/[token]/page.tsx`.

### Verificação
Backend: `mvn test` (suíte completa) → PASS, sem regressão. Frontend: `npm run build` limpo,
`eslint` sem erros novos, `npm test` 107/110 (3 falhas pré-existentes).

## Status
🟢 Implementado e testado (mocks/build). Validação end-to-end fica pro Douglas repetir C2/C4/C6 do
QA manual — [TASK-QA-MAN-022](../QA/tasks/TASK-QA-MAN-022.md) atualizado com os cenários revisados.
