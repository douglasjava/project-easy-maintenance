# TASK-038 — LGPD: exportação e exclusão de dados pessoais

## Tipo
Compliance / Produto / Legal

## Categoria
Backend / Frontend / Compliance

## Prioridade
🔵 Baixo

## Fase
3 — Escala

## Épico
EPIC-003 — Multi-tenancy e Autorização

## Descrição
A Lei Geral de Proteção de Dados (LGPD) garante ao titular de dados o direito de:
- Acessar seus dados pessoais (portabilidade)
- Solicitar a exclusão de seus dados (direito ao esquecimento)
- Corrigir dados incorretos

Para um SaaS comercial, especialmente com clientes corporativos, a conformidade com LGPD é um requisito legal e de confiança.

## Critérios de Aceite
- [ ] Endpoint `GET /users/me/data-export` que retorna todos os dados pessoais do usuário em JSON
- [ ] Endpoint `DELETE /users/me` que inicia processo de exclusão de dados com confirmação
- [ ] Processo de exclusão: anonimiza dados pessoais (não deleta registros relacionados ao compliance)
- [ ] Política de privacidade acessível no frontend e no footer
- [ ] Prazo de resposta para solicitações: 15 dias (conforme LGPD)

## Subtasks
- [ ] Mapear todos os dados pessoais armazenados (nome, e-mail, CPF, endereço, etc.)
- [ ] Implementar endpoint de exportação
- [ ] Implementar processo de anonimização (substituir nome por "Usuário Removido", e-mail por hash, etc.)
- [ ] Criar página de privacidade no frontend
- [ ] Definir DPO (Data Protection Officer) ou canal de contato para solicitações

## Esforço
Grande (3-5 dias)

## Status
Backlog
