# TASK-029 — Runbook de incidentes e operação

## Tipo
Operação / Documentação

## Categoria
Infra / Operação

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-005 — Observabilidade e Operação

## Descrição
Um runbook é um documento operacional que descreve como responder a incidentes conhecidos. Sem runbook, a resposta a incidentes em produção depende de quem está disponível e de quanto tempo leva para diagnosticar o problema.

## Incidentes Prioritários a Documentar

1. **Job de billing falhou** — como verificar, como reprocessar manualmente
2. **Asaas fora do ar** — como comunicar clientes, o que bloquear, o que liberar
3. **Banco de dados lento** — como identificar query pesada, como escalar
4. **OpenAI quota esgotada** — como o fallback está configurado, como recarregar
5. **Railway restart loop** — como diagnosticar, como rollback
6. **Cobrança duplicada** — como identificar, como reverter no Asaas, como comunicar cliente

## Critérios de Aceite
- [x] Runbook para os 6 cenários listados acima documentados em `/docs/runbooks/`
- [x] Cada runbook tem: sintomas, causa provável, passos de diagnóstico, passos de resolução, como comunicar o cliente
- [x] Runbook acessível para toda a equipe (não apenas o tech lead)

## Esforço
Pequeno (1 dia)

## Risco de não fazer
Primeiro incidente em produção vira caos. Tempo de resolução alto com clientes impactados.

## Status
Concluído
