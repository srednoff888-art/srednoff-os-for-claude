# INSTALL-SOURCES — откуда ставить внешние агенты/скиллы

Большинство записей `CORE-300.md` помечены `INST`/`ANTH` — **уже доступны**, ставить ничего не нужно. Внешние (`WSH`, `VOLT`) ставятся только когда профиль проекта реально их требует.

## SREDNOFF — Ivan'а собственный sibling-репозиторий (тот же автор, MIT, vetted=true)
Источник: [srednoff888-art/srednoff-os](https://github.com/srednoff888-art/srednoff-os) — Codex-версия
этой же OS. Записи `SREDNOFF` — не unvetted-discovery как WSH/VOLT/GH: это Иванова же работа под MIT,
без отдельного лицензионного ревью (verification gate rule 70 её не требует для `SREDNOFF`, только
для внешних supply-chain источников). 303 скилла из `.codex/skills/` этого репо адаптированы под
Claude Code (текст: `Codex`→`Claude Code`, пути `.codex/`→`.claude/`) и лежат в
`templates/claude-md-os/skills-library/<name>/SKILL.md` — НЕ грузятся автоматически. Уже
**установлены**, но не **активированы**: `gen-profile-lock.ps1/.sh` при генерации PROFILE.lock
копирует до 20 тег-совпадающих скиллов из `skills-library/` в `.claude/skills/` проекта (жёсткий
кап — ~100 токенов на скилл на старте сессии Claude Code, 303 скилла целиком = 30k+ токенов, что
неприемлемо). Полная библиотека: `skills-library/index.json`. 2 записи (`quality-cost-skill-kernel`,
`source-ranking-roi-selector`) — донор-специфичные мета-концепции, description backfilled, но
контент НЕ импортирован (см. `PLAN-V2-MERGE-FROM-CODEX.md`, "НЕ БРАТЬ"). 3 записи с совпадающим
именем (`github-research`, `production-review`, `seo`) НЕ тронуты — у нас уже есть канонические
версии этих скиллов.

## ANTH-OFF — официальный маркетплейс Anthropic (ПРИОРИТЕТ №1, vetted)
Высший уровень доверия: курируется Anthropic → проходит гейт без сомнений. Брать отсюда первым делом.
```
/plugin marketplace add anthropics/claude-plugins-official   # 55–101 vetted-плагинов
/plugin marketplace add anthropics/skills                    # официальные skills
/plugin install code-review        # feature-dev, commit-commands, security-guidance, frontend-design ...
# knowledge-work-plugins: официальные sales/legal/finance/data (Anthropic open-sourced)
```
- Каталог: https://github.com/anthropics/claude-plugins-official · skills: https://github.com/anthropics/skills
- Правило приоритета: при равном качестве официальное Anthropic > community (wshobson/VoltAgent/прочее).

## Наблюдаемость / eval / cost (закрывает P1)
- nexus-labs-automation/agent-observability — LLM-трейсинг, tool calls, cost, prompt A/B, guardrails (14 скиллов): https://github.com/nexus-labs-automation/agent-observability
- OpenTelemetry для Claude Code (official): спаны `claude_code.llm_request`/`.tool` → OTLP (Honeycomb/Datadog/Grafana/Langfuse)
- rohitg00/awesome-claude-code-toolkit — индекс 135 агентов/176 плагинов/20 хуков: https://github.com/rohitg00/awesome-claude-code-toolkit

## WSH — wshobson/agents (главный community-источник, 194 агента + 158 скиллов)
Multi-harness marketplace, нативно для Claude Code. Самый зрелый и поддерживаемый.

```
# в интерактивном Claude Code:
/plugin marketplace add wshobson/agents
/plugin install <plugin-name>
```
- Каталог агентов: https://github.com/wshobson/agents/blob/main/docs/agents.md
- Каталог скиллов: https://github.com/wshobson/agents/blob/main/docs/agent-skills.md
- Плагины группируют связанные агенты+скиллы (напр. `python-development` = python-pro + django-pro + fastapi-pro + 16 скиллов). Ставь плагин целиком под домен, а не по одному.

## VOLT — VoltAgent/awesome-claude-code-subagents (150+ агентов, 10 категорий)
Маркдаун-агенты. Клонировать в `.claude/agents/` проекта или в `~/.claude/agents/` глобально.

```bash
git clone https://github.com/VoltAgent/awesome-claude-code-subagents ~/.claude/_volt
# скопировать нужные .md в ~/.claude/agents/ (только выбранные по профилю)
```
- https://github.com/VoltAgent/awesome-claude-code-subagents

## FTB — freshtechbro/claudedesignskills (3D web + анимация, 22 плагина)
Главный источник по 3D/анимации/web-дизайну. Нативный plugin marketplace.
```
/plugin marketplace add freshtechbro/claudedesignskills
/plugin install react-three-fiber      # или threejs-webgl, gsap-scrolltrigger, motion-framer, babylonjs-engine
/plugin install core-3d-animation       # bundle: Three.js+GSAP+R3F+Motion+Babylon
```

## GH — точечные репозитории (clone, проверить лицензию!)
- 3D/R3F: EnzeD/r3f-skills, CloudAI-X/threejs-skills, Nice-Wolf-Studio/claude-skills-threejs-ecs-ts, ai4brands-design/claude-skills
- Frontend/дизайн: wilwaldon/Claude-Code-Frontend-Design-Toolkit, Schoepplake/framer-motion-skill
- SEO (универсальные, мощные): AgriciDaniel/claude-seo (25 skills+18 agents), AgriciDaniel/claude-blog (30 skills), Bhanunamikaze/Agentic-SEO-Skill, TheCraigHewitt/seomachine, seranking/seo-skills
- Amazon: nexscope-ai/Amazon-Skills (free), MarceauSolutions/amazon-seller-mcp (open-source SP-API + FBA fee calc 2026)

## EXT — managed Amazon MCP (OAuth/платные, для реального кабинета продавца)
- DataDoe Amazon MCP — Seller/Vendor/Ads/profit, repricer, FBA reimbursement, chargeback: https://www.datadoe.com/connect/amazon/mcp
- agentcentral — hosted Seller Central + Ads + finance: mcpservers.org/servers/agentcentral
- sellermetrics — Amazon Ads (PPC) MCP: https://sellermetrics.app/amazon-ads-mcp-with-claude/
- Porter — SP-API↔Claude прослойка (OAuth/rate-limit): https://portermetrics.com
⚠️ SP-API = доступ к реальному кабинету (инвентарь, деньги). Не выполнять платные/repricing-действия без явного подтверждения Ивана (см. 50-security.md).

## 0xfurai/claude-code-subagents (928★) — tool/library-эксперты (~150 `*-expert`)
Гранулярность инструмента (redis/kafka/prisma/playwright/flyway/...). Бери точечно под стек.
```
git clone https://github.com/0xfurai/claude-code-subagents
# скопировать нужные agents/<tool>-expert.md в ~/.claude/agents/ или .claude/agents/
```

## Оркестрация / swarm (G3, тяжёлые внешние фреймворки — ставить ТОЛЬКО под явную задачу)
- ruvnet/claude-flow (Ruflo, 31k★) — swarm-оркестрация + SPARC: https://github.com/ruvnet/claude-flow  (`npx claude-flow`)
- dsifry/metaswarm — 18 агентов+13 скиллов, TDD+quality gates: https://github.com/dsifry/metaswarm
- nwiizo/ccswarm — worktree-изоляция, plan→consensus→PR: https://github.com/nwiizo/ccswarm
- affaan-m/claude-swarm — декомпозиция + terminal UI: https://github.com/affaan-m/claude-swarm
- barkain/claude-code-workflow-orchestration — плагин plan-mode: https://github.com/barkain/claude-code-workflow-orchestration
- ralph-claude-code / claude_code_agent_farm / agentsys — автономные циклы/фермы (по звёздам)
⚠️ Внешний рой = автономные правки + много токенов. Перед запуском — подтверждение Ивана (50-security.md).

## E-commerce / маркетинг ниша
- Shopify/Shopify-AI-Toolkit (официальный) — products/orders/inventory/GraphQL: https://github.com/Shopify/Shopify-AI-Toolkit
- thatrebeccarae/claude-marketing — 56 скиллов: Klaviyo, Shopify, GA4, Looker Studio: https://github.com/thatrebeccarae/claude-marketing
- coreyhaines31/marketingskills — CRO/copywriting/analytics/growth: https://github.com/coreyhaines31/marketingskills
- devkindhq/shopifyql-skill — ShopifyQL/Segment запросы: https://github.com/devkindhq/shopifyql-skill

## Skill-индексы (для будущего расширения, не массовая установка)
- ComposioHQ/awesome-claude-skills (1000+): https://github.com/ComposioHQ/awesome-claude-skills
- VoltAgent/awesome-agent-skills (1000+, официальные Anthropic/Vercel/Stripe/Cloudflare): https://github.com/VoltAgent/awesome-agent-skills
- sickn33/antigravity-awesome-skills (1600+, есть installer CLI): https://github.com/sickn33/antigravity-awesome-skills
- travisvn/awesome-claude-skills: https://github.com/travisvn/awesome-claude-skills

## Верификационный гейт (ОБЯЗАТЕЛЬНО перед первой установкой внешнего)
Статус по умолчанию: `INST`/`ANTH` = installed; всё внешнее = **unvetted**. Звёзды ≠ безопасность/качество/лицензия.
1. **github-research**: лицензия (совместима?), дата последнего коммита (живой?), беглый скан README/кода на вредоносное и запрос секретов.
2. **Пиннинг**: фиксируй коммит/тег, не «latest».
3. **Приоритет** официальным (Anthropic/Vercel/Stripe/Shopify/Cloudflare) над случайным community.
4. **Least-privilege**: внешний агент без доступа к `.env`/секретам.
5. **Swarm/автономные** (claude-flow, metaswarm, ccswarm, ralph, agent-farm) — автономные правки → только с явным подтверждением Ивана (50-security.md).
6. **Никакого авто-install.** Ставить только выбранное по профилю (`SELECTION-PROTOCOL.md`/`PROFILE.lock`), не «всё подряд».

## Правило установки (из CLAUDE.md §12 / 50-security.md)
- Формат Claude Skills — открытый стандарт (Anthropic, дек. 2025), совместим с Claude Code / API / Codex / Cursor / Gemini.
