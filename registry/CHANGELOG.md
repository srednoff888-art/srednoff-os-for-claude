# CHANGELOG — реестр ядра Claude MD OS

## v1.6 — 2026-07-01 (закрытие дыр из враждебного критического ревью)
- **Git-версионирование:** `registry/` и `templates/claude-md-os/` теперь git-репозитории с baseline-коммитом. **Автокоммит встроен в `doctor.ps1`** (не полагается на память — коммитит сам при каждом прогоне doctor). Закрывает «0 бэкапов, 0 отката».
- **Re-tagging:** доля `[general]` (тег-заглушка) среди новых 1526 записей — **30.7% → 7.5%** (353 записи точечно перетегированы по org-контексту + расширенным keyword-правилам, покрывающим ранее пропущенные теги словаря: quality/arch/product/pm/ops/meta/api/compliance/business/hr/git/shell).
- **Hook liveness ledger:** `auto-bootstrap.ps1` теперь безусловно логирует каждый вызов (`~/.claude/logs/hook-liveness.jsonl`) с полем `source` — впервые появляется способ независимо от автора кода проверить, срабатывал ли хук через реальный runtime (`source=startup/resume/clear/compact`), а не только через ручной synthetic-тест.
- **Hook canary test:** `doctor.ps1` теперь скармливает каждому активному хуку заведомо-опасный синтетический вход и требует deny/block — превращает «тихий fail-open при поломке» в «доктор кричит FAIL при поломке».
- **Секрет-паттерны проверены против РЕАЛЬНОГО корпуса** (не собственных примеров): Stripe TP/FP из тест-сьюта самого gitleaks, AWS-ключ из официальных доков AWS, GitHub/npm по задокументированным форматам. Закреплено как `evals/secret-pattern-fixtures.json` (6 кейсов) — **evals теперь 24→30**.
- **CockroachDB broken-хук:** предпринята повторная, более серьёзная попытка через `claude plugin list` (реальная CLI-команда) — подтверждено окончательно: плагин НЕ управляется через Claude Code CLI, это Cowork-коннектор вне досягаемости. Не «сдался», а исчерпал реальные пути.
- Исправлен PS5.1-баг (native git stderr + `$ErrorActionPreference=Stop` → ложный terminating error) в новом `Invoke-AutoCommit`.
- **Честно НЕ закрыто (не подделывается):** нулевой прод-стаж системы (построена и проверена в рамках одной сессии); statusline-рендеринг в Cowork UI по-прежнему не подтверждён независимо от автора.

## v1.5 — 2026-07-01 (проверка di-sukharev/vibe + масштабирование каталога до 2000+)
- **di-sukharev/vibe** (283★, Apache 2.0, реальные тесты, DO+Yandex Cloud деплой) проверен и добавлен как ДВЕ записи (2027/2028) — full-stack project-starter (не skill/agent). Вплетён в `product-builder` skill, чтобы реально всплывал при старте нового full-stack проекта.
- **Масштабирование: 501 → 2027 записей.** Источники: VoltAgent/awesome-agent-skills (1174 записи, официальные команды Vercel/Stripe/Cloudflare/Netlify/Supabase/Datadog/NVIDIA/Microsoft/etc + community — реально проверено `gh repo view`/README, не выдумано), srednoff-os собственных 306 named-скиллов Ивана, wshobson остаток 52. Генерация через программный скрипт (`expand_catalog.py`) с дедупом против существующих 501 + внутри новой партии — **0 дубликатов на выходе** (проверено `audit-registry.ps1`).
- **Найдены и исправлены 2 бага скоринга тегов** при генерации: `\bdefi\b` матчил подстроку внутри "de**fi**nitions"; bare `crypto` путал криптографию с крипто-трейдингом (`Cryptographic key management` ошибочно получал [trading]). Исправлено, пере-проверено на конкретных кейсах.
- **Тест производительности селектора на 2027 записях (явный вопрос из задания):** до правок — 5.6с/вызов. Найдена причина: НЕ парсинг файла, а `Add-Member` в PowerShell-пайплайне на 2000+ итераций (известный антипаттерн) + баг `@(List[object])` в интерпретаторе PS (`PSToObjectArrayBinder` ArgumentException). Исправлено: (1) JSON-кэш каталога (`core-catalog-index.json`, инвалидация по mtime CORE-300.md), (2) убран `Add-Member` из цикла релевантности (HashSet+List<T> вместо pipeline), (3) убран `@()` вокруг типизированных коллекций. **Результат: ~2.4-3.1с (было 5.6с), корректность выбора сохранена** (специфичные скиллы по-прежнему побеждают generic-meta).
- Убраны хардкоженные числа «500 скиллов»/«~300 скиллов» из CLAUDE.md/rule70/auto-bootstrap.ps1 (протухали при каждом росте каталога) → ссылка на `version.json` как источник истины.
- Полная проверка после всех правок: `validate-catalog-format.ps1` 0 проблем, `audit-registry.ps1` 0 дубликатов, `run-evals.ps1` 24/24, все 8 проектов — PROFILE.lock перегенерирован.

## v1.4.2 — 2026-07-01 (честный 4-угольный аудит + закрытие найденных пробелов)
- **Аудит (инженерия/security/web-design/SEO), кратко:**
  - Инженерия: PS-only (ок для среды Ивана), нет CI-автозапуска evals (нужен ручной `doctor -RunEvals`), CORE-300.md — regex-парсинг markdown как псевдо-БД без schema-валидации (**исправлено** → `validate-catalog-format.ps1`).
  - Security: хуки были fail-open по дизайну (осознанный трейд-офф для personal tooling, не баг) + секрет-паттерны — только 7 провайдеров (**исправлено** → +Stripe/Slack/Twilio/SendGrid/npm, проверено по gitleaks.toml).
  - Web-design: не было именного visual-regression/a11y-QA скилла (**исправлено** → Дополнение E).
  - SEO: подозревался пробел (Google AI Mode/zero-click/GEO) — **проверено research'ем, пробела НЕТ**, уже покрыто каноном `seo-geo`.
- **Дополнение E:** `accessibility-agents` (348★ MIT, 11 WCAG 2.2 AA специалистов), `playwright-skill` (2847★ MIT) — оба проверены `gh repo view` перед добавлением. **501 запись** (было 499).
- **`validate-catalog-format.ps1`** — новый: ловит записи, которые молча выпали бы из парсинга (0 проблем сейчас). Подключён в `doctor.ps1`.
- **Секрет-паттерны:** +stripe_key, +slack_token/webhook, +twilio_key, +sendgrid_key, +npm_token в `hook-lib.ps1` (Supabase/Vercel сознательно не добавлены — нет задокументированного фикс-префикса; Supabase service-role — JWT, уже ловится).
- **Хуки активированы** во всех 8 проектов (`settings.json` скопирован из example, с explicit-одобрения Ивана) — защита теперь реально работает, не только "готова к включению".

## v1.4.1 — 2026-07-01 (устранение рисков)
- **Данные:** `audit-registry.ps1` нашёл 4 реальных дубликата имён (не только известный `zoominfo:tam-sizer`, но и `vanta:test-remediation`, `seo-content-brief`, `quant-analyst`) — G2/G3-варианты переименованы в `*-full` (различимы для селектора), явный дубль `seo-content-brief` #388 удалён. **500 → 499 записей.** 0 дубликатов после фикса.
- **Evals:** +`mode-fixtures.json` (7 кейсов, включая явную проверку — кириллическое «турбо» НЕ должно триггерить turbo, только буквальное английское слово) + инвариант квот (`lean`-бюджет никогда не выбирает G3) + домены legal/finance/infra/design добавлены в domain-fixtures. **24/24 evals проходят.**
- **Usage-log:** `select-skills.ps1` теперь по умолчанию пишет `~/.claude/logs/selector-usage.jsonl` (какие скиллы реально запрашивались) — закрывает P1 "каталог используется вслепую". `-NoLog` для синтетических/eval-вызовов.
- **CockroachDB broken-хук:** диагностирован как Cowork-коннектор (не CLI-плагин, не в `~/.claude/`) — подтверждено non-blocking (все Write за сессию прошли успешно несмотря на stderr), инструкция отключения дана пользователю (UI Cowork, не файл).
- `doctor.ps1` теперь всегда прогоняет `audit-registry.ps1` (дёшево, без сети).

## v1.4 — 2026-07-01 (заимствования из srednoff-os для Codex, 10 пунктов согласованы построчно)
- **Хуки (Пакет A):** `hook-lib.ps1` (общая lib: content-based секрет-скан + privacy-safe audit ledger `~/.claude/logs/hook-events.jsonl`, только по триггерам); `block-dangerous-bash.ps1`/`protect-secrets.ps1` теперь сканируют СОДЕРЖИМОЕ (не только пути/паттерны команд) на реальные секреты (OpenAI/Anthropic/GitHub/AWS/Google ключи, PEM, JWT) + новые паттерны (`git reset --hard`, `format C:`); новый хук `scan-prompt-secrets.ps1` на `UserPromptSubmit` (контракт подтверждён по офиц. докам: `{"decision":"block","reason":...}`).
- **Роутинг (Пакет B):** `registry/routing-lib.ps1` (общие функции), `mode-router.ps1` (normal/deep/turbo, TURBO только по буквальному слову), `domain-router.ps1` (динамический — по брифу ЗАДАЧИ, не только по стеку проекта — вопросы/skill-picks/validation-gates), `select-skills.ps1` (ROI-селектор с budget-квотами G1/G2/G3, парсит реальный CORE-300.md). Найден и исправлен баг: сортировка по номеру каталога давала generic-[meta]-скиллам приоритет над специфичными — исправлено скорингом релевантности.
- **Health/evals (Пакет C):** `version.json`, `scripts/status.ps1` (единый status one-liner), `scripts/run-evals.ps1` + `registry/evals/*.json` (12 фикстур domain+selector), `scripts/doctor.ps1` (`-RunEvals -FixSafe`, с пост-фикс пере-проверкой — честно отражает состояние после починки, не до).
- **Доки (Пакет D):** UI/3D source ranking checklist в `CAPABILITY-INDEX.md`; `EXPORT-HYGIENE.md` (что не публиковать, если OS станет шаримой).
- Источник: `github.com/srednoff888-art/srednoff-os` (тот же автор, для Codex) — портированы КОНЦЕПЦИИ, не код (другой формат/агент). Одобрено построчно перед реализацией.

## v1.3 — 2026-06-28 (Дополнение C)
+18 (483–500): официальный маркетплейс Anthropic (`ANTH-OFF`, приоритет №1) — claude-plugins-official / anthropics/skills / knowledge-work (sales/legal/finance/data); observability/eval/cost (закрыт P1-пробел) — agent-observability, otel-tracing-setup, llm-eval-unit, three-layer-eval-suite, guardrails. Теги `[eval][observability]`. **Каталог = 500.**

## v1.2 — 2026-06-28 (Дополнение B)
+63 (420–482): tool-эксперты 0xfurai (redis/kafka/playwright/prisma/flyway…), e-com (Shopify-AI-Toolkit/claude-marketing: Klaviyo/GA4/Looker), оркестрация/рой (claude-flow/metaswarm/ccswarm/ralph). Теги `[ecom][orchestration][jobs][messaging]`.

## v1.1 — 2026-06-28 (Дополнение A)
+69 (351–419): 3D web/WebGL (freshtechbro: three.js/R3F/babylon/spline), анимация (GSAP/Framer/Lottie/Rive), web-дизайн, SEO programmatic/GEO, Amazon (nexscope + SP-API). Теги `[3d][webgl][animation][amazon][desktop]`.

## v1.0 — 2026-06-28 (ядро)
350 записей в 3 группах (G1/G2/G3). Источники: wshobson (194/158), VoltAgent (150+), INST/ANTH. + SELECTION-PROTOCOL, INSTALL-SOURCES, анти-overlap.

## Принципы (неизменны)
- **Принцип №1**: качество первично, экономия — tie-breaker.
- Один канон на способность → `CAPABILITY-INDEX.md`.
- Внешнее = `unvetted` до github-research + лицензии + пиннинга.
- Модель под требуемое качество → `80-model-routing.md`.

## Политика версионирования
Новые записи = новое «Дополнение» в `CORE-300.md` + строка сюда. **Раз в квартал:** staleness-check внешних (репо живой? коммит запиннен?) + чистка по факту использования (P1: USAGE-LOG). Следующая ревизия: ~2026-09-28.
