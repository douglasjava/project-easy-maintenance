# TASK-024 — Exportação de relatórios PDF/Excel

## Tipo
Produto / Feature

## Categoria
Backend / Frontend / Produto

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-006 — Produto SaaS

## Descrição
O nicho de manutenção regulatória exige documentação e histórico. Clientes precisam gerar relatórios de manutenções realizadas para apresentar a órgãos de fiscalização, síndicos, gestores ou auditores. A exportação de dados é um recurso essencial nesse segmento — sua ausência é um gap significativo para clientes B2B.

O billing já tem `reportsEnabled` como feature flag — está planejado mas não implementado.

## Problema
- Cliente não consegue extrair histórico de manutenções para compliance
- Relatórios são gerados manualmente via print ou cópia de tela
- Diferencial em relação a planilhas fica menor sem exportação

## Impacto
- Gap de produto que pode bloquear vendas para clientes corporativos
- Recurso de retenção: cliente que exporta regularmente tem mais stickiness

## Dependências
- `reportsEnabled` feature flag já existe no billing — apenas habilitar
- Definir formato prioritário: CSV (mais simples), Excel ou PDF

## Critérios de Aceite
- [x] Exportação de lista de manutenções em CSV com filtros (por data, status, item)
- [x] Exportação disponível apenas para planos com `reportsEnabled = true`
- [x] Usuário recebe arquivo para download imediatamente (até 5000 registros via blob)
- [x] Relatório inclui: item, data realizada, responsável, norma aplicável, próxima data
- [x] Botão de exportação visível na tela de manutenções

## Subtasks
- [x] Definir formato: CSV (menor complexidade)
- [x] Criar endpoint `GET /items/maintenances/export?itemId=...&startDate=...&endDate=...`
- [x] Verificar `reportsEnabled` antes de permitir exportação (403 se não habilitado)
- [x] Native SQL JOIN query limitada a 5000 registros (evitar OOM)
- [x] Adicionar botão "⬇ Exportar CSV" na tela de manutenções com loading state
- [x] Tratar caso de usuário sem feature `reportsEnabled` com `GuardedButton` + upgrade message

## Esforço
Grande (2-3 dias)

## Risco de não fazer
Bloqueador de vendas para segmentos que exigem relatórios (hospitais, condomínios com síndico técnico).

## Status
Concluído
