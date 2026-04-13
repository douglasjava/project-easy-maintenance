# EPIC-007 — Performance e Escalabilidade

## Status
Não iniciado — 0/4 tasks entregues (TASK-027, 028 em SPRINT-04 pendente; TASK-036, 037 em SPRINT-05)

## Objetivo
Preparar o sistema para crescimento de base de clientes sem degradação de performance ou aumento linear de custos de infraestrutura.

## Descrição
O sistema atual é adequado para early stage, mas tem gargalos conhecidos que vão se manifestar com crescimento: upload de arquivos passando pelo backend (memória/CPU), chamadas IA síncronas bloqueando threads, jobs processando todo o banco de dados em loop, e paginação offset que degrada com volume.

## Impacto no Produto
- **Sem este épico:** Uploads lentos com arquivos grandes, timeouts em respostas de IA, jobs demorando horas com base de clientes grande, lentidão em listagens com muitos registros.
- **Com este épico:** Sistema escalável horizontalmente sem mudanças de arquitetura.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-027 | Pre-signed URLs S3 para uploads diretos | 🟡 Médio | 2 |
| TASK-028 | Processamento assíncrono de chamadas IA | 🟡 Médio | 2 |
| TASK-036 | Paginação cursor-based em listagens grandes | 🔵 Baixo | 3 |
| TASK-037 | Jobs de billing assíncronos com fila | 🔵 Baixo | 3 |

## Critério de Conclusão do Épico
- [ ] Upload de anexos usa pre-signed URL S3 (backend não processa binário)
- [ ] Chamadas à IA retornam imediatamente com job ID para polling
- [ ] Listagens principais suportam cursor-based pagination sem degradação
- [ ] Jobs de billing processam em lotes com commit parcial
