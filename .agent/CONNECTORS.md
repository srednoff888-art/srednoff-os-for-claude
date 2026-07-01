# CONNECTORS.md — как Claude должен использовать MCP/коннекторы

Цель MCP/коннекторов — дать Claude факты и действия, а не просто "подумать".

## Общий алгоритм

1. Определи, какие внешние системы реально нужны.
2. Получи только нужный минимум данных.
3. Перед destructive действиями запроси подтверждение.
4. После действия проверь результат.
5. В отчёте укажи, какой коннектор использовался и зачем.

## GitHub
Чтение репозитория, поиск похожих проектов, анализ issues/PR, ветки, PR, code review, CI logs.

## Vercel
Деплой, логи build/runtime, env vars, preview URL, production diagnostics.
Нельзя без подтверждения: менять production env; удалять проект; менять домены; rollback production; менять billing/teams.

## Supabase
Schema inspection, migrations, RLS, auth, storage, edge functions, logs.
Нельзя без подтверждения: DROP; массовый DELETE; отключение RLS; изменение auth policies; irreversible migrations.

## Figma / Canva
UI references, design systems, assets, visual direction.

## Gmail / Calendar / Contacts
Только для задач коммуникации, встреч, follow-up, отправки писем или поиска контактов.

## Anthropic / OpenAI / AI agents
Генерация черновиков, классификация, сравнение вариантов, code review, извлечение данных, проверка качества.
Не используй AI там, где лучше обычный код, SQL, regex, cron или deterministic parser.
