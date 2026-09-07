# TASK-230 — BUGFIX Backend: `V106` falha em MySQL real — coluna `notes` pequena demais

## Tipo
BUGFIX

## Categoria
Backend / Migrations (Flyway)

## Prioridade
🔴 Crítico — bloqueia qualquer deploy/migração daqui pra frente (Flyway para na primeira migration
que falha; `V107`, `V108`... nunca chegam a rodar enquanto `V106` não for corrigida).

## Contexto

Douglas reportou, rodando contra MySQL real:

```
SQL State  : 22001
Error Code : 1406
Message    : Data truncation: Data too long for column 'notes' at row 1
Location   : db/migration/V106__seed_pontos_ancoragem_norm.sql, Line 18
```

Achado exatamente o que eu tinha alertado no risco da própria TASK-228: este repo não tem teste
automatizado que valide sintaxe/tamanho de dado de migration contra MySQL real (suite roda em H2
com `spring.flyway.enabled=false`) — só é validado de verdade no primeiro boot contra o banco real.

**Causa raiz confirmada**: `norms.notes` é `VARCHAR(500)` (`V1__init_schema.sql`). O texto da norma
`PONTOS_ANCORAGEM` (`V106`, TASK-228) tem ~700 caracteres — MySQL em modo estrito (`STRICT_TRANS_TABLES`,
padrão em instâncias modernas) rejeita o `INSERT` inteiro em vez de truncar silenciosamente. A
migration nunca chega a aplicar em nenhum ambiente onde isso já rodou.

## Verificação (não só teórica — testado contra MySQL real)

Reproduzi o erro exato (mesmo SQL State/Error Code/mensagem/linha) rodando as 106 migrations contra
um MySQL 8.0 real em modo estrito (container Docker efêmero). Confirmei que a correção abaixo
resolve — as 106 migrations aplicam limpo do zero contra o mesmo banco.

## Correção

`V106__seed_pontos_ancoragem_norm.sql` (**editada diretamente, não uma migration nova** — ver
Justificativa abaixo): adiciona `ALTER TABLE norms MODIFY COLUMN notes VARCHAR(2000) NULL;` antes
do `INSERT`, alargando a coluna de 500 pra 2000 caracteres. Protege também futuras normas com notas
mais detalhadas, não só esta.

### Justificativa de editar `V106` em vez de criar uma migration nova

Regra geral do projeto é nunca editar uma migration já aplicada — mas `V106` **nunca aplicou com
sucesso em lugar nenhum** (o próprio erro reportado é a prova disso: o `INSERT` é rejeitado por
inteiro, nada fica gravado). `V106` só foi mergeada em `staging` (PR api#77), nunca promovida pra
`main` (confirmado via `gh pr list`). Criar uma migration nova (`V108` fazendo só o `ALTER`) não
resolveria nada, porque o Flyway processa em ordem — ele nunca chegaria a `V108` enquanto `V106`
continuar falhando primeiro. Editar `V106` diretamente é o remédio padrão pra uma migration quebrada
que nunca completou em nenhum ambiente.

## Ação necessária no ambiente de cada um (fora do meu alcance — não tenho acesso a banco)

Qualquer ambiente onde a tentativa de aplicar `V106` já falhou (provavelmente o local do Douglas, e
possivelmente o Railway de `staging` se o deploy automático já tentou) vai ter uma entrada `FAILED`
pra `V106` na tabela `flyway_schema_history`, bloqueando o Flyway de tentar de novo mesmo com o
arquivo corrigido (`spring.flyway.validate-on-migrate=true` detecta o checksum diferente). Antes de
rodar a aplicação com esta correção, rodar em cada banco afetado:

```sql
DELETE FROM flyway_schema_history WHERE version = '106' AND success = 0;
```

(Se não houver nenhuma entrada `FAILED` pra `106` — ambiente que nunca chegou a tentar — não precisa
fazer nada, a aplicação corrigida já resolve sozinha.)

## Critérios de Aceite

- [x] Causa raiz confirmada (`VARCHAR(500)` vs. ~700 caracteres de conteúdo)
- [x] Erro reproduzido byte-a-byte contra MySQL 8 real em modo estrito
- [x] Correção validada — as 106 migrations aplicam limpo do zero contra o mesmo banco, com a
      correção aplicada
- [x] Comentário na própria migration documentando o bugfix, pra rastreabilidade

## Dependências
Nenhuma técnica. Depende de cada ambiente já impactado rodar o `DELETE` acima antes do próximo
deploy/boot (instrução comunicada ao Douglas).

## Riscos
Baixo pro código em si (`ALTER ... MODIFY COLUMN` alargando um `VARCHAR` nunca trunca dado
existente). Risco operacional real: se algum ambiente compartilhado (ex. `staging` na Railway) já
tentou e falhou, precisa do `DELETE` manual antes do próximo deploy — comunicado explicitamente.

## Esforço
Baixo

## Status
✅ Mergeada em `staging` ([api#81](https://github.com/douglasjava/easy-maintenance-api/pull/81)) —
Douglas confirmou que rodou certinho contra o banco real depois do `DELETE` na `flyway_schema_history`.
Branch da TASK-174/229 (`feature/TASK-174-supplier-in-whatsapp-notification`, PR
[api#80](https://github.com/douglasjava/easy-maintenance-api/pull/80)) já atualizada com essa
correção (merge de `staging`, sem conflito, `mvn test` → 911/911).
