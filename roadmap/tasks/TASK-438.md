# TASK-438 — Samu: anexo sem contexto — evidência do último registro ou documento para ler

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Anexos

## Prioridade
🟡 Médio.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Fluxo I da [Parte B](../QA/registro-usabilidade-producao.md).

## Escopo
- Foto ou PDF fora de fluxo: [Evidência do último registro] [Documento para ler] [Outro].
- "Documento para ler" chama a leitura do EPIC-034 e propõe a ação (registrar, atualizar validade, cadastrar
  fornecedor, lançar despesa).

## Critérios de Aceite
- [x] Anexo fora de fluxo nunca é descartado em silêncio
- [x] "Evidência do último registro" anexa ao último registro da persona

## Dependências
[TASK-432](TASK-432.md). "Documento para ler" depende da [TASK-345](TASK-345.md).

## Riscos
Custo de IA na leitura: só quando o usuário escolhe "Documento para ler".

## Implementação (10/11/2026)
[api#215](https://github.com/douglasjava/easy-maintenance-api/pull/215), mergeada em `staging`.
- Foto ou PDF fora de fluxo oferece [Evidência do último registro] [Registrar manutenção] [Outro]. O último registro da persona fica guardado sem prazo (V150).
- Nunca em silêncio: "Outro", outro atalho ou a expiração avisam que o arquivo não foi guardado. Texto vira a descrição do registro, com o arquivo.
- **Fora do escopo:** "Documento para ler" entra com a TASK-345 (leitura por IA).
- `mvn test` 2021, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas; "Documento para ler" depende da TASK-345.
