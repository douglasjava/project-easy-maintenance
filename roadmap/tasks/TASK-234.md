# TASK-234 — BACKEND: Profile `loadtest` — contagem de query por request

## Tipo
BACKEND

## Categoria
Performance / Teste de carga

## Prioridade
🟡 Médio

## Épico
[EPIC-029](../epics/EPIC-029.md) — Teste de Carga Estrutural

## QA obrigatório
Sim — confirmar que o profile é opt-in de verdade: aplicação sobe normalmente sem o profile ativo
e o comportamento (incluindo `mvn test`, que não usa esse profile) não muda em nada.

---

## Contexto

Tempo de resposta sozinho não diz **por que** um endpoint é lento sob carga — o sinal mais direto
de N+1 é a contagem de query SQL disparada por request, e isso não está instrumentado hoje
(`hibernate.generate_statistics` desligado, sem `show_sql`). Precisa ser ligado só sob demanda, pra
não pesar o comportamento padrão da aplicação. Decisão do brainstorm (08/09/2026): novo profile
Spring dedicado, nunca ativo em dev/staging/produção por padrão.

Precedente de que isso resolve problema real: TASK-224 (01/09/2026) corrigiu um N+1 em
`resolveNormInfo` (listagem de itens) que só apareceu como sintoma visível em log de produção — sem
instrumentação ativa, esse tipo de problema passa despercebido até virar reclamação de cliente.

## Escopo

- Novo profile Spring `loadtest` (`application-loadtest.properties` ou equivalente), ativado só via
  `--spring.profiles.active=loadtest` explícito na hora de rodar o teste de carga.
- Sob esse profile: `spring.jpa.properties.hibernate.generate_statistics=true` + configuração de
  log (nível `DEBUG`/`TRACE` no logger de estatísticas do Hibernate, ou equivalente) que permite
  correlacionar contagem de query por request.
- Sem esse profile ativo (comportamento padrão — dev, staging, produção, suíte de testes): nenhuma
  mudança de comportamento, config ou performance.
- Pool de conexão (HikariCP) não precisa de trabalho novo — já visível via Micrometer/Actuator.

## Critérios de Aceite

- [ ] Profile `loadtest` liga `hibernate.generate_statistics` + log de contagem de query só quando
      ativado explicitamente
- [ ] Aplicação sobe normalmente sem o profile ativo, comportamento idêntico ao de hoje
- [ ] `mvn test` (que não ativa esse profile) sem regressão, 0 mudança de comportamento
- [ ] Documentado (README curto ou comentário no arquivo de properties) como ativar o profile e
      onde olhar a contagem de query gerada

## Dependências
Nenhuma técnica. Independente da TASK-233 (podem andar em paralelo). TASK-235 depende deste
profile já pronto pra conseguir correlacionar contagem de query com os endpoints testados.

## Riscos
Baixo — mudança aditiva e opt-in, comportamento padrão da aplicação não muda. Ponto de atenção:
`generate_statistics=true` tem custo de overhead — por isso fica isolado num profile que só roda
durante o teste de carga em ambiente descartável, nunca em produção/staging.

## Esforço
Baixo

## Status
🔴 Não iniciada
