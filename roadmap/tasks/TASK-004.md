# TASK-004 — Testes mínimos para billing e tenant isolation

## Tipo
Qualidade / Débito técnico

## Categoria
Backend / Testes

## Prioridade
🔴 Crítico

## Fase
1 — Antes do lançamento (mínimo viável)

## Épico
EPIC-008 — Qualidade e Testes

## Descrição
O projeto não possui testes automatizados. Para um SaaS com billing real (Asaas), lógica de prorata, bloqueio de assinatura e multi-tenancy, a ausência de testes significa que qualquer mudança de código pode quebrar cobrança ou isolamento de dados sem que a equipe saiba.

Esta task define o escopo mínimo de testes a implementar antes do lançamento, focado em áreas de maior risco: cálculos de billing e isolamento entre tenants.

## Problema
Sem testes:
- Bug de cálculo de prorata pode cobrar valores errados de clientes
- Bug de tenant isolation pode expor dados de uma org para outra
- Refatoração de qualquer módulo crítico é feita às cegas
- Bugs são descobertos pelos clientes, não pela equipe

## Impacto
- Primeiro lançamento sem a rede de segurança mínima
- Qualquer hotfix em produção tem risco elevado de regressão

## Dependências
- Nenhuma hard dependency, mas recomenda-se resolver TASK-001 e TASK-003 antes para não testar código que será alterado

## Critérios de Aceite
- [ ] Testes unitários para `ProrataCalculator` cobrindo casos de borda (primeiro dia, último dia, meses com 28/30/31 dias)
- [ ] Testes unitários para cálculo de status de assinatura (TRIAL, ACTIVE, PAST_DUE, BLOCKED)
- [ ] Teste de integração: usuário da org A não consegue acessar dados da org B via API
- [ ] Teste de integração: trial de 7 dias com job de bloqueio funcionando corretamente
- [ ] Pipeline básico de CI configurado (GitHub Actions) executando testes em cada push para main
- [ ] Coverage mínimo de 70% nos módulos `billing` e `kernel`

## Subtasks
- [ ] Adicionar dependências de teste ao `pom.xml` (JUnit 5, Mockito, TestContainers para MySQL)
- [ ] Configurar `application-test.properties` com H2 ou TestContainers
- [ ] Escrever testes unitários de `ProrataCalculator`
- [ ] Escrever testes unitários de `SubscriptionStatusService` (ou equivalente)
- [ ] Escrever teste de integração de tenant isolation usando MockMvc
- [ ] Escrever teste de integração do fluxo trial → expiração
- [ ] Configurar GitHub Actions (`.github/workflows/ci.yml`)
- [ ] Documentar como rodar testes localmente

## Esforço
Grande (3-5 dias)

## Risco de não fazer
Primeiro bug de billing em produção gera chargeback, disputa e dano reputacional. Bug de tenant isolation é uma brecha de segurança que pode comprometer dados de todos os clientes.

## Status
Concluído
