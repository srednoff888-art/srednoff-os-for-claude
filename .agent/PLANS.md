# PLANS.md — ExecPlan для больших задач Claude

> **Источник истины**: `.claude/rules/60-exec-plans.md`. При конфликте выигрывает `rules/`; при правке одного — проверь и обнови второй.

ExecPlan — это living document, который позволяет вести большую задачу от исследования до production-ready результата.

Используй ExecPlan, когда задача:

- занимает больше 30 минут;
- меняет архитектуру;
- затрагивает БД;
- затрагивает auth/security;
- требует деплоя;
- требует нескольких интеграций;
- имеет высокий риск ошибки;
- требует GitHub research.

## Шаблон ExecPlan

```md
# ExecPlan: <task name>

## Goal
Что должно быть достигнуто.

## User value
Какой бизнес-результат получает пользователь.

## Current state
Что есть сейчас в репозитории: файлы; архитектура; ограничения; зависимости; проблемы.

## Assumptions
-

## Questions for user
Только блокирующие вопросы:
1.

## GitHub research

| Repo | Why relevant | Pattern to adapt | Risk |
|---|---|---|---|
|  |  |  |  |

## Official docs checked
-

## Target architecture
frontend; backend; database; jobs/queues; external APIs; auth; deployment; monitoring.

## Step-by-step implementation

### Step 1
Goal:
Files:
Actions:
Validation:

## Data model / migrations
SQL migration plan.

## API contracts
Request/response types.

## Security model
auth; roles; RLS; validation; secrets; rate limits.

## Testing plan
unit; integration; e2e/manual; regression.

## Rollback plan
Что делать, если деплой сломается.

## Definition of done
- [ ] Code implemented
- [ ] Tests pass
- [ ] Build passes
- [ ] Security reviewed
- [ ] Docs updated
- [ ] Deploy path clear

## Progress log
- [ ] Created plan
- [ ] GitHub checked
- [ ] Architecture approved/assumed
- [ ] Implementation started
- [ ] Tests done
- [ ] Final report sent
```
