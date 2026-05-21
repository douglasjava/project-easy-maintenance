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
Autenticação de dois fatores é um requisito crescente para clientes corporativos (hospitais, condomínios grandes, indústrias). 
Sem 2FA, o sistema depende exclusivamente da senha para proteção. Com crescimento da base de clientes, isso se torna um vetor de ataque relevante.

## Critérios de Aceite
- [x] 2FA via Google Authenticator implementado como opção
- [x] Usuário pode habilitar/desabilitar 2FA nas configurações do perfil
- [x] Backup codes gerados no momento de ativação do 2FA
- [x] Administradores de organização podem tornar 2FA obrigatório para todos os usuários da org
- [x] Fluxo de recovery para perda de 2FA (via e-mail + backup codes)

## Implementação

### Backend
- **`V62__totp_2fa.sql`** — tabelas `user_totp_settings`, `user_backup_codes`; coluna `require_2fa` em `organizations`
- **`UserTotpSettings.java`** / **`UserBackupCode.java`** — entidades JPA
- **`TotpService.java`** — geração de secret, QR code, verificação TOTP, backup codes (BCrypt)
- **`TwoFactorService.java`** — setup, confirmação, desativação, recuperação por e-mail
- **`UsersService.java`** — fluxo de login modificado: pending JWT (5 min, scope `2fa_pending`) quando 2FA ativo
- **`AuthController.java`** — `POST /auth/2fa/verify`, `POST /auth/2fa/request-recovery`, `POST /auth/2fa/apply-recovery`
- **`TwoFactorController.java`** — `GET/POST /me/2fa/*`, toggle `require_2fa` por org
- **`JwtService.java`** — método `generateWithTtl()` para pending token
- **`SecurityConfig.java`** — endpoints 2FA na lista pública

### Frontend
- **`login/page.tsx`** — step de verificação TOTP após login; recovery flow
- **`profile/page.tsx`** — card 2FA: status, setup com QR code, confirmação, backup codes, desativação, regeneração

### Testes
- **`TotpServiceTest.java`** — 14 testes unitários (secret, QR, verifyCode, backup codes, hash/verify)
- **`TwoFactorServiceTest.java`** — 30 testes (getStatus, initiateSetup, confirmSetup, disable, verifyForLogin, isEnabled, regenerateBackupCodes, requestEmailRecovery, applyEmailRecovery)
- Suite completa: **256 testes, 0 falhas**

## Esforço
Grande (1 semana)

## Status
Concluído
