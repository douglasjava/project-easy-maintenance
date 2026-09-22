# TASK-279 — Busca de fornecedor por raio geográfico real (lat/long)

## Tipo
FULL_STACK

## Categoria
Backend / Frontend / Marketplace de Fornecedores

## Prioridade
🟡 Médio — ideia registrada, sem brainstorm ainda

## Épico
[EPIC-028](../epics/EPIC-028.md) — Marketplace de Fornecedores

## Problema

`SupplierRepository.findByRegionVisibleTo` (Fase 1) filtra fornecedores por match **literal** de
`city`/`state` — já era um item explícito de "Fora de Escopo" desde o design original do EPIC-028
("Raio geográfico real (lat/long) — fica em cidade/estado").

```java
WHERE s.city = :city AND s.state = :state
```

Um fornecedor cadastrado em "São Paulo/SP" nunca aparece pra uma organização de "Guarulhos/SP",
mesmo sendo cidades vizinhas. Funciona razoavelmente quando `city` é um município grande (a
premissa original: "fornecedor de manutenção predial atende a cidade toda"), mas piora em regiões
metropolitanas fragmentadas em muitos municípios pequenos — exatamente o caso de Guarulhos/SP,
Contagem/BH, etc.

Levantado por Douglas durante o QA do Pix Automático em produção (22/09/2026), ao notar que a busca
não considera raio real.

## Ideia (não desenhada ainda)

Geocodificar `city`/`state` (ou um endereço mais preciso) em lat/long no cadastro do fornecedor (e
da organização), e trocar o filtro por distância real (raio configurável, ex. 30km) em vez de match
exato de string.

## Status
Backlog (ideia registrada, sem brainstorm/desenho técnico)
