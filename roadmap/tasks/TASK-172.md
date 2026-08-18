# TASK-172 — Backend: `SupplierLookupService` — busca textual + cache 7 dias

## Tipo
BACKEND

## Categoria
Notificações / Fornecedores

## Prioridade
🟠 Alto

## Épico
[EPIC-023](../epics/EPIC-023.md) — Fornecedores nas Notificações de Vencimento

## QA obrigatório
Sim — testes automatizados cobrindo sucesso, 1 resultado, 0 resultados e erro de API. Sem QA
manual necessário nesta task isoladamente (não tem UI nem canal de envio ainda — isso é TASK-173 e
TASK-174).

---

## Contexto

O job de notificação (`NotificationEventDetectionJob`) roda à noite, sem navegador — não tem como
reaproveitar a busca de fornecedores existente (`SupplierSearchService.searchNearby`), que depende
de `navigator.geolocation` chamado no clique do usuário. Esta task cria a peça que falta: busca de
fornecedor por **texto** (cidade/estado), não por coordenada.

Detalhe completo da decisão em `docs/superpowers/specs/2026-08-18-supplier-notifications-design.md`.

## Objetivo

Novo `SupplierLookupService` com um método que recebe cidade/estado + categoria de item e devolve
uma lista de fornecedores próximos (nome, telefone, endereço/link do Maps), nunca lançando exceção
— falha vira lista vazia.

## Escopo

- `SupplierLookupService.findNearbyByCityState(String city, String state, String categoryKeyword)`.
- Reaproveita o cliente HTTP do Google Places já usado em `SupplierSearchService`, mas chama o
  endpoint **Text Search** (`textsearch/json`) em vez de Nearby Search — query no formato
  `"{categoryKeyword} em {city}, {state}"`.
- Extrai `SupplierSearchService.mapServiceKeyToKeyword` (whitelist itemType→keyword: `EXTINTOR`,
  `SPDA`, `CAIXA_DAGUA`, `ILUMINACAO_EMERGENCIA`, `HIDRANTE`, `AR_COND` + fallback genérico) pra um
  local compartilhado entre os dois serviços — **não duplicar** o whitelist.
- Cache Caffeine novo (`suppliersNotification`), TTL 7 dias, chave `(organizationCode,
  categoryKeyword)` — **não** reaproveitar o cache de curto prazo (`suppliersNearby`) do fluxo
  interativo.
- Qualquer falha (timeout, quota, 4xx/5xx da API, categoria sem resultado) retorna lista vazia —
  nunca propaga exceção pro chamador.

## Critérios de Aceite

- [ ] `findNearbyByCityState` retorna fornecedores reais via Google Places Text Search
- [ ] Resultado cacheado 7 dias por `(organizationCode, categoryKeyword)`, sem chamar a API de novo
      dentro da janela
- [ ] Erro de API (mock de timeout/4xx/5xx) retorna lista vazia, não lança exceção
- [ ] Categoria sem resultado retorna lista vazia
- [ ] Whitelist itemType→keyword reaproveitado de `SupplierSearchService`, não duplicado
- [ ] Testes unitários cobrindo os 4 cenários acima

## Dependências
Nenhuma.

## Riscos
Baixo — serviço novo e isolado, sem consumidor ainda (TASK-173/174 conectam depois).

## Esforço
Baixo-Médio

## Status
Pronto para implementar.
