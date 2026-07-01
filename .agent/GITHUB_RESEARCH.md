# GITHUB_RESEARCH.md — обязательный протокол проверки GitHub

> **Источник истины**: `.claude/rules/10-github-research.md`. При конфликте выигрывает `rules/`; при правке одного — проверь и обнови второй.

Используй этот документ каждый раз, когда задача требует внешнего инженерного опыта.

## Когда запускать

Перед: выбором архитектуры; выбором библиотеки; созданием бота/парсера/агента/сайта/SaaS/dashboard; интеграцией с API; настройкой деплоя; сложным багфиксом; refactor; security-sensitive изменениями.

## Запросы для поиска

```text
<technology> <feature> example
<technology> <problem> GitHub
<framework> starter <feature>
<integration> boilerplate
<library> production example
<error message> GitHub issue
```

Примеры:

```text
telegram bot supabase vercel github
nextjs supabase auth rls starter
anthropic claude code skill github
claude code hooks example github
mcp server typescript github
vercel cron supabase edge functions github
```

## Фильтр качества

Хороший репозиторий: активно обновлялся 6-12 мес; понятный README; есть лицензия; здоровые issues/PR; не demo-spam; есть тесты/production-подход; совместим со стеком.

Плохой: нет лицензии; старый последний коммит; много critical issues; нет документации; hardcoded secrets; устаревшие версии; копипаста без тестов.

## Таблица сравнения

```md
| Repo | Stars | Last update | License | Stack | Useful pattern | Risks |
|---|---:|---|---|---|---|---|
|  |  |  |  |  |  |  |
```

## Решение после анализа

```md
## Decision
Adopt:
Adapt:
Avoid:
Build ourselves:
Why:
```

## Правило лицензий

Не копировать код, если: лицензия отсутствует; несовместима; непонятно происхождение. Идеи и паттерны использовать можно, если это не прямое копирование.
