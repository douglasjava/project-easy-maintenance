# TASK-148 — Frontend: ajustar tela de Relatório Analítico para refletir export em Excel

## Tipo
FRONTEND

## Categoria
Relatórios

## Prioridade
🔵 Baixo

## Épico
[EPIC-017](../epics/EPIC-017.md) — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## QA obrigatório
Sim — validar que o download funciona e o arquivo abre corretamente.

---

## Contexto

`src/app/reports/page.tsx` hoje rotula a ação de export como CSV (ícone, texto, extensão esperada).
Depois da TASK-147, o arquivo passa a ser `.xlsx` — a UI precisa refletir isso.

---

## Objetivo

Atualizar rótulos, ícone e tratamento de download da aba "Manutenções" de `/reports` para refletir
Excel em vez de CSV.

---

## Escopo

- Texto do botão ("Exportar CSV" → "Exportar Excel").
- Extensão/nome do arquivo baixado no `blob`/`Content-Disposition` handling do frontend.
- Revisar se o ícone atual (`FileText`, `Download` de `lucide-react`) ainda faz sentido ou merece
  troca.

---

## Critérios de Aceite

- [x] Rótulo e ícone refletem Excel, não CSV
- [x] Arquivo baixado abre corretamente como `.xlsx`
- [x] `npm run build` limpo

## Dependências
- **TASK-147** — precisa do backend já gerando `.xlsx`.

## Riscos
Nenhum.

## Esforço
Baixo

## Status
**Concluída** — implementado na branch `feature/EPIC-017-reports-accountability-analytics`
(`easy-maintenance-web`). `npm run build` limpo, `npm test` 86/89 (3 falhas pré-existentes, não
relacionadas). QA manual aprovado. Commitado, com PR aberto para `staging`.

## Implementação

- Rótulo do botão e `title` atualizados ("Exportar CSV" → "Exportar Excel").
- `Blob` type e extensão do arquivo baixado trocados pra
  `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` / `.xlsx`.
- **Ícone mantido** (`Download`, `lucide-react`) — já é genérico o suficiente pra qualquer formato de
  arquivo, não precisa de troca (avaliado conforme o Escopo previa).
- Mudança mínima e isolada, sem tocar em nenhuma outra lógica da tela.
