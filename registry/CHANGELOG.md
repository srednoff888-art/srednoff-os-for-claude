# CHANGELOG — реестр ядра Claude MD OS

## v1.10 — 2026-07-01 (самоулучшение: рефакторинг нашими же скиллами `refactoring-specialist`/`code-simplification`)
По запросу Ивана «найди в нашей же ОС агенты и скилы для рефакторинга — посмотрим как OS сможет улучшить сама себя». Выбраны `refactoring-specialist`, `refactoring-coach-agent`, `code-simplification`, `quality-cost-skill-kernel` из CORE-300.md; 2 параллельных агента-ревьюера прогнаны против хуков/registry-скриптов и scripts/-инструментов. Применено (только консервативные, поведение-сохраняющие изменения):
- **[HIGH] Устранено реальное расхождение единого источника истины**: `status.ps1`/`status.sh` держали свою НЕЗАВИСИМУЮ копию списка 10 rule-файлов, отдельно от канонического списка в `check-claude-md-os.ps1`/`.sh` — при добавлении нового правила эти два места молча разошлись бы. Вынесено в новые общие файлы `scripts/rule-file-list.ps1`/`.sh` (единственный список), оба скрипта теперь ссылаются на него.
- **Извлечены 2 bash-хелпера в `routing-lib.sh`**: `count_nonempty_lines()` (повторявшийся 4х в `validate-catalog-format.sh` + 3х в `audit-registry.sh` идиома "grep -c с защитой от off-by-one на пустой строке" — заодно исправлен скрытый мелкий баг: `total_records`/`external_records`/`installed_records` в `audit-registry.sh` не имели этой защиты вовсе) и `bash_arr_to_json()` (4х повторявшийся в `domain-router.sh` паттерн "массив bash → JSON или `[]`").
- **`select-skills.sh`**: `domain_tags_json` вычислялся дважды за один запуск (в блоке логирования и в блоке `--json`), когда оба флага активны одновременно — вычисляется один раз, переиспользуется.
- Косметика (нулевой риск): выравнивание ключей hashtable в `audit-registry.ps1`, единственный русскоязычный комментарий в `init-claude-project.ps1` переведён на английский (весь остальной файл — на английском).
- **Отклонено предложение агента** (осознанно, не вслепую): переход `Add-Tag` в `gen-profile-lock.ps1` на `HashSet` — HashSet не гарантирует порядок вставки, а порядок тегов в выводе "Dominant tags" значим; List с ручной проверкой `Contains` оставлен как есть (перф на ~20 тегах не имеет значения).
- Полная регрессия после рефакторинга: **evals 33/33** на PowerShell и bash, hook-canary 3/3, registry-audit 0 дублей, catalog-format 0 проблем. По пути поймана и диагностирована ложная тревога: `run-evals.sh` периодически подвисал на 200+с в затянувшейся Windows/Cygwin-сессии из-за накопившихся зависших дочерних bash-процессов от предыдущих `timeout`-тестов (подтверждено: та же логика мгновенно и корректно отрабатывала в изоляции; после очистки зависших процессов — снова стабильные 33/33). Не баг рефакторинга, артефакт тестовой среды.

## v1.9 — 2026-07-01 (самоаудит: 3 параллельных ревью нашими же скиллами из CORE-300.md)
По запросу Ивана выбраны канонические записи каталога (`debugger`, `security-auditor`, `code-reviewer`/`architect-reviewer`) и прогнаны через них наш собственный код: 3 независимых агента-ревьюера (security-auditor, debugger, architect-reviewer) проверили хуки, роутинг-скрипты и структуру правил. Найдено и исправлено:
- **[CRITICAL] Кросс-платформенное расхождение в `audit-registry.ps1`**: паттерн `EXT\b` не имел ЛЕВОЙ границы слова (в отличие от bash-версии, где граница была честно захардкожена вручную из-за отсутствия `\b` в POSIX ERE) — матчился внутри "Next.js"/"context"/"text". Плюс отдельный баг: `-match` в PowerShell регистронезависим по умолчанию, из-за чего `VOLT`/`WSH` ложно матчились внутри реальных имён скиллов (`voltagent:create-voltagent`, `wshuyi:...`). Оба фикса дали идеальное совпадение чисел: 142 installed / 574 external на обеих платформах (было 578 на Windows).
- **[HIGH] Обходы `rm -rf` в `block-dangerous-bash.ps1/.sh`**: `rm -rf /*` и `rm -rf ./*` (wildcard-обёртка root/cwd) обходили старый паттерн из-за требования пробела/конца-строки сразу после цели; long-form `--recursive --force` и реверс `-fr` не матчились вовсе. `git push -f` (короткий флаг) не ловился — только `--force`. Все фиксы протестированы против 13 кейсов (обходы + легитимные `rm -rf node_modules`/`git push origin main`) — 13/13 корректно на обеих платформах, ложных срабатываний нет.
- **[MEDIUM] Пробелы в секрет-паттернах**: добавлены `gcp_service_account_key` (по полю `private_key_id`, 40-hex — GCP JSON-ключи не ловились как единый multi-line PEM) и `db_connection_string` (postgres/mysql/mongodb/redis/amqp URI с паролем). Добавлены в постоянный regression: `secret-pattern-fixtures.json` (6→9 кейсов).
- **[MEDIUM] Тихое проглатывание ошибки в `domain-router.ps1/.sh`**: если `CORE-300.md` отсутствует/сломан, раньше отдавался пустой `skill_picks` неотличимо от «ничего не подошло». Теперь отдельное поле `catalog_warning` явно называет причину.
- **[CRITICAL, по дизайну] Тихий fail-open в bash-хуках при отсутствии `jq`**: не баг логики, а невидимость — `doctor.sh` теперь имеет отдельную явную проверку `jq-dependency` вместо неясного generic-фейла hook-canary.
- **Расширен matcher хуков**: `Read|Edit|Write|MultiEdit` → `+NotebookEdit` в обоих `settings*.example.json` (был пробел покрытия).
- **[HIGH, архитектура] Тройное дублирование правил** (`CLAUDE.md`/`.claude/rules/`/`.agent/*.md`) без единого источника истины — добавлены явные cross-reference пометки «канонический источник ↔ развёрнутая версия» в 5 парах файлов (quality-gate, connectors, github-research, exec-plans, user-briefing), без полного слияния (риск/выгода рефакторинга признан несоразмерным в рамках этой сессии).
- **Правило failure-lifecycle для ПЕРВИЧНОГО агента** добавлено в `60-exec-plans.md` (раньше `90-subagent-contract.md` требовал disposition только от делегированных вызовов, не от самого себя).
- Полная регрессия после всех фиксов: **evals 33/33** (было 30, +3 новых secret-фикстуры), hook-canary 3/3, registry-audit 0 дублей — на PowerShell и bash одинаково.

## v1.8 — 2026-07-01 (session_id корреляция + финальный disposition для сабагентов)
- **Исследован `paperclipai/paperclip`** (MIT, 72k★, легитимный, активный) по запросу Ивана. Вывод: это платформа оркестрации КОМАНД автономных агентов (org-chart, бюджеты, approval gates, сервер+БД+UI) — другой продукт для другого сценария использования (флот агентов 24/7 vs один оператор). Полную оркестрацию сознательно НЕ забрали — несоразмерный рост инфраструктуры под несуществующую у Ивана задачу (явное решение Ивана после обсуждения tradeoff).
- **Взято адаптированной концепцией (не кодом), 2 пункта:**
  1. **session_id корреляция в audit-ledger** — `Write-HookLedger`/`write_hook_ledger` теперь извлекают `session_id` (подтверждено: присутствует на верхнем уровне JSON всех 4 типов хуков по офиц. докам Claude Code) и пишут в `hook-events.jsonl`; то же добавлено в `hook-liveness.jsonl` (session-start-hook.ps1/.sh). Позволяет grep'ать все события одной сессии. Протестировано: с session_id → пишется корректно; без него → `null`, хук не ломается (backward-compatible).
  2. **Финальный disposition для сабагентов** (rule `90-subagent-contract.md`) — каждый делегированный вызов (Agent/Task/фоновый Bash) обязан завершиться явным исходом (`done`/`blocked`/`deferred`/`failed`), зафиксированным в ответе пользователю — не обрываться молча.
- Полная регрессия после изменений: `doctor.ps1` и `doctor.sh` — **evals 30/30, hook-canary 3/3, registry-audit 0 дублей, catalog-format 0 проблем** на обеих платформах.

## v1.7 — 2026-07-01 (полный паритет Linux/macOS: bash-порты всех хуков и скриптов)
- **Хуки:** `hook-lib.sh` (bash-аналог `hook-lib.ps1` — 13 секрет-паттернов через `grep -P`, ledger через `jq`+`sha256sum`); `block-dangerous-bash.sh`/`protect-secrets.sh` доведены до паритета с `.ps1` (были устаревшие, без content-based секрет-скана и части опасных паттернов) + **новый** `scan-prompt-secrets.sh` (ранее существовал только в PowerShell). Все 3 функционально протестированы canary-инпутами.
- **Реестр:** `routing-lib.sh`, `mode-router.sh`, `domain-router.sh`, `select-skills.sh`, `audit-registry.sh`, `validate-catalog-format.sh` — полные bash-порты. Каталог парсится POSIX-совместимым awk (без gawk-специфичных расширений — работает и под mawk), без JSON-кэша (не нужен: awk парсит 2027 записей за ~0.24с, в разы быстрее PS-плоского-файлового парсинга).
- **Скрипты:** `status.sh`, `gen-profile-lock.sh` (сразу generic — без хардкода Ивана, в отличие от `.ps1`-версии), `apply-os-all.sh`, `run-evals.sh`, `doctor.sh` — полные bash-порты, весь `doctor.sh` (structure+registry-audit+catalog-format+version-control+hook-canary+evals+fix-safe) протестирован end-to-end.
- **Глобальные скрипты:** `scripts/global/{session-start-hook,statusline}.{ps1,sh}` — вынесены в шаблон как generic first-class файлы (были только в приватных `~/.claude/auto-bootstrap.ps1`/`srednoff-os-statusline.ps1`, привязанных к конкретной машине). Обе версии читают `SREDNOFF_OS_ROOT` вместо хардкода пути.
- **Найден и исправлен реальный баг** (тестированием, не инспекцией): `init-claude-project.ps1`/`.sh` копировали `.git/*` САМОГО шаблона в целевой проект (шаблон получил git в этой же сессии, экспорт-фильтр не исключал `.git`) — теперь исключён явно в обеих версиях. Проверено: ни один реальный проект Ивана не задет (баг не успел сработать до фикса).
- **Найдена и устранена утечка приватных данных**, уже попавшая в публикованный GitHub-репозиторий: одно приватное бренд-имя оставалось в `CORE-300.md` (запись-алиас #271) и в regex-эвристике `gen-profile-lock.ps1` — предыдущий редакшн ловил только составное имя папки, не отдельное слово. Исправлено фикс-коммитом (без переписывания git-истории — явное решение Ивана, 0 клонов/форков на момент утечки).
- **30/30 evals проходят одинаково на `.ps1` и `.sh`** (один и тот же набор фикстур, независимая от платформы корректность).
- `settings.example.json` (bash-версия) была неполной — не хватало `UserPromptSubmit`-хука; добавлен, теперь паритет с `settings.windows.example.json`.

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
