# Hooks — opt-in only

Эти hooks **не включены автоматически**. Это примеры. Чтобы включить:

**Windows / PowerShell (рекомендуется на Windows — без jq):**
```powershell
Copy-Item .claude\settings.windows.example.json .claude\settings.json
```
Эта версия вызывает `*.ps1`-хуки (`block-dangerous-bash.ps1`, `protect-secrets.ps1`, `scan-prompt-secrets.ps1`, `quality-reminder.ps1`) — работают на чистой Windows-машине без зависимостей.

**Linux / macOS / bash:**
```bash
cp .claude/settings.example.json .claude/settings.json
chmod +x .claude/hooks/*.sh
```
Эта версия вызывает `*.sh`-хуки — требуют `bash` + `jq` + `grep -P` (см. ниже).

## Зависимости (bash-хуки)

- `bash` (на Windows — Git Bash, обычно уже стоит; это не рекомендуемый путь на Windows — используй PowerShell-версию выше);
- `jq` — Linux: `apt install jq` / `dnf install jq` / `pacman -S jq`; macOS: `brew install jq`; Windows: `winget install jqlang.jq`;
- `grep -P` (PCRE) — стандартно на Linux (GNU grep). На macOS системный `grep` (BSD) **не поддерживает** `-P`: поставь `brew install grep` (даст `ggrep`) и экспортируй `SREDNOFF_GREP_BIN=ggrep`, либо работай через WSL.

Если `jq` не установлен — bash-хуки просто пропускают проверку (fail-open), команда не блокируется. Это безопасно для работы, но защита не сработает. Установи `jq` и `grep -P`, чтобы хуки реально фильтровали.

## Хуки (одинаковый набор в .ps1 и .sh, паритет функциональности)

- `hook-lib.ps1` / `hook-lib.sh` — общая библиотека (dot-source/source), не хук сама по себе: контентное сканирование секретов (OpenAI/Anthropic/GitHub/AWS/Google/Stripe/Slack/Twilio/SendGrid/npm ключи, PEM, JWT — 13 паттернов, сверены с gitleaks.toml) + audit-журнал.
- `block-dangerous-bash.ps1` / `.sh` — PreToolUse(Bash): блокирует опасные команды (`rm -rf /`, `mkfs`, `dd of=/dev/*`, fork-bomb, `chmod -R 777 /`, `git push --force`, `git reset --hard`, `format C:`) **и** секреты, вставленные прямо в команду.
- `protect-secrets.ps1` / `.sh` — PreToolUse(Read|Edit|Write|MultiEdit): блокирует доступ к секретным путям (`.env`, `*.pem`, `*.key`, `id_rsa`, `secrets.*`, `credentials.json`) **и** секреты, которые вот-вот запишутся в обычный файл (контент, не только путь).
- `scan-prompt-secrets.ps1` / `.sh` — UserPromptSubmit: блокирует сам промпт, если в нём есть вставленный секрет (до того, как он попадёт хоть куда-то). Контракт подтверждён по офиц. докам (`{"decision":"block","reason":...}`).
- `quality-reminder.ps1` / `.sh` — Stop: напоминание про тесты/безопасность/отчёт.

**Audit ledger:** все denies/blocks пишутся в `~/.claude/logs/hook-events.jsonl` (timestamp, хук, решение, находки, **sha256 сырого инпута** — не сам секрет). Логируются только сработавшие события, не каждый вызов — иначе журнал раздувается без пользы. Формат ledger одинаковый у `.ps1` и `.sh` версий (можно смешивать хосты и читать один общий журнал).
