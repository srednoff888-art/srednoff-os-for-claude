# 50-security.md

Запрещено без явного подтверждения:

- удалять production-данные;
- менять production env vars;
- отключать RLS/auth/security;
- читать/публиковать секреты без необходимости;
- коммитить `.env`;
- выполнять платные действия;
- менять DNS/domain/payment settings;
- делать irreversible migrations.

Всегда проверяй:

- input validation; auth boundaries; SQL injection; XSS; SSRF; CSRF;
- rate limits; secrets handling; PII handling.
