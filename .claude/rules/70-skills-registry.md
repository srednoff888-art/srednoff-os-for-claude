# 70-skills-registry.md

> 🔴 **ШАГ 0 — ДО любого инструмента, грепа и ответа:** если в проекте есть `.claude/PROFILE.lock.md` — **прочитай его ПЕРВЫМ**. Это не опционально. Компактный выбор уже вшит в начало `CLAUDE.md` (блок `SREDNOFF-OS:SELECTION`) → он уже в контексте; полный список и G3-по-запросу — в `PROFILE.lock.md`. Не грепай `CORE-300.md`, пока есть lock.
>
> **Это правило теперь принудительно, не только на честном слове.** Реальный кейс (02.07.2026, `my-app`): OS была полностью развёрнута, баннер `SREDNOFF OS — ACTIVE` + список тегов/скиллов были на первых 6 строках `CLAUDE.md` — и агент всё равно ни разу не прочитал `PROFILE.lock.md` и не вызвал `Skill()`. Вывод: пассивный текст в контексте — не гарантия действия, даже на самом видном месте. Поэтому пара хуков `require-profile-lock-read` (PreToolUse Edit/Write/MultiEdit) + `mark-profile-lock-read` (PostToolUse Read) **денят первый Edit/Write в сессии**, пока `PROFILE.lock.md` реально не прочитан — один раз за сессию, дальше не мешает. Это opt-in хук (см. `.claude/settings.example.json`), но именно он превращает эту инструкцию из совета в гейт.

Есть глобальное ядро скиллов/агентов (3 группы по расходу токенов; точное число записей — см. `~/.claude/registry/version.json`, растёт со временем):
`~/.claude/registry/CORE-300.md` (каталог) + `SELECTION-PROTOCOL.md` + `INSTALL-SOURCES.md`.

**Принцип №1 — качество решения превыше всего; экономия — tie-breaker.**
Цель системы — КАЧЕСТВЕННО решить задачу. Скиллы/агенты/модель выбирай по тому, что нужно для нужного качества, НЕ чтобы сэкономить. Если есть путь дешевле при ТОМ ЖЕ качестве — бери его. Никогда не жертвуй качеством ради токенов. Группы G1/G2/G3 = «сколько мощности реально требует задача», а не «бери дешёвое»: бери минимально достаточную для нужного качества — и не ниже.
Модель под задачу по тому же принципу: детерминированное/простое → Haiku; экспертная работа → Sonnet; сложное рассуждение/аудит/архитектура/оркестрация → Opus. Не занижай модель, если задача требует рассуждения.

**НЕ грузи каталог целиком в контекст.** При старте работы в проекте:

1. Классифицируй проект → 1–4 доминирующих доменных тега (см. протокол).
2. `grep` `CORE-300.md` по этим тегам, возьми имена.
3. GROUP 1 (экономят/нейтральны) — бери щедро по тегам + универсальные мета.
4. GROUP 2 (≈ по расходу) — 3–7 точечно под стек.
5. GROUP 3 (дорого) — НЕ подключай заранее; зови под явную задачу и предупреждай о расходе.
6. Соблюдай анти-overlap карту (низ `CORE-300.md`): один канон на способность.
7. Зафиксируй выбор 1 строкой в отчёте/ExecPlan.

Команда выбора:
```bash
grep -E "\[web\]|\[ai\]" ~/.claude/registry/CORE-300.md
```
```powershell
Select-String -Path "$env:USERPROFILE\.claude\registry\CORE-300.md" -Pattern "\[web\]|\[ai\]"
```

## PROFILE.lock (кэш выбора — экономия контекста)
Если в проекте есть `.claude/PROFILE.lock.md` — **грузи его вместо грепа** CORE-300 (это стартовый набор под стек). Нет файла → сгенерируй:
```powershell
& "$env:USERPROFILE\.claude\templates\claude-md-os\scripts\gen-profile-lock.ps1" .
```
Lock — стартовая точка, не догма: под конкретную задачу можно звать любую запись из CORE-300 (Принцип №1).

## Динамический роутинг (per-задача, не только per-проект) — v1.4

Перед существенной работой (не мелкой правкой), особенно если задача может выходить за рамки статичного `PROFILE.lock` (напр. 3D-задача в web-проекте):
```powershell
powershell -NoProfile -File "$env:USERPROFILE\.claude\registry\mode-router.ps1" -Brief "<задача>"
powershell -NoProfile -File "$env:USERPROFILE\.claude\registry\domain-router.ps1" -ProjectPath "." -Brief "<задача>"
```
`mode-router` — 5 quality-режимов (v1.15, `~/.claude/registry/quality-modes.json`): `fast`(lean/8, мелкие правки) → `standard`(balanced/16, обычная работа) → `production`(deep/24, launch/deploy/SEO/growth/mobile/3D) → `critical`(deep/32, security/auth/payments/миграции БД) → `turbo`(turbo/48, **только по буквальному слову TURBO**, синонимы типа «максимально»/«не экономь» дают `production`, не `turbo`). Каждый режим также отдаёт `legacy_mode` (normal/deep/turbo) для обратной совместимости. `domain-router` — домены задачи + уточняющие вопросы (только для UI/3D/SEO/Amazon, не для всего) + канонические скиллы + validation gates. Точечный ROI-выбор из каталога:
```powershell
powershell -NoProfile -File "$env:USERPROFILE\.claude\registry\select-skills.ps1" -Brief "<задача>" -Budget balanced -Max 16
```
Health-check: `powershell -NoProfile -File "$env:USERPROFILE\.claude\templates\claude-md-os\scripts\doctor.ps1" -ProjectPath "." -RunEvals -FixSafe`.

**UI/3D/design/growth source selection (v1.16)** — перед выбором внешней UI-библиотеки, 3D-ассета, компонент-маркетплейса или design-коннектора прогони ranker вместо выбора источника по памяти:
```powershell
powershell -NoProfile -File "$env:USERPROFILE\.claude\registry\source-ranker.ps1" -Brief "<задача>" -Max 8
```
Возвращает ранжированный список с `score`/`risk`/`license`/`gates` из `registry/design-source-registry.json` (17 источников: shadcn, 21st.dev, Three.js, react-three-fiber, Sketchfab и др.) — `gates` явно перечисляет, что нужно проверить (лицензия, provenance, accessibility, размер ассета) перед копированием. Это дополняет, не заменяет, верификационный гейт ниже — source-ranker покрывает конкретно готовые UI/3D/design источники, github-research — произвольный внешний код/паттерны.

## Верификационный гейт для внешних агентов (supply-chain)
- **Реально доступны без установки только `INST`/`ANTH`.** Всё остальное (`WSH/VOLT/FTB/GH/EXT`) — **по умолчанию `unvetted`**, звёзды ≠ безопасность/качество/лицензия.
- **Никакого авто-install.** Перед ПЕРВЫМ использованием внешнего агента: github-research (лицензия, дата последнего коммита, беглый скан на вредоносное/секреты), затем **пиннинг коммита/тега**. Приоритет официальным (Anthropic/Vercel/Stripe/Shopify) над случайным community.
- **Swarm/автономные фреймворки** (claude-flow, metaswarm, ccswarm, ralph…) делают автономные правки → ставить и запускать **только с явным подтверждением Ивана** (50-security.md).
- Внешний агент работает по least-privilege: не давать доступ к секретам/`.env`.
