# TASK-233 — INFRA/CONFIG: Seed sintético de dados para teste de carga

## Tipo
INFRA/CONFIG

## Categoria
Performance / Teste de carga

## Prioridade
🟡 Médio

## Épico
[EPIC-029](../epics/EPIC-029.md) — Teste de Carga Estrutural

## QA obrigatório
Sim — validar que o seed roda do início ao fim sem violar constraint (FK, `X-Org-Id`), e que o
volume final bate com o alvo (contagem de linhas por tabela).

---

## Contexto

Pra achar gargalo de código sob carga (N+1, falta de índice), o banco precisa ter volume de dado
realista — testar contra um banco local vazio não denuncia nada, a maioria dos problemas desse tipo
só aparece com dado suficiente pra a query ruim custar caro. Decisão do brainstorm (08/09/2026,
spec em `docs/superpowers/specs/2026-09-08-load-testing-epic-design.md`): escala **média** — uma
ordem de grandeza acima do que a base real de clientes deve ter hoje, o bastante pra expor o
problema sem tornar o setup impraticável de rodar repetidamente.

## Escopo

- Novo script `db/queries/loadtest-seed.sql`, gerado em lote via SQL (`INSERT ... SELECT` numérico
  ou stored procedure com loop — decisão de implementação, não pela camada de serviço/ORM, que
  seria lento demais pro volume alvo).
- Monta a hierarquia `organization` → `users` → `maintenance_item` → `maintenance`, respeitando FKs
  e a distinção multi-tenant (`X-Org-Id`) real do schema.
- Volume alvo: ~500 organizações, ~50 mil itens, ~150 mil manutenções.
- Roda **só contra um banco descartável** (MySQL local via Docker, mesmo padrão já usado na
  verificação da TASK-230 — container efêmero). Nunca aponta pra staging ou produção — script deve
  deixar isso explícito em comentário no topo do arquivo.
- README curto (pode ser comentário no próprio SQL, ou `db/queries/README-loadtest.md`) explicando
  como subir o container e rodar o seed.

## Critérios de Aceite

- [ ] Script roda do zero contra um MySQL 8 limpo (container Docker efêmero) sem erro de
      constraint/FK
- [ ] Volume final bate com o alvo (~500 orgs / ~50k itens / ~150k manutenções, tolerância razoável)
- [ ] Dado gerado é multi-tenant coerente (itens/manutenções de uma org não vazam pra outra)
- [ ] Script deixa explícito (comentário) que é só pra ambiente descartável, nunca staging/produção
- [ ] Tempo de execução documentado (quanto demora rodar do zero) — informação necessária pra
      TASK-235 saber se é viável rodar repetidamente

## Dependências
Nenhuma técnica. Independente da TASK-234 (podem andar em paralelo). TASK-235 depende deste seed
já pronto.

## Riscos
Baixo — roda só contra banco descartável, nunca toca staging/produção. Risco de esforço: gerar
volume relacional grande e coerente (multi-tenant, FKs) pode exigir iteração até ficar rápido o
suficiente pra rodar de novo sem fricção.

## Esforço
Médio

## Implementação

### Arquivos criados
- `db/queries/loadtest-seed.sql` — 100% set-based (`INSERT...SELECT` via tabela auxiliar de
  números 0..999, cross join de "dígitos", sem recursão/stored procedure), respeitando FKs e o
  modelo multi-tenant real (`user_organizations`, não a antiga coluna direta em `users`).
- `db/queries/README-loadtest.md` — como rodar, tempo medido, credenciais geradas.

### Decisões tomadas durante a implementação
- **Código de organização precisa ser hex-válido**: a primeira versão usava um prefixo
  `loadtest-...` legível, mas a API valida `X-Org-Id` como UUID (regex hex) — `loadtest` tem
  letras fora de `a-f` e a validação rejeitava com 400. Trocado pro padrão clássico `deadbeef-...`
  (hex válido, ainda reconhecível como dado sintético).
- **`seq_0999` referenciada duas vezes na mesma query (papel de org e de item) quebra**: MySQL não
  permite abrir a mesma `TEMPORARY TABLE` duas vezes numa query (`Can't reopen table`). Corrigido
  criando `seq_0999b`, uma segunda cópia idêntica, só pra esse caso.
- Todos os itens são `OPERATIONAL` (sem `norm_id`) — os 3 fluxos priorizados não distinguem
  item regulatório de operacional, e evitar o join com `norms` mantém a geração mais simples/rápida.

### Verificação (contra MySQL 8.0.33 real, container Docker efêmero)
- Volume bate exato com o alvo: 500 orgs / 500 users / 50.000 itens / 150.000 manutenções.
- Zero item/manutenção órfã; todo org com exatamente 100 itens (sem vazamento cross-tenant).
- Idempotente: rodado 2x seguidas, mesmo volume final nas duas.
- Tempo: ~9,4s primeira execução, ~22,3s reexecução (limpa antes de recriar).
- **Validado de ponta a ponta com a API real rodando** (TASK-235/258): login, `/items` e o job de
  detecção de notificação todos funcionaram contra este seed.

## Status
🟢 Implementada, testada e validada com a API rodando de verdade contra o dado gerado.
