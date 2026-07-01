# Hooks — opt-in only

Эти hooks **не включены автоматически**. Это примеры. Чтобы включить:

**Windows / PowerShell (рекомендуется — без jq):**
```powershell
Copy-Item .claude\settings.windows.example.json .claude\settings.json
```
Эта версия вызывает `*.ps1`-хуки (`block-dangerous-bash.ps1`, `protect-secrets.ps1`, `scan-prompt-secrets.ps1`, `quality-reminder.ps1`) — работают на чистой Windows-машине без зависимостей.

**bash / jq:**
```bash
cp .claude/settings.example.json .claude/settings.json
```

## Зависимости

Bash-хуки (`*.sh`) требуют:

- `bash` (на Windows — Git Bash, обычно уже стоит);
- `jq` — на Windows: `winget install jqlang.jq`, затем перезапустить терминал.

Если `jq` не установлен — `block-dangerous-bash.sh` и `protect-secrets.sh` будут просто пропускать проверку (fail-open), команда не блокируется. Это безопасно для работы, но защита не сработает. Установи `jq`, чтобы хуки реально фильтровали.

## Хуки

- `block-dangerous-bash.sh` — PreToolUse(Bash): блокирует `rm -rf /`, `mkfs`, `dd of=/dev/*`, fork-bomb, `chmod -R 777 /`.
- `protect-secrets.sh` — PreToolUse(Read|Edit|Write): блокирует доступ к `.env`, `*.pem`, `*.key`, `id_rsa`, `secrets.*`.
- `quality-reminder.sh` — Stop: напоминание про тесты/безопасность/отчёт.

## PowerShell-хуки (актуальная версия, 01.07.2026 — доработаны по мотивам srednoff-os для Codex)

- `hook-lib.ps1` — общая библиотека (dot-source), не хук сама по себе: `Find-SecretSignals` (контентное сканирование секретов: OpenAI/Anthropic/GitHub/AWS/Google ключи, PEM, JWT) + `Write-HookLedger` (audit-журнал).
- `block-dangerous-bash.ps1` — PreToolUse(Bash): блокирует опасные команды (`rm -rf /`, `mkfs`, `dd of=/dev/*`, fork-bomb, `chmod -R 777 /`, `git push --force`, **`git reset --hard`**, **`format C:`**) **и** секреты, вставленные прямо в команду.
- `protect-secrets.ps1` — PreToolUse(Read|Edit|Write|MultiEdit): блокирует доступ к секретным путям (`.env`, `*.pem`, `*.key`, `id_rsa`, `secrets.*`) **и** секреты, которые вот-вот запишутся в обычный файл (контент, не только путь).
- `scan-prompt-secrets.ps1` — **новый**, UserPromptSubmit: блокирует сам промпт, если в нём есть вставленный секрет (до того, как он попадёт хоть куда-то). Контракт подтверждён по офиц. докам (`{"decision":"block","reason":...}`).
- `quality-reminder.ps1` — Stop: напоминание.

**Audit ledger:** все denies/blocks пишутся в `~/.claude/logs/hook-events.jsonl` (timestamp, хук, решение, находки, **sha256 сырого инпута** — не сам секрет). Логируются только сработавшие события, не каждый вызов — иначе журнал раздувается без пользы.
