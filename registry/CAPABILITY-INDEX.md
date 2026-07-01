# CAPABILITY-INDEX — один канон на способность

Замена ручной анти-overlap карты, которая гниёт с ростом каталога. При выборе бери **КАНОН**; альтернативу — только если канон недоступен/не подходит. Правило: официальное (`ANTH-OFF`/`INST`) > community при равном качестве (Принцип №1).

| Способность | Канон | Альтернатива (не вместе) |
|---|---|---|
| code review (diff) | `anthropic:code-review` / INST `code-review` | WSH `code-reviewer` |
| глубокое облачное ревью | INST `code-review ultra` | — |
| отладка | `debugger` | `error-detective` |
| тесты (написать) | `test-automator` | `tdd-orchestrator` (цикл) · `qa-expert` (стратегия) |
| E2E браузер | `playwright-expert` | `cypress-expert` · `e2e-testing-patterns` (skill) |
| Next.js | `nextjs-developer` / `vercel:nextjs` | `nextjs-app-router-patterns` (skill) |
| UI/качество фронта | `ui-ux-pro-max` (INST) + `modern-web-design` | `frontend-design-toolkit` (за MCP/трюки) |
| 3D движок | ОДИН: `threejs-webgl` / `babylonjs-engine` / `playcanvas-engine` | — |
| 3D в React | `react-three-fiber` (+`r3f-skills`) | — |
| анимация (React) | `motion-framer` | `gsap-scrolltrigger` (vanilla/scroll) · `react-spring` (физика) |
| SEO аудит | INST `seo` / `searchfit-seo:seo-audit` | `claude-seo` (внешн., если шире) |
| SEO живые данные | `dataforseo` | — |
| Amazon данные/ресёрч | `merchant_amazon_*` (DataForSEO) + `nexscope` | — |
| Amazon кабинет (деньги) | SP-API MCP `amazon-seller-mcp` (с подтверждением) | DataDoe/agentcentral (managed) |
| оркестрация (встроенная) | `multi-agent-coordinator` | `codebase-orchestrator` |
| оркестрация (внешний рой) | `claude-flow` (с подтверждением) | `metaswarm`/`ccswarm` |
| наблюдаемость | `otel-tracing-setup` | `agent-observability` · `datadog-llm-observability` (managed) |
| eval | `llm-eval-unit` (быстро) | `three-layer-eval-suite` (полно) |
| диаграммы | `mermaid-expert` | `c4-*` (архитектура) |
| docs из кода | `readme-generator`/`openapi-spec-generation`/ADR | `docs-architect` (нарратив) |
| память/контекст | `context-manager` (сессия) | `productivity:memory-management` (долгая) · файловая memory |
| язык целиком | `python-pro`/`typescript-pro`/… | — |
| конкретный инструмент | `<tool>-expert` (redis/kafka/prisma/playwright) | — (не вместо язык-про) |
| sales/legal/finance/data | `knowledge-work:*` (ANTH-OFF) | community-аналоги |

Связка: `40-quality-gate` (ручной чеклист) ↔ `llm-eval-unit`/`three-layer-eval-suite` (автоматизация тех же проверок).

## UI/3D source ranking checklist (v1.4, ported concept from srednoff-os)

Перед принятием внешнего UI-кита/3D-ассета/компонента (не агента — визуального источника) сравнивай в этом порядке приоритета:
1. **Уже есть в проекте** — используй существующий компонент/паттерн, если подходит.
2. **Stack-native, документированный, низкий риск** — прежде чем визуально эффектный, но незнакомый источник.
3. Для UI: shadcn registry → Magic UI / 21st.dev (via Magic MCP) → Aceternity/Origin UI/React Bits → Figma/Canva-макет.
4. Для 3D: `model-viewer` (проще всего) → Three.js/R3F (см. каталог: `threejs-webgl`, `react-three-fiber`, `r3f-skills`) → Babylon.js → готовые ассеты (Poly Haven, ambientCG, Sketchfab) → Spline (no-code).

Перед adoption любого внешнего компонента/ассета — обязательный чек (не пропускать):
- лицензия совместима?
- вес зависимостей оправдан (не тянет ли лишний рантайм ради одной анимации)?
- accessibility не хуже, чем нативная альтернатива?
- perf-бюджет (особенно 3D — canvas non-blank, mobile-fallback, asset-size)?
- security/provenance — откуда код, кто автор, нет ли обфускации?
- визуально подходит проекту (не "AI slop" — избыточные градиенты/эффекты без функции)?

`domain-router.ps1 -Brief "<задача>"` уже задаёт нужные уточняющие вопросы для UI/3D-доменов (target user/impression, viewer vs configurator vs decorative, perf-бюджет) — не переспрашивай то же самое вручную.
