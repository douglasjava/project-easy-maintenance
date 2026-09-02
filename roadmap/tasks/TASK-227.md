# TASK-227 — INFRA/CONFIG: Biblioteca de queries de acompanhamento de clientes (trial/pagantes/atraso)

## Tipo
INFRA / CONFIG

## Categoria
Backend / Ferramentas internas (SQL de acompanhamento, sem impacto em produção)

## Prioridade
🟡 Médio — não é bloqueio de nada, mas evita retrabalho constante agora que existem clientes
reais em TRIAL pra acompanhar.

## Contexto

Com clientes reais entrando em TRIAL, Douglas precisa acompanhar o funil (quem ainda não
cadastrou, quem tá em trial, quanto tempo falta, quem já é pagante, quem tá em atraso) sem
escrever um SELECT do zero toda vez. Pedido explícito: pensar juntos na lista antes de criar,
depois deixar tudo num lugar só, com título, pra só buscar e rodar.

## Decisão (Douglas, 02/09/2026)

Lista inicial de 10 queries (confirmada via `AskUserQuestion` antes de implementar — "cobre tudo,
pode seguir"), salva num arquivo `.sql` único com seções tituladas (opção escolhida sobre "um
arquivo por query"). Depois, mesma sessão, Douglas pediu mais 4 (leads convertidos, trial nunca
ativado, usuário sem item cadastrado, itens/manutenções cadastradas por cliente) — acrescentadas
na mesma branch/PR por ainda estar aberta.

## Escopo

- `db/queries/acompanhamento-clientes.sql` (novo, na raiz do repo `easy-maintenance-api`, **fora**
  de `src/main/resources/db` — não é migration Flyway, é só biblioteca de referência):
  1. Leads que ainda não cadastraram (`landing_leads.status IN ('NEW','CONTACTED')`)
  2. Funil de leads por status (contagem agrupada)
  3. Quem está em TRIAL agora
  4. Trial — dias restantes até `current_period_end`, ordenado por urgência
  5. Trial expirado sem conversão (`TRIAL_EXPIRED`)
  6. Ativos pagantes (`ACTIVE`)
  7. Receita por plano (assinaturas ativas, agrupado por plano + ciclo)
  8. Em atraso (`PAST_DUE`) + dias até o bloqueio automático (`billing.blocking.days-after-due`)
  9. Cancelados recentes (`cancel_at_period_end`/`canceled_at`)
  10. Clientes perto do limite de organizações do plano (≥80% do `maxOrganizations` do
      `features_json`) — mesmo cenário da TASK-225 se repetindo
  11. Leads que já viraram usuário (`landing_leads.email` × `users.email`, pelo dado real, não
      pelo status manual do lead)
  12. Usuários que ainda não ativaram o trial (sem nenhuma `billing_subscriptions` — trial é
      criado no 1º passo do onboarding, `OnboardingService.createUser`, antes mesmo de existir
      organização; sem essa linha, o usuário só criou login e nunca completou esse passo)
  13. Usuários sem nenhum item cadastrado (trial/ativo mas produto nunca usado de verdade —
      cobre tanto onboarding incompleto quanto quem criou org e nunca cadastrou item)
  14. Itens e manutenções cadastradas por cliente (volume de uso de todo mundo em TRIAL/ACTIVE:
      quantidade de itens, quantidade de manutenções já registradas em `maintenances` e data da
      última manutenção — complemento da query 13, mostra quem está engajado de verdade)

## Critérios de Aceite

- [x] Arquivo único, com título por query, fácil de buscar
- [x] Colunas/tabelas conferidas contra as migrations reais (`billing_subscriptions`,
      `billing_accounts`, `billing_subscription_items`, `billing_plans`, `landing_leads`,
      `user_organizations`)
- [x] Fora do diretório de migrations Flyway (não pode ser confundido com schema change)
- [ ] Rodar cada query pelo menos uma vez contra o banco real pra confirmar (não foi possível
      nesta sessão — sem acesso direto ao banco)

## Dependências
Nenhuma — arquivo de referência isolado, sem mudança de código/schema/comportamento.

## Riscos
Nenhum — não é executado pela aplicação, não entra em nenhum fluxo automatizado.

## Esforço
Baixo

## Status
✅ Implementada, PR aberta contra `staging`:
[api#75](https://github.com/douglasjava/easy-maintenance-api/pull/75). Recomendado rodar cada
query uma vez contra o banco real antes do uso do dia a dia, já que este cowork não tem acesso
direto ao banco pra validar.
