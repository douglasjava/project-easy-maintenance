# TASK-232 — BACKEND: Telefone do fornecedor via Place Details só na busca de notificação

## Tipo
BACKEND

## Categoria
Notificações / Fornecedores

## Prioridade
🟡 Médio

## Épico
[EPIC-023](../epics/EPIC-023.md) — Fornecedores nas Notificações de Vencimento

## QA obrigatório
Sim, já feito — Douglas testou o `v3` ponta a ponta em ambiente real (TASK-172/173/174/229/230
todas validadas) e recebeu a mensagem com 2 fornecedores, mas os dois com "não informado" no
telefone.

---

## Contexto

Achado testando o template `v3` de verdade (script de QA da TASK-174/229): a mensagem chegou certa
(nome, empresa, data, 2 fornecedores), mas **nenhum dos dois fornecedores trouxe telefone** — "não
informado" nos dois.

Causa raiz: telefone só vem da chamada Place Details da API do Google (custo à parte, separado da
busca em si), controlada pelo flag `google.places.details-enabled`. Esse flag está `false` desde
que a busca de fornecedor **interativa** (`SupplierSearchService`, usada na tela de criar
manutenção) foi criada — decisão de custo original, já que aquela busca dispara a cada clique, sem
cache. `SupplierLookupService` (TASK-172, busca de notificação) reaproveitava o mesmo flag sem
querer — herdou a config pensada pra um contexto de custo bem diferente do seu.

## Decisão (Douglas, 07/09/2026)

Ligar telefone **só na busca de notificação**, não na interativa:
- Notificação (`SupplierLookupService`): cache de 7 dias por organização+categoria — custo contido,
  e o telefone é o que dá valor real à sugestão (poder ligar na hora, direto da mensagem).
- Interativa (`SupplierSearchService`, dentro do app): continua sem telefone por ora — mostrar só
  nome já ajuda, sem gerar custo extra por clique.

## Escopo

- `GooglePlacesProperties` ganha `notificationDetailsEnabled` (novo campo, independente do
  `detailsEnabled` existente).
- `SupplierLookupService.buildSuppliers()` passa a checar `notificationDetailsEnabled` em vez de
  `detailsEnabled`. `SupplierSearchService` não muda — continua no `detailsEnabled` original.
- `application.properties`: `google.places.notification-details-enabled=true`,
  `google.places.details-enabled` continua `false`.

## Critérios de Aceite

- [x] `SupplierLookupService` enriquece com telefone quando `notificationDetailsEnabled=true`
- [x] `SupplierSearchService` (interativa) inalterada — continua sem telefone por padrão
- [x] Testes cobrindo o enriquecimento (Place Details estubado, telefone confirmado no `SupplierDTO`)
- [x] `mvn test` sem regressão (912/912)

## Dependências
TASK-172/173/174/229/230, já implementadas — este é um ajuste de config descoberto testando o
fluxo completo pela primeira vez em ambiente real.

## Riscos
Baixo — campo novo aditivo, comportamento da busca interativa não muda. Custo adicional real:
1 chamada Place Details por fornecedor novo encontrado, por organização+categoria, a cada 7 dias
(bounded pelo cache já existente).

## Esforço
Baixo

## Status
✅ Mergeada em `staging`, PR `staging→main` aberta: [api#82](https://github.com/douglasjava/easy-maintenance-api/pull/82).
**Confirmado por Douglas em ambiente real** — telefone chegou correto nos dois fornecedores.
Implementada na mesma branch/PR original da TASK-174/229
([api#80](https://github.com/douglasjava/easy-maintenance-api/pull/80)). TDD: testes falharam por
erro de compilação (construtor com 6 argumentos) antes da implementação, passaram depois. `mvn
test` → 912/912, 0 regressão.
