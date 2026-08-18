# EPIC-023 — Fornecedores nas Notificações de Vencimento

## Status
Desenhado via brainstorm com Douglas (18/08/2026), pronto para implementar. Spec em
`docs/superpowers/specs/2026-08-18-supplier-notifications-design.md`.

## Objetivo
Fechar o ciclo "avisei que venceu" → "aqui está quem pode resolver" numa etapa só: as notificações
de vencimento/atraso de manutenção (e-mail e WhatsApp, EPIC-015) passam a trazer 2-3 fornecedores
próximos direto na mensagem, em vez do síndico precisar abrir o sistema e buscar manualmente no
fluxo de "registrar manutenção" (busca ao vivo já existente, `SupplierSearchService`).

## Descrição

A busca de fornecedores existente depende de geolocalização do navegador (`navigator.geolocation`),
chamada só no clique do usuário — não existe fornecedor salvo em banco, nem coordenada de
organização. O job de notificação roda à noite, sem navegador. Esta epic cria a peça que faltava:
um novo `SupplierLookupService` que busca fornecedor por **texto** (cidade/estado do endereço da
organização, já cadastrado) em vez de coordenada — sem geocodificação nova — com cache de 7 dias,
chamado só pelos canais que já disparam WhatsApp/E-mail hoje (não pelo PUSH in-app).

**Diferença importante entre os dois canais**:
- **E-mail**: sem restrição — bloco de fornecedores (0 a N encontrados) entra direto no HTML já
  existente, pode ir pro ar assim que implementado.
- **WhatsApp**: usa template HSM pré-aprovado pela Meta (`vencimento_manutencao_v2`, 5 variáveis
  fixas) — não dá pra editar um template já aprovado. Precisa de um template **novo**
  (`vencimento_manutencao_v3`, 9 variáveis: as 5 atuais + nome/telefone de 2 fornecedores fixos),
  submetido à Meta e aprovado antes de ir pro ar — mesma dependência externa e mesmo risco de
  demora que já atrasou o `v2` original (EPIC-015). Se a busca achar menos de 2 fornecedores pra
  aquela categoria/região, o envio por WhatsApp desse evento específico é pulado (mesmo fallback já
  existente pra outras falhas de envio).

---

## Contexto Técnico

- `NotificationEventDetectionJob` → `NotificationOrchestratorService` → canal (já existe, EPIC-015)
  — `NotificationEvent` **não** ganha campo novo; a busca de fornecedor acontece dentro de cada
  serviço de canal, não no evento/orquestrador.
- `SupplierSearchService.mapServiceKeyToKeyword` (whitelist itemType→keyword) é reaproveitado, não
  duplicado — extraído pra local compartilhado.
- Cache novo (`suppliersNotification`, Caffeine, TTL 7 dias) — separado do cache de curto prazo do
  fluxo interativo.
- `whatsapp.default-template-name` (hoje `vencimento_manutencao_v2`) só migra pra `v3` depois do
  template novo estar aprovado pela Meta — até lá, o código pode estar pronto sem o canal
  WhatsApp-com-fornecedor estar de fato ativo em produção.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-172](../tasks/TASK-172.md) | Backend: `SupplierLookupService` — busca textual + cache 7 dias | BACKEND | 🟠 Alto |
| [TASK-173](../tasks/TASK-173.md) | Backend: fornecedores no e-mail de notificação | BACKEND | 🟠 Alto |
| [TASK-174](../tasks/TASK-174.md) | Backend: fornecedores no WhatsApp — template v3 (depende de aprovação Meta) | BACKEND | 🟡 Médio |

Ordem: TASK-172 primeiro (as outras duas dependem dela) → TASK-173 e TASK-174 podem andar em
paralelo do ponto de vista de código, mas a TASK-174 só fica realmente ativa em produção depois da
aprovação do template pela Meta (ação do Douglas, fora do controle da implementação).

---

## Critério de Conclusão do Épico

- [ ] `SupplierLookupService` busca fornecedor por cidade/estado, cacheado 7 dias, nunca propaga
      exceção pro chamador (falha = lista vazia)
- [ ] E-mail de notificação (`OVERDUE`) mostra bloco de fornecedores quando encontrados
- [ ] WhatsApp de notificação (`NEAR_DUE` dia 1 / `OVERDUE`) envia com 2 fornecedores quando
      encontrados; pula o envio (fallback já existente) quando encontra menos de 2
- [ ] Template `vencimento_manutencao_v3` submetido à Meta (ação do Douglas)
- [ ] Testes cobrindo 0/1/2+ fornecedores encontrados em cada canal
- [ ] `mvn test` sem regressão

---

## Fora de Escopo

- Geocodificação de endereço da organização (lat/lng reais, busca por raio real).
- Expansão do whitelist `itemType → keyword` além do que já existe hoje.
- Fornecedor em notificação `PUSH` (in-app).
- Qualquer persistência de fornecedor (tabela, histórico, avaliação) — segue sendo busca ao vivo.
- Tratamento alternativo pro WhatsApp com só 1 fornecedor encontrado (ex.: template pra 1 vaga) —
  decisão explícita foi pular o envio nesse caso.

## Riscos
- **Aprovação da Meta do template `v3`** é dependência externa fora do controle da implementação —
  mesmo risco que já atrasou o `v2`. TASK-174 pode ficar com código pronto e testado sem o canal
  estar de fato ativo até a aprovação sair.
- Custo/rate-limit do Google Places, mitigado pelo cache de 7 dias e pelo escopo restrito (só
  eventos que já disparam WhatsApp/E-mail) — vale observar volume real pós-rollout.
- Busca textual por cidade/estado é menos precisa que busca por raio real, especialmente em cidades
  grandes — trade-off aceito pra evitar geocodificação nesta leva.
