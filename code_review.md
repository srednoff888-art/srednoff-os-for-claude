# code_review.md

При review кода проверяй:

## P0 — блокеры

- утечка секретов;
- потеря данных;
- обход авторизации;
- отключение RLS/security;
- production outage risk;
- SQL injection / XSS / SSRF;
- destructive migrations без rollback;
- изменение billing/domain/DNS/payment settings без подтверждения.

## P1 — серьёзные проблемы

- сломанный core-flow;
- отсутствие обработки ошибок;
- race conditions;
- некорректные права доступа;
- нестабильные интеграции;
- отсутствие тестов на критичную логику;
- нарушение API contracts;
- риск зависания job/queue/cron.

## P2 — улучшения

- читаемость;
- дублирование;
- слабая типизация;
- отсутствие логов;
- неоптимальные запросы;
- неясные boundaries между слоями;
- отсутствие документации для нового поведения.

## P3 — косметика

- naming;
- formatting;
- небольшие cleanup-задачи;
- улучшение комментариев.

## Формат ответа

```md
## Code Review

P0:
-

P1:
-

P2:
-

P3:
-

Ship decision:
- SHIP / DO NOT SHIP / SHIP WITH RISKS

Required fixes:
-
```
