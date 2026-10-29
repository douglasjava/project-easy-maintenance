# TASK-372 — INFRA/CONFIG: Templates WhatsApp (confirmação de código + protocolo criado/concluído)

## Tipo
INFRA / CONFIG

## Categoria
Chamados de Moradores

## Prioridade
🔴 Crítico (bloqueia TASK-368 e TASK-371 em produção — submissão à Meta tem prazo de aprovação fora
do nosso controle, mesmo risco já visto no EPIC-023/`vencimento_manutencao_v3`; deve começar o mais
rápido possível, em paralelo com TASK-367)

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — confirmar os 2 templates aprovados pela Meta recebem e renderizam corretamente as variáveis
reais (nome, protocolo, categoria, organização, código), antes de qualquer flag ser ligada em
produção.

---

## Contexto

Pedido de Douglas (28/10/2026): separar a definição/submissão dos templates WhatsApp em task própria,
fora de TASK-368/371 — são artefatos de configuração externa (Meta Business), não código, e têm
prazo de aprovação independente do desenvolvimento. Detalhe completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

Definir e submeter à aprovação da Meta **2 templates (HSM)** novos:

1. **Template de validação de telefone** (usado por TASK-371) — envia o código de confirmação de
   6 dígitos ao morador que marcou o opt-in. Texto curto, categoria provável `Utility` (não é
   marketing — é confirmação de uma ação que o próprio morador iniciou). Nome sugerido:
   `chamado_morador_confirmacao_codigo_v1`. Variáveis: código.
2. **Template de atualização de protocolo** (usado por TASK-368) — cobre criação e conclusão do
   chamado. Avaliar na submissão se cabe **um único template genérico** com variável de status (ex.
   "Seu chamado nº {{1}} foi {{2}}" com `{{2}}` = "aberto"/"concluído") ou se a Meta exige **dois
   templates separados** por ter textos de propósito distinto — decisão fica a cargo de quem
   submeter, dependendo das regras de aprovação vigentes no momento. Nome sugerido:
   `chamado_morador_protocolo_v1` (ou `_criado_v1`/`_resolvido_v1` se precisar separar). Variáveis:
   nome do morador, protocolo, categoria (só na criação), nome da organização.
3. Documentar nome final e variáveis de cada template aprovado — necessário pra TASK-368/371
   referenciarem o nome exato no código (`templateName`).
4. Confirmar a categoria de aprovação de cada template (`Utility` x `Marketing`) — categoria errada
   pode exigir opt-in de marketing (como aconteceu no template `v3` do EPIC-023, TASK-229) ou ser
   rejeitada pela Meta.

## Critérios de Aceite

- [ ] Template de confirmação de código submetido e aprovado pela Meta
- [ ] Template(s) de protocolo criado/concluído submetido(s) e aprovado(s) pela Meta
- [ ] Nomes finais e variáveis documentados (neste arquivo ou na spec) pra TASK-368/371
      referenciarem sem ambiguidade
- [ ] Teste de envio real (sandbox ou produção controlada) confirma renderização correta das
      variáveis em cada template

## Dependências
Nenhuma técnica — pode começar em paralelo com TASK-367, já que é trabalho de configuração externa,
não depende do código. **Bloqueia** TASK-368 e TASK-371 em produção (o código pode ser escrito e
testado contra mock antes da aprovação, mas o envio real só funciona depois).

## Riscos
Prazo de aprovação da Meta é incerto e fora do controle do time (precedente: EPIC-023). Categoria de
aprovação (`Utility` x `Marketing`) pode vir diferente do esperado e exigir ajuste de opt-in —
mesmo problema já visto no `v3` do EPIC-023 (TASK-229).

## Esforço
Pequeno (trabalho de configuração, não de código) — mas com tempo de espera externo imprevisível.

## Status
📋 Backlog
