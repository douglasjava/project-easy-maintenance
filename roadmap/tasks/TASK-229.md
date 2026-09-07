# TASK-229 — FULL_STACK: Opt-in de Marketing pro WhatsApp de fornecedores (v3)

## Tipo
FULL_STACK

## Categoria
Notificações / Fornecedores / Compliance (LGPD + política Meta)

## Prioridade
🟡 Médio

## Épico
[EPIC-023](../epics/EPIC-023.md) — Fornecedores nas Notificações de Vencimento

## QA obrigatório
Sim — QA manual: ativar/desativar os dois toggles no perfil, confirmar que o de marketing só
habilita com o de utilidade já ligado, confirmar que o backend rejeita marketing sem utilidade.

---

## Contexto

A Meta aprovou o template `vencimento_manutencao_v3` (TASK-174) só como categoria **Marketing**,
não Utility — o conteúdo (sugestão de fornecedor terceiro) é lido pelo classificador automático da
Meta como promocional, mesmo depois de reformular o texto pra soar mais factual (tentativa
registrada, não teve jeito). Decisão de Douglas (07/09/2026): aceitar Marketing e construir o
opt-in específico, em vez de deixar o fornecedor fora do WhatsApp.

Mensagens de categoria Marketing exigem consentimento próprio, separado do opt-in genérico de
notificação já existente (`whatsappOptIn`, TASK-122) — não dá pra reaproveinar o mesmo checkbox
sem ficar vago sobre o que a pessoa está de fato aceitando receber.

## Escopo

### Backend
- Nova migration `V107__add_whatsapp_marketing_opt_in_to_users.sql`: coluna `whatsapp_marketing_opt_in
  BOOLEAN NOT NULL DEFAULT FALSE`, mesmo padrão da V80.
- `User`: novo campo `whatsappMarketingOptIn`.
- `UserDTO.UpdateUserRequest`/`UserResponse`: novo campo.
- `UsersService.applyWhatsappMarketingOptIn`: exige `whatsappOptIn` (o de utilidade) já ativo antes
  de permitir marketing — mesmo espírito da validação existente que exige telefone antes de
  utilidade.
- `BusinessWhatsAppNotificationService.resolveSuppliersForTemplate`: ganha o `recipient` como
  parâmetro, checa `recipient.isWhatsappMarketingOptIn()` além da flag global
  (`supplier-template-enabled`) e do checkpoint (`NEAR_DUE daysOffset=30`). Sem esse opt-in, cai
  pro payload padrão (`v2`), mesmo fallback já usado pra <2 fornecedores.

### Frontend
- `profile/page.tsx`: novo toggle "Sugestões de fornecedores parceiros", visualmente aninhado sob o
  toggle de notificações WhatsApp já existente, **desabilitado até o de utilidade estar ligado**.
  Texto de consentimento explícito distinguindo de "avisos de vencimento" (mensagem de conta) —
  deixa claro que é conteúdo promocional/de terceiros.

## Critérios de Aceite

- [x] Novo campo persistido, migration idempotente/reversível no padrão do projeto
- [x] Backend rejeita `whatsappMarketingOptIn=true` sem `whatsappOptIn=true`
- [x] `BusinessWhatsAppNotificationService` só usa `v3` quando: checkpoint de 30 dias + flag
      `supplier-template-enabled=true` + 2+ fornecedores encontrados + `recipient.
      whatsappMarketingOptIn=true` — qualquer um desses ausente cai pro `v2`
- [x] Frontend: toggle de marketing desabilitado enquanto o de utilidade estiver desligado;
      desligar o de utilidade desliga o de marketing também (mesmo princípio já aplicado ao
      telefone→utilidade)
- [x] Testes cobrindo os cenários acima (backend); `npm run build` limpo (frontend)
- [x] `mvn test` sem regressão (911/911)

## Dependências
TASK-174 (código do `v3` já implementado, PR [api#80](https://github.com/douglasjava/easy-maintenance-api/pull/80)
ainda aberta — esta task continua na mesma branch/PR).

## Riscos
Baixo — aditivo, mesmo padrão de um campo de opt-in que já existe e já está testado. Ponto de
atenção: usuários que já tinham `whatsappOptIn=true` antes desta task não têm
`whatsappMarketingOptIn` retroativo (default `FALSE`) — precisam ativar explicitamente, o que é o
comportamento correto (consentimento não pode ser presumido).

## Esforço
Baixo-Médio

## Status
✅ Implementada — continuação da TASK-174 na mesma branch/PR
([api#80](https://github.com/douglasjava/easy-maintenance-api/pull/80)), depois da Meta confirmar
que o template só é aprovado como Marketing. Frontend em PR separada:
[web#72](https://github.com/douglasjava/easy-maintenance-web/pull/72). `mvn test` → 911/911, 0
regressão. `npm run build` limpo (`npm test` com 3 falhas pré-existentes em `middleware.test.ts`,
confirmadas não relacionadas). Douglas já tem o template `v3` aprovado — falta mergear as duas PRs
e ligar `notification.whatsapp.supplier-template-enabled=true` em produção.
