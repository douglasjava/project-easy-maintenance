# TASK-095 — Frontend: Página /indicador/[code] (dashboard do afiliado)

## Tipo
FRONTEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🟠 Alto

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Criar o painel público `/indicador/[code]` onde o afiliado acompanha suas indicações. O código no URL é a única autenticação — quem tem o link, acessa.

**Dados exibidos:**
- Link copiável (card destacado com botão "Copiar")
- Cards de resumo: total leads indicados, total convertidos, total a receber (R$), total recebido (R$)
- Tabela de indicações: e-mail mascarado (`jo***@gmail.com`), status (Lead / Convertido), data

**Estados a tratar:**
- Loading (spinner centralizado)
- Erro / code inválido (mensagem + link para cadastro)
- Sem indicações ainda (mensagem encorajadora)

## Critérios de Aceite
- [ ] Dados carregados via `GET /api/v1/affiliates/{code}/dashboard`
- [ ] E-mails exibidos mascarados (nunca PII completo)
- [ ] Valores em R$ formatados com `Intl.NumberFormat pt-BR`
- [ ] Badge "Convertido" em verde, "Lead" em cinza
- [ ] Botão "Copiar" usa clipboard API
- [ ] Página responsiva (mobile)
- [ ] Code inválido exibe erro amigável, não crash

## Esforço
Pequeno-Médio (2-3h)

## Status
Backlog

## Dependências
TASK-091 (endpoint `GET /affiliates/{code}/dashboard`)
