# TASK-039 — Autenticação 2FA (dois fatores)

## Tipo
Segurança / Produto

## Categoria
Backend / Frontend / Segurança

## Prioridade
🔵 Baixo

## Fase
3 — Escala

## Épico
EPIC-001 — Segurança Crítica

## Descrição
Autenticação de dois fatores é um requisito crescente para clientes corporativos (hospitais, condomínios grandes, indústrias). Sem 2FA, o sistema depende exclusivamente da senha para proteção. Com crescimento da base de clientes, isso se torna um vetor de ataque relevante.

## Critérios de Aceite
- [ ] 2FA via TOTP (Google Authenticator, Authy) implementado como opção
- [ ] Usuário pode habilitar/desabilitar 2FA nas configurações do perfil
- [ ] Backup codes gerados no momento de ativação do 2FA
- [ ] Administradores de organização podem tornar 2FA obrigatório para todos os usuários da org
- [ ] Fluxo de recovery para perda de 2FA (via e-mail + backup codes)

## Esforço
Grande (1 semana)

## Status
Backlog
