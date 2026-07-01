# CORE-300 — Ядро скиллов и агентов Claude MD OS

Единый источник истины. **НЕ грузить целиком в контекст.** При старте проекта агент классифицирует проект и `grep`-ает этот файл по доменным тегам `[tag]`, берёт только нужное. См. `SELECTION-PROTOCOL.md`.

Собран 28.06.2026 на основе реального GitHub-research: wshobson/agents (194 агента + 158 скиллов, plugin-marketplace), VoltAgent/awesome-claude-code-subagents (150+), Anthropic official skills, и уже установленных в среде плагинов. См. `INSTALL-SOURCES.md`.

**Статус верификации (по умолчанию):** `INST`/`ANTH` = **installed** (живо сразу). Всё остальное (`WSH/VOLT/FTB/GH/EXT`) = **unvetted** до github-research (лицензия + last-commit + скан) и пиннинга. Звёзды ≠ безопасность. Никакого авто-install — см. верификационный гейт в `70-skills-registry.md`.

**Источники (source codes):**
- `INST` — уже установлено в этой среде (skill/plugin доступен сразу, 0 установки)
- `ANTH` — официальный Anthropic skill (установлен)
- `WSH` — wshobson/agents marketplace (`/plugin install <name>`)
- `VOLT` — VoltAgent collection (clone/curl)
- `LOCAL` — наш Claude MD OS

**Доменные теги для grep:** `[web] [frontend] [backend] [api] [mobile] [data] [ai] [ml] [infra] [devops] [cicd] [security] [compliance] [quality] [test] [perf] [a11y] [docs] [diagram] [arch] [seo] [marketing] [sales] [business] [product] [pm] [finance] [trading] [legal] [hr] [ops] [windows] [lang] [design] [meta] [research] [mcp] [game] [web3] [iot] [embedded] [shell] [git] [payments]`

**Принцип выбора: качество решения — главное; экономия — при равном качестве.** Бери минимально достаточную мощность для НУЖНОГО качества — и не ниже. G1/G2/G3 описывают, сколько мощности требует задача, а не «что подешевле».

**Три группы по экономике токенов:**
- **GROUP 1 — нейтральные/экономят токены.** Детерминированные генераторы, валидаторы, конвертеры, шаблоны, хуки, read-only проверки, сжатие контекста. Берутся почти всегда — они дешевле, чем делать то же руками.
- **GROUP 2 — улучшение ≈ расход токенов.** Одношаговый экспертный консультант по домену. Берутся точечно под стек проекта.
- **GROUP 3 — дорого, но понятный результат.** Многошаговые оркестраторы, полные аудиты, глубокий research, multi-agent команды, полные сборки. Только под явную задачу/подтверждение.

Принцип: **никакого перекрытия** — одна каноническая запись на способность. Если способность уже закрыта `INST`, внешние дубликаты не ставим.

---

## GROUP 1 — Token-neutral / token-saving (≈90)

### Документы и конвертация (детерминированно, заменяет ручную работу)
1. `docx` [docs] ANTH — создание/редактирование Word
2. `pptx` [docs] ANTH — создание/редактирование PowerPoint
3. `xlsx` [docs][data] ANTH — создание/редактирование Excel
4. `pdf` [docs] ANTH — чтение/извлечение/заполнение PDF
5. `pdf-viewer:fill-form` [docs] INST — заполнение PDF-форм
6. `pdf-viewer:sign` [docs] INST — подпись PDF
7. `pdf-viewer:annotate` [docs] INST — аннотации PDF
8. `api-documenter` [api][docs] VOLT — генерация API-референса
9. `openapi-spec-generation` [api][docs] WSH — генерация OpenAPI
10. `readme-generator` [docs] VOLT — README из репозитория
11. `changelog-automation` [docs] WSH — changelog из коммитов
12. `architecture-decision-records` [docs][arch] WSH — ADR-шаблоны
13. `hads` [docs] WSH — стандарты документации

### Диаграммы (из описания/кода, без ручного рисования)
14. `mermaid-expert` [diagram][docs] WSH — mermaid-диаграммы
15. `c4-context` [diagram][arch] WSH — C4 context
16. `c4-container` [diagram][arch] WSH — C4 container
17. `c4-component` [diagram][arch] WSH — C4 component
18. `c4-code` [diagram][arch] WSH — C4 code
19. `figma:figma-generate-diagram` [diagram] INST — диаграммы в Figma
20. `miro:miro-diagram` [diagram] INST — диаграммы в Miro

### Дизайн-ассеты (детерминированная генерация)
21. `canvas-design` [design] ANTH — постеры/арт PNG/PDF
22. `algorithmic-art` [design] ANTH — генеративный арт
23. `theme-factory` [design] ANTH — темы/палитры
24. `brand-guidelines` [design] ANTH — применение бренд-гайда
25. `slack-gif-creator` [design] ANTH — GIF для Slack
26. `visual-asset-generator` [design] VOLT — ассеты
27. `logo_search` [design] INST — поиск логотипов (magic MCP)
28. `design-system-patterns` [design][web] WSH — дизайн-токены
29. `responsive-design` [design][web] WSH — адаптив-паттерны
30. `tailwind-design-system` [design][web] WSH — Tailwind-система

### Скаффолдинг и шаблоны (экономит exploration)
31. `fastapi-templates` [backend] WSH — заготовки FastAPI
32. `github-actions-templates` [cicd] WSH — CI-воркфлоу
33. `gitlab-ci-patterns` [cicd] WSH — GitLab CI
34. `k8s-manifest-generator` [infra] WSH — k8s-манифесты
35. `helm-chart-scaffolding` [infra] WSH — helm-чарты
36. `terraform-module-library` [infra] WSH — terraform-модули
37. `stripe-integration` [payments] WSH — заготовка Stripe
38. `paypal-integration` [payments] WSH — заготовка PayPal
39. `incident-runbook-templates` [ops] WSH — раннбуки
40. `employment-contract-templates` [legal][hr] WSH — договоры
41. `vercel:bootstrap` [web] INST — бутстрап Vercel-приложения
42. `searchfit-seo:generate-schema` [seo] INST — JSON-LD генератор
43. `seo-schema` [seo] INST — schema.org генератор
44. `seo-sitemap` [seo] INST — sitemap генератор/валидатор

### Мета/скаффолд OS (структурно, 0 доп. токенов)
45. `project-bootstrap` [meta] LOCAL — init Claude MD OS
46. `skill-creator` [meta] ANTH — автор новых скиллов
47. `mcp-builder` [meta][mcp] ANTH — скаффолд MCP-серверов
48. `cowork-plugin-management:create-cowork-plugin` [meta] INST — плагин
49. `github-research` [meta] LOCAL — протокол GitHub-research
50. `production-review` [meta] LOCAL — пред-деплой ревью
51. `connector-orchestrator` [meta][mcp] LOCAL — дисциплина MCP
52. `init` [meta] LOCAL command — bootstrap проекта
53. `plan` [meta] LOCAL command — ExecPlan
54. `research` [meta] LOCAL command — GitHub research
55. `review-production` [meta] LOCAL command — деплой-ревью

### Валидаторы/линтеры/хуки/read-only проверки (дёшево, ловят дорогие ошибки)
56. `shellcheck-configuration` [shell] WSH — линт shell
57. `bash-defensive-patterns` [shell] WSH — безопасный bash
58. `bats-testing-patterns` [shell][test] WSH — тесты bash
59. `block-no-verify-hook` [meta][security] WSH — блок `--no-verify`
60. `protect-mcp-setup` [mcp][security] WSH — защита MCP-конфига
61. `secrets-management` [security] WSH — обращение с секретами
62. `sast-configuration` [security] WSH — настройка SAST
63. `wcag-audit-patterns` [a11y] WSH — чеклист доступности
64. `screen-reader-testing` [a11y] WSH — проверки скринридером
65. `error-handling-patterns` [quality] WSH — обработка ошибок
66. `sql-optimization-patterns` [data] WSH — паттерны тюнинга SQL
67. `code-review-excellence` [quality] WSH — чеклист ревью (skill)
68. `license-engineer` [legal] VOLT — проверка лицензий
69. `dependency-manager` [devops] VOLT — гигиена зависимостей
70. `dependency-upgrade` [devops] WSH — безопасные апгрейды

### Git/билд/devex (детерминированная дисциплина)
71. `git-workflow-manager` [git][devops] VOLT — git-воркфлоу
72. `git-advanced-workflows` [git] WSH — продвинутый git
73. `monorepo-management` [devops] WSH — структура монорепо
74. `nx-workspace-patterns` [devops] WSH — Nx
75. `turborepo-caching` [devops] WSH — кеш Turborepo
76. `bazel-build-optimization` [devops] WSH — Bazel
77. `build-engineer` [devops] VOLT — оптимизация сборки
78. `tooling-engineer` [devops] VOLT — внутренний тулинг
79. `cli-developer` [devops] VOLT — CLI-тулзы
80. `dx-optimizer` [devops] VOLT — developer experience

### Контекст/память/поиск (прямая экономия токенов)
81. `context-manager` [meta] WSH — сжатие/менеджмент контекста
82. `search-specialist` [research] VOLT — фокусированный поиск
83. `before-you-build` [meta] WSH — пред-билд чеклист (анти-rework)
84. `productivity:memory-management` [meta] INST — постоянная память
85. `productivity:task-management` [meta] INST — трекинг задач
86. `anthropic-skills:consolidate-memory` [meta] INST — чистка памяти
87. `enterprise-search:search` [research] INST — кросс-поиск
88. `enterprise-search:source-management` [research] INST — источники
89. `kpi-dashboard-design` [business] WSH — шаблоны KPI-дашбордов
90. `social-publishing` [marketing] WSH — публикация постов

---

## GROUP 2 — Improvement ≈ token cost (≈140)

### Качество / ревью / отладка / тесты
91. `code-reviewer` [quality] WSH — ревью диффа
92. `architect-reviewer` [arch][quality] WSH — ревью архитектуры
93. `debugger` [quality] WSH — root-cause отладка
94. `error-detective` [quality] VOLT — поиск паттернов ошибок
95. `test-automator` [test] WSH — написание тестов
96. `tdd-orchestrator` [test] WSH — TDD-цикл
97. `qa-expert` [test] VOLT — QA-стратегия
98. `e2e-testing-patterns` [test] WSH — e2e
99. `accessibility-tester` [a11y] VOLT — a11y-тестирование
100. `ui-ux-tester` [test][web] VOLT — UI-тестирование
101. `performance-engineer` [perf] WSH — тюнинг производительности
102. `database-optimizer` [data][perf] WSH — тюнинг запросов/индексов
103. `observability-engineer` [ops] WSH — телеметрия
104. `refactoring-specialist` [quality] VOLT — точечный рефактор
105. `legacy-modernizer` [quality] VOLT — модернизация легаси

### Языки
106. `python-pro` [lang] WSH
107. `typescript-pro` [lang] VOLT
108. `javascript-pro` [lang] VOLT
109. `golang-pro` [lang] VOLT
110. `rust-engineer` [lang] VOLT
111. `java-architect` [lang] VOLT
112. `csharp-developer` [lang] VOLT
113. `cpp-pro` [lang] VOLT
114. `php-pro` [lang] VOLT
115. `sql-pro` [lang][data] VOLT
116. `swift-expert` [lang][mobile] VOLT
117. `kotlin-specialist` [lang][mobile] VOLT
118. `node-specialist` [lang][backend] VOLT
119. `elixir-expert` [lang] VOLT
120. `powershell-7-expert` [lang][windows] VOLT — (среда Ивана = Windows)
121. `powershell-5.1-expert` [lang][windows] VOLT

### Web/frontend фреймворки
122. `nextjs-developer` [web] VOLT — (my-nextjs-app на Next.js)
123. `react-specialist` [web] VOLT
124. `vue-expert` [web] VOLT
125. `angular-architect` [web] VOLT
126. `nextjs-app-router-patterns` [web] WSH
127. `react-state-management` [web] WSH
128. `ui-ux-pro-max` [web][design] INST — UI/UX дизайн-интеллект
129. `frontend-design:frontend-design` [web][design] INST
130. `vercel:nextjs` [web] INST
131. `vercel:shadcn` [web] INST
132. `vercel:ai-sdk` [web][ai] INST
133. `vercel:auth` [web][security] INST
134. `vercel:env` [web] INST
135. `figma:figma-use` [design] INST
136. `21st_magic_component_builder` [web][design] INST — генерация компонентов

### Backend / API / архитектура
137. `backend-developer` [backend] VOLT
138. `api-designer` [api] VOLT
139. `graphql-architect` [api] VOLT
140. `api-design-principles` [api] WSH
141. `architecture-patterns` [arch] WSH
142. `microservices-patterns` [backend][arch] WSH
143. `cqrs-implementation` [backend] WSH
144. `saga-orchestration` [backend] WSH
145. `event-store-design` [backend] WSH
146. `auth-implementation-patterns` [security][backend] WSH
147. `django-developer` [backend] VOLT
148. `fastapi-developer` [backend] VOLT
149. `laravel-specialist` [backend] VOLT
150. `rails-expert` [backend] VOLT
151. `spring-boot-engineer` [backend] VOLT
152. `dotnet-core-expert` [backend] VOLT

### Данные
153. `data-engineer` [data] VOLT
154. `data-analyst` [data] VOLT
155. `postgres-pro` [data] VOLT
156. `postgresql-table-design` [data] WSH
157. `dbt-transformation-patterns` [data] WSH
158. `airflow-dag-patterns` [data] WSH
159. `data-quality-frameworks` [data] WSH
160. `spark-optimization` [data] WSH
161. `data:write-query` [data] INST
162. `data:create-viz` [data] INST
163. `data:analyze` [data] INST
164. `data:statistical-analysis` [data] INST

### Infra / DevOps
165. `docker-expert` [infra] VOLT
166. `kubernetes-specialist` [infra] VOLT
167. `terraform-engineer` [infra] VOLT
168. `deployment-engineer` [infra][cicd] VOLT
169. `devops-engineer` [devops] VOLT
170. `network-engineer` [infra] VOLT
171. `database-administrator` [infra][data] VOLT
172. `deployment-pipeline-design` [cicd] WSH
173. `prometheus-configuration` [ops] WSH
174. `grafana-dashboards` [ops] WSH
175. `distributed-tracing` [ops] WSH
176. `slo-implementation` [ops] WSH
177. `vercel:deploy` [deploy][web] INST
178. `vercel:status` [deploy][web] INST

### Безопасность (ограниченная, точечная)
179. `security-engineer` [security] VOLT
180. `backend-security-coder` [security] WSH
181. `frontend-security-coder` [security] WSH
182. `mobile-security-coder` [security] WSH
183. `stride-analysis-patterns` [security] WSH
184. `security-review` [security] INST command
185. `vanta:fix-test` [security][compliance] INST
186. `vanta:test-remediation` [security][compliance] INST
187. `powershell-security-hardening` [security][windows] VOLT

### AI / LLM / MCP
188. `ai-engineer` [ai] VOLT
189. `prompt-engineer` [ai] VOLT
190. `prompt-engineering-patterns` [ai] WSH
191. `rag-implementation` [ai] WSH
192. `langchain-architecture` [ai] WSH
193. `llm-evaluation` [ai] WSH
194. `embedding-strategies` [ai] WSH
195. `hybrid-search-implementation` [ai] WSH
196. `vector-index-tuning` [ai] WSH
197. `mcp-developer` [mcp] VOLT
198. `claude-api` [ai] INST — референс Claude API
199. `vercel:ai-gateway` [ai] INST

### SEO (точечные проверки; полный аудит — GROUP 3)
200. `seo-specialist` [seo] VOLT
201. `seo-content-auditor` [seo] WSH
202. `seo-keyword-strategist` [seo] WSH
203. `seo-structure-architect` [seo] WSH
204. `seo-authority-builder` [seo] WSH
205. `seo-cannibalization-detector` [seo] WSH
206. `searchfit-seo:on-page-seo` [seo] INST
207. `searchfit-seo:technical-seo` [seo] INST
208. `searchfit-seo:internal-linking` [seo] INST
209. `searchfit-seo:keyword-clustering` [seo] INST
210. `seo-content-brief` [seo] INST

### Бизнес / продукт / маркетинг / продажи
211. `product-manager` [product] VOLT
212. `business-analyst` [business] VOLT
213. `ux-researcher` [product] VOLT
214. `technical-writer` [docs] VOLT
215. `content-marketer` [marketing] VOLT
216. `scrum-master` [pm] VOLT
217. `project-manager` [pm] VOLT
218. `product-management:write-spec` [product] INST
219. `product-management:competitive-brief` [product] INST
220. `marketing:campaign-plan` [marketing] INST
221. `marketing:email-sequence` [marketing] INST
222. `marketing:content-creation` [marketing] INST
223. `sales:account-research` [sales] INST
224. `sales:draft-outreach` [sales] INST
225. `sales:call-prep` [sales] INST
226. `common-room:compose-outreach` [sales] INST
227. `vpai` [sales][ai] INST — vibe-prospecting
228. `brand-voice:enforce-voice` [marketing] INST

### Operations / финансы / HR / legal (точечные)
229. `operations:runbook` [ops] INST
230. `operations:status-report` [ops] INST
231. `small-business:lead-triage` [business] INST
232. `small-business:invoice-chase` [business] INST
233. `small-business:cash-flow-snapshot` [finance] INST
234. `finance:reconciliation` [finance] INST
235. `finance:variance-analysis` [finance] INST
236. `human-resources:draft-offer` [hr] INST
237. `legal:review-contract` [legal] INST
238. `legal:compliance-check` [legal] INST

### Мобайл / специализированные домены
239. `mobile-developer` [mobile] VOLT
240. `flutter-expert` [mobile] VOLT
241. `expo-react-native-expert` [mobile] VOLT
242. `react-native-architecture` [mobile] WSH
243. `game-developer` [game] VOLT
244. `unity-ecs-patterns` [game] WSH
245. `embedded-systems` [embedded] VOLT
246. `iot-engineer` [iot] VOLT
247. `blockchain-developer` [web3] VOLT
248. `solidity-security` [web3][security] WSH
249. `payment-integration` [payments] VOLT
250. `fintech-engineer` [fintech][finance] VOLT

### Трейдинг (релевантно trading-bot)
251. `quant-analyst` [trading] VOLT — кванты
252. `risk-manager` [trading] VOLT — риск-менеджмент
253. `backtesting-frameworks` [trading] WSH — бэктест
254. `risk-metrics-calculation` [trading] WSH — риск-метрики

### Windows / M365 (релевантно среде)
255. `windows-infra-admin` [windows] VOLT
256. `powershell-module-architect` [windows] VOLT
257. `powershell-ui-architect` [windows] VOLT
258. `m365-admin` [windows] VOLT

### Миграции (точечные)
259. `react-modernization` [web] WSH
260. `angular-migration` [web] WSH
261. `database-migration` [data] WSH
262. `cockroachdb:cockroachdb-sql` [data] INST

### Документация-как-архитектура / research-lite
263. `docs-architect` [docs] WSH
264. `research-analyst` [research] VOLT
265. `competitive-analyst` [research] VOLT
266. `trend-analyst` [research] VOLT
267. `nimble:competitor-intel` [research] INST
268. `zoominfo:enrich-company` [sales][research] INST
269. `apollo:enrich-lead` [sales] INST
270. `airtable:sales-ops` [business] INST

### Спец-стек (под конкретные проекты)
271. `huntlandia` → `merchant_amazon_*` [business] INST — Amazon FBA данные (DataForSEO)
272. `adspirer-ads-agent:campaign-performance` [marketing] INST
273. `adspirer-ads-agent:keyword-research` [marketing] INST
274. `sanity:sanity` [web][backend] INST — Sanity CMS
275. `twilio-developer-kit:twilio-messaging-overview` [backend] INST
276. `zoom-plugin:start` [backend] INST
277. `cloudinary:cloudinary-transformations` [web][design] INST
278. `box:box` [docs] INST
279. `intercom:intercom-analysis` [business] INST
280. `slack-by-salesforce:summarize-channel` [ops] INST

---

## GROUP 3 — Token-heavy, clear result (≈70)

### Полные аудиты безопасности/комплаенса
281. `code-review ultra` (ultrareview) [quality] INST — multi-agent облачное ревью ветки/PR
282. `security-auditor` [security] WSH — полный аудит безопасности
283. `penetration-tester` [security] VOLT — пентест
284. `threat-modeling-expert` [security] WSH — полное threat-моделирование
285. `attack-tree-construction` [security] WSH — деревья атак
286. `compliance-auditor` [compliance] VOLT — комплаенс-аудит
287. `gdpr-ccpa-compliance` [compliance] VOLT — GDPR/CCPA
288. `hipaa-compliance` [compliance] VOLT — HIPAA
289. `aws-dev-toolkit:security-review` [security] INST
290. `vanta:test-remediation-full` (полный прогон) [compliance] INST

### Reliability / incident / SRE
291. `chaos-engineer` [ops] VOLT — chaos-эксперименты
292. `incident-responder` [ops] VOLT — разбор инцидентов
293. `devops-incident-responder` [ops] VOLT
294. `sre-engineer` [ops] VOLT
295. `engineering:incident-response` [ops] INST

### Облачная архитектура / well-architected / миграции
296. `cloud-architect` [infra][arch] VOLT — полный дизайн облака
297. `platform-engineer` [infra] VOLT
298. `aws-dev-toolkit:well-architected` [infra][arch] INST — WAF-ревью
299. `aws-dev-toolkit:aws-architect` [infra][arch] INST
300. `migration-advisor` [migration] INST — миграция ворклоадов в AWS

### Мульти-агент оркестрация (дорого, но закрывает большие задачи)
301. `multi-agent-coordinator` [meta] VOLT — оркестрация команд агентов
302. `codebase-orchestrator` [meta] VOLT — крупные изменения по кодбазе
303. `workflow-orchestrator` [meta] VOLT
304. `agent-organizer` [meta] VOLT
305. `parallel-feature-development` [meta] WSH — команда агентов параллельно
306. `parallel-debugging` [meta] WSH
307. `multi-reviewer-patterns` [meta] WSH

### Глубокий research / аналитика
308. `scientific-literature-researcher` [research] VOLT — лит-обзор (PubMed/bioRxiv плагины)
309. `data-researcher` [research] VOLT
310. `market-sizing-analysis` [business] WSH — TAM/SAM/SOM
311. `startup-financial-modeling` [business][finance] WSH
312. `competitive-landscape` [business] WSH
313. `enterprise-search:knowledge-synthesis` [research] INST
314. `nimble:company-deep-dive` [research] INST
315. `zoominfo:tam-sizer` [sales] INST
316. `bigdata-com:investment-memo` [finance][research] INST
317. `daloopa:build-model` [finance] INST — финансовая модель
318. `lseg:equity-research` [finance] INST

### ML / data science пайплайны (тяжело, понятный артефакт)
319. `ml-engineer` [ml] VOLT — сборка ML-модели
320. `mlops-engineer` [ml] VOLT — MLOps-пайплайн
321. `machine-learning-engineer` [ml] VOLT
322. `data-scientist` [data][ml] VOLT
323. `ml-pipeline-workflow` [ml] WSH
324. `reinforcement-learning-engineer` [ml][trading] VOLT — (RL для trading-bot)
325. `llm-architect` [ai][ml] VOLT — дизайн LLM-системы
326. `nlp-engineer` [ai][ml] VOLT

### Полные SEO/контент-сборки
327. `seo` (full audit) [seo] INST — полный SEO-аудит сайта
328. `searchfit-seo:seo-audit` [seo] INST
329. `searchfit-seo:content-strategy` [seo][marketing] INST
330. `seo-dataforseo` [seo] INST — живые SERP/бэклинки (DataForSEO MCP)

### Крупные бизнес-сборки / стратегия
331. `product-management:synthesize-research` [product] INST
332. `marketing:performance-report` [marketing] INST
333. `operations:process-optimization` [ops] INST
334. `operations:capacity-plan` [ops] INST
335. `human-resources:org-planning` [hr] INST
336. `finance:financial-statements` [finance] INST
337. `finance:close-management` [finance] INST
338. `legal:legal-risk-assessment` [legal] INST
339. `small-business:quarterly-review` [business] INST
340. `engineering:system-design` [arch] INST — полный system design

### Доменные глубокие (под конкретные проекты)
341. `quant-analyst-full` (полный портфельный анализ) [trading] VOLT
342. `lseg:fixed-income-portfolio` [finance][trading] INST
343. `bigdata-com:risk-assessment` [finance][research] INST
344. `nimble:market-finder` [research][business] INST
345. `zoominfo:tam-sizer-full` (полный TAM) [sales] INST
346. `common-room:generate-account-plan` [sales] INST
347. `sales:forecast` [sales] INST
348. `customer-support:customer-research` [business] INST
349. `bio-research:single-cell-rna-qc` [research] INST — (если био-задача)
350. `cockroachdb:designing-multi-region-applications` [data][arch] INST

---

## Анти-overlap карта (каноны)

Когда несколько источников дают одно и то же — берём канон:
- **Code review (diff)** → `code-reviewer` (WSH). Глубокое облачное → `code-review ultra` (INST, G3).
- **Security**: точечно по слою → `*-security-coder` (G2); полный аудит → `security-auditor`/`penetration-tester` (G3). Не запускать оба на одну задачу.
- **Тесты**: написать → `test-automator`; цикл → `tdd-orchestrator`; стратегия → `qa-expert`. Один на задачу.
- **Next.js**: реализация → `nextjs-developer`/`vercel:nextjs`; паттерны роутинга → `nextjs-app-router-patterns`. Дизайн UI → `ui-ux-pro-max` (не дублировать с `frontend-design`).
- **SEO**: точечная проверка → G2 `seo-*`; полный аудит → G3 `seo`/`searchfit-seo:seo-audit`. Живые данные → `seo-dataforseo`.
- **Docs**: README → `readme-generator`; OpenAPI → `openapi-spec-generation`; ADR → `architecture-decision-records`; архитектурный нарратив → `docs-architect`.
- **Диаграммы**: mermaid → `mermaid-expert`; C4 → `c4-*`. Не оба на одну диаграмму.
- **Память/контекст**: `context-manager` (сжатие сессии) ≠ `productivity:memory-management` (долгая память) ≠ наш файловый memory. Разные слои.

---

# ДОПОЛНЕНИЕ A (28.06.2026) — Deep research v2: 3D web, программирование, web-дизайн, SEO, Amazon

Второй заход GitHub/площадки тем же принципом (3 группы, без overlap). Новые теги: `[3d] [webgl] [animation] [amazon] [desktop]`.

Новые source codes:
- `FTB` — freshtechbro/claudedesignskills (plugin marketplace: `/plugin marketplace add freshtechbro/claudedesignskills`)
- `GH:<repo>` — отдельный GitHub-репозиторий (clone, **проверить лицензию перед установкой**)
- `EXT` — внешний managed MCP-сервис (платный/OAuth)

⚠️ Внешние (`FTB`/`GH`/`EXT`) — ставить ТОЛЬКО по профилю проекта и после проверки лицензии (github-research). Не массово.

## G1+ — знание-скиллы и генераторы (экономят токены: дают точный API → меньше проб и rework)

### 3D web / WebGL (freshtechbro/claudedesignskills — 22 плагина)
351. `threejs-webgl` [3d][webgl][web] FTB — Three.js/WebGL API + паттерны
352. `react-three-fiber` [3d][web][frontend] FTB — R3F (декларативный 3D в React)
353. `babylonjs-engine` [3d][webgl][game] FTB — Babylon.js
354. `aframe-webxr` [3d][webgl][web] FTB — A-Frame WebXR/VR/AR
355. `playcanvas-engine` [3d][webgl][game] FTB — PlayCanvas
356. `pixijs-2d` [3d][web] FTB — PixiJS (2D WebGL)
357. `lightweight-3d-effects` [3d][web][perf] FTB — лёгкие 3D-эффекты без тяжёлого движка
358. `spline-interactive` [3d][design][web] FTB — Spline-сцены (no-code 3D → web)
359. `blender-web-pipeline` [3d][design] FTB — Blender → glTF → web пайплайн
360. `substance-3d-texturing` [3d][design] FTB — текстурирование 3D
361. `web3d-integration-patterns` [3d][web][arch] FTB — мета: как комбинировать 3D-либы
362. `r3f-skills` [3d][web] GH:EnzeD/r3f-skills — углублённый набор по React Three Fiber
363. `threejs-ecs-ts` [3d][game] GH:Nice-Wolf-Studio/claude-skills-threejs-ecs-ts — Three.js + ECS + TS, мобильные 3D-игры
364. `threejs-skills` [3d][webgl] GH:CloudAI-X/threejs-skills — справочник Three.js API

### Анимация / motion (knowledge-скиллы, авто-активация)
365. `gsap-scrolltrigger` [animation][web] FTB — GSAP + ScrollTrigger (useGSAP, scrub, reduced-motion)
366. `motion-framer` [animation][web] FTB — Framer Motion (variants, layout)
367. `react-spring-physics` [animation][web] FTB — react-spring (физика)
368. `animejs` [animation][web] FTB — anime.js
369. `lottie-animations` [animation][web] FTB — Lottie (After Effects → web)
370. `rive-interactive` [animation][design] FTB — Rive (интерактивная анимация)
371. `scroll-reveal-libraries` [animation][web] FTB — scroll-reveal
372. `locomotive-scroll` [animation][web] FTB — smooth scroll
373. `barba-js` [animation][web] FTB — page transitions
374. `animated-component-libraries` [animation][web] FTB — анимированные компоненты
375. `framer-motion-skill` [animation][web] GH:Schoepplake/framer-motion-skill — отдельный Framer Motion skill

### Web-дизайн (знание + качество фронта)
376. `modern-web-design` [design][web] FTB — принципы современного web-дизайна
377. `frontend-design-toolkit` [design][web] GH:wilwaldon/Claude-Code-Frontend-Design-Toolkit — набор для красивого фронта (skills+MCP+CLAUDE.md трюки)
378. `premium-frontend-ui` [design][web] GH:awesome-copilot — премиальные UI-паттерны
379. `web-component-design` [web][design] WSH — дизайн web-components
380. `interaction-design` [design][web] WSH — interaction design
381. `visual-design-foundations` [design] WSH — основы визуального дизайна
382. `mobile-ios-design` [mobile][design] WSH — iOS UI
383. `mobile-android-design` [mobile][design] WSH — Android UI
384. `react-native-design` [mobile][design] WSH — RN UI

### SEO — программный/GEO (gap-fill; каноны уже INST)
385. `seo-programmatic` [seo][web] INST — программные SEO-страницы из данных (quality gates)
386. `seo-geo` [seo] INST — GEO/AEO: AI Overviews / ChatGPT / Perplexity
387. `seo-hreflang` [seo] INST — international hreflang
389. `claude-seo (universal)` [seo] GH:AgriciDaniel/claude-seo — 25 sub-skills + 18 агентов (внешний, если выходим за пределы INST)

### Amazon — данные/генераторы
390. `nexscope Amazon-Skills` [amazon][business] GH:nexscope-ai/Amazon-Skills — бесплатные skill'ы: keyword research, competitor analysis, listing audit
391. `merchant_amazon_products_live_advanced` [amazon][business] INST — данные товаров Amazon (DataForSEO MCP)
392. `merchant_amazon_asin_live_advanced` [amazon][business] INST — ASIN-данные (DataForSEO)
393. `merchant_amazon_sellers_live_advanced` [amazon][business] INST — данные продавцов (DataForSEO)

## G2+ — точечные эксперты (улучшение ≈ расход)

### Программирование / фронт / 3D
394. `frontend-developer` [web][frontend] VOLT — реализация фронта
395. `ui-designer` [design][web] VOLT — UI-дизайн-агент
396. `design-bridge` [design][web] VOLT — мост дизайн↔код
397. `websocket-engineer` [backend][web] VOLT — realtime/WebSocket
398. `electron-pro` [desktop] VOLT — десктоп-приложения (Electron)
399. `godot-gdscript-patterns` [game] WSH — Godot/GDScript

### SEO-специалисты (внешние sub-agents, если мало INST)
400. `seo-programmatic-agent` [seo] GH:claude-seo — программный SEO в масштабе
401. `seo-international-agent` [seo] GH:claude-seo — международный SEO
402. `seo-ecommerce` [seo][amazon] INST — e-commerce SEO (канон, INST)
403. `seo-local` [seo][local] INST — локальный SEO (канон, INST)
404. `seo-maps` [seo][local] INST — maps intelligence (канон, INST)

### Amazon-специалисты
405. `amazon-listing-optimizer` [amazon] GH:nexscope — аудит/оптимизация листинга
406. `amazon-keyword-research` [amazon] GH:nexscope — ключи под листинг/PPC
407. `amazon-competitor-analysis` [amazon] GH:nexscope — анализ конкурентов

## G3+ — дорого, понятный результат

### Полные 3D-сборки
408. `core-3d-animation` (bundle) [3d][animation][web] FTB — полная 3D+анимация сборка (5 скиллов: Three.js, GSAP, R3F, Motion, Babylon)
409. `extended-3d-scroll` (bundle) [3d][web] FTB — полный scroll-experience
410. `web3d-experience-build` [3d][web] GH:ai4brands-design/claude-skills — полный 3D web-experience

### Полные SEO-системы (внешние)
411. `claude-seo full run` [seo] GH:AgriciDaniel/claude-seo — полный аудит (25 sub-skills + 18 агентов, PDF/Excel отчёты)
412. `claude-blog suite` [seo][marketing] GH:AgriciDaniel/claude-blog — 30 sub-skills, blog delivery contract (Google + AI citations)
413. `seomachine` [seo][marketing] GH:TheCraigHewitt/seomachine — workspace для long-form SEO-контента
414. `Agentic-SEO-Skill` [seo] GH:Bhanunamikaze — 16 sub-skills + 10 агентов + 88 evidence-скриптов

### Amazon — полные системы (MCP/SP-API)
415. `amazon-seller-mcp` [amazon] GH:MarceauSolutions/amazon-seller-mcp — open-source SP-API MCP + калькулятор FBA-комиссий 2026 + inventory optimization
416. `DataDoe Amazon MCP` [amazon] EXT — managed Seller/Vendor/Ads/profit (repricer, FBA reimbursement bot, chargeback agent)
417. `agentcentral Amazon MCP` [amazon] EXT — hosted Seller Central + Ads + finance + fulfillment
418. `Amazon Ads MCP (sellermetrics)` [amazon][marketing] EXT — управление PPC через MCP
419. `Porter (SP-API↔Claude)` [amazon] EXT — OAuth/rate-limit/pagination прослойка к SP-API

## Анти-overlap для новых доменов
- **3D web**: точечный движок → один из `threejs-webgl` / `babylonjs-engine` / `playcanvas-engine` (НЕ все сразу). React-стек → `react-three-fiber` (+ `r3f-skills` для глубины). No-code сцены → `spline-interactive`. Комбинирование → `web3d-integration-patterns`. Полная сборка → bundle `core-3d-animation` (G3).
- **Анимация**: React → `motion-framer`; vanilla/scroll → `gsap-scrolltrigger`; физика → `react-spring-physics`; вектор/дизайнер → `rive-interactive`/`lottie-animations`. Один канон на задачу.
- **Web-дизайн**: качество фронта → `modern-web-design` + `ui-ux-pro-max` (INST, канон). НЕ дублировать с `frontend-design-toolkit` (его брать только за MCP/трюки).
- **SEO**: каноны = INST (`seo`, `searchfit-seo:*`, `seo-programmatic`, `seo-geo`, `dataforseo`). Внешние `claude-seo`/`seomachine` — ТОЛЬКО если задача шире установленного. Не запускать INST и внешний SEO-аудит на одно и то же.
- **Amazon**: данные/ресёрч → `merchant_amazon_*` (INST, DataForSEO, канон) + `nexscope` skills. Реальные продажи/инвентарь/PPC/деньги → SP-API MCP (`amazon-seller-mcp` open-source ИЛИ managed DataDoe/agentcentral). DataForSEO ≠ SP-API: первый = публичные SERP/листинги, второй = твой кабинет продавца. Не путать.

---

# ДОПОЛНЕНИЕ E (01.07.2026) — закрытие пробела: QA/accessibility (из честного 4-угольного аудита v1.4)

Аудит по web-design углу нашёл пробел: не было именного visual-regression/accessibility-QA скилла (только generic-упоминания). Проверено `gh repo view` перед добавлением (звёзды/лицензия/активность).

501. `accessibility-agents` [a11y][quality] GH:Community-Access/accessibility-agents — 11 WCAG 2.2 AA специалистов, 348★, MIT, обновлён 29.06.2026
502. `playwright-skill` [test][web] GH:lackeyjb/playwright-skill — Claude Code Skill для браузерной автоматизации Playwright, model-invoked, **2847★**, MIT

Канон: точечная a11y-проверка → `accessibility-tester` (G2, уже в ядре); полный WCAG-прогон → `accessibility-agents` (G3, 11 специалистов). E2E-тесты → канон остаётся `playwright-expert` (0xfurai, tool-уровень); `playwright-skill` — альтернатива с фокусом на автономный browser-QA workflow, не дублировать оба на одну задачу.

**SEO-угол честно проверен и НЕ является пробелом:** research 2026 (Google AI Mode, zero-click, GEO/"Information Gain") подтвердил, что уже установленный канон `seo-geo` (INST, AI Overviews/ChatGPT/Perplexity) адекватно покрывает тренд — новых записей не добавлено, чтобы не дублировать.

---

# ДОПОЛНЕНИЕ B (28.06.2026) — Top-агенты по всем нишам (3-й deep-research)

Широкий заход (GitHub по звёздам + Reddit r/ClaudeCode). Принцип: **G1 экономия токенов → G2 улучшение производительности → G3 макс производительность.** Новые теги: `[ecom][orchestration][jobs][messaging]`. Все внешние (`GH`) — проверить лицензию перед установкой, ставить точечно.

## G1 — экономия токенов (query/knowledge-скиллы)
420. `shopifyql-skill` [ecom][data] GH:devkindhq/shopifyql-skill — пишет/дебажит ShopifyQL и Segment-запросы (детерминированно, без проб)
421. `marketingskills` (CRO/copywriting/analytics) [marketing] GH:coreyhaines31/marketingskills — knowledge-набор по конверсии/копирайтингу/росту
422. `tailwind-expert` [web][design] GH:0xfurai — справочник Tailwind (точные классы → меньше итераций)
423. `rest-expert` [api] GH:0xfurai — REST-конвенции (knowledge)
424. `bash-expert` [shell] GH:0xfurai — bash-эксперт (дополняет наши shell-скиллы)

## G2 — улучшение производительности (tool/library-эксперты, точечно; источник 0xfurai/claude-code-subagents, 928★)
### Базы данных / хранилища (гранулярность инструмента, НЕ дублируют postgres-pro)
425. `redis-expert` [data] GH:0xfurai
426. `mongodb-expert` [data] GH:0xfurai
427. `elasticsearch-expert` [data] GH:0xfurai
428. `opensearch-expert` [data] GH:0xfurai
429. `neo4j-expert` [data] GH:0xfurai — граф
430. `cassandra-expert` [data] GH:0xfurai
431. `dynamodb-expert` [data] GH:0xfurai
432. `vector-db-expert` [data][ai] GH:0xfurai — векторные БД (RAG)
### ORM / миграции
433. `prisma-expert` [data][backend] GH:0xfurai
434. `typeorm-expert` [data] GH:0xfurai
435. `flyway-expert` [data] GH:0xfurai — миграции БД
436. `liquibase-expert` [data] GH:0xfurai
### Очереди / фоновые задачи
437. `celery-expert` [jobs][backend] GH:0xfurai — Python
438. `bullmq-expert` [jobs][backend] GH:0xfurai — Node
439. `sidekiq-expert` [jobs][backend] GH:0xfurai — Ruby
### Messaging / API
440. `kafka-expert` [messaging][data] GH:0xfurai
441. `rabbitmq-expert` [messaging] GH:0xfurai
442. `nats-expert` [messaging] GH:0xfurai
443. `mqtt-expert` [messaging][iot] GH:0xfurai
444. `grpc-expert` [api][backend] GH:0xfurai
445. `trpc-expert` [api][web] GH:0xfurai
### Тестирование (tool-агенты — закрывают пробел между нашими test-скиллами)
446. `playwright-expert` [test] GH:0xfurai — канон E2E-браузер-тестов
447. `cypress-expert` [test] GH:0xfurai
448. `vitest-expert` [test] GH:0xfurai
449. `jest-expert` [test] GH:0xfurai
450. `puppeteer-expert` [test] GH:0xfurai — браузер-автоматизация/скрейпинг
### Сборка / рантаймы
451. `webpack-expert` [devops] GH:0xfurai
452. `bun-expert` [backend][lang] GH:0xfurai
453. `deno-expert` [backend][lang] GH:0xfurai
### Auth / security инструменты
454. `auth0-expert` [security] GH:0xfurai
455. `keycloak-expert` [security] GH:0xfurai
456. `oauth-oidc-expert` [security] GH:0xfurai
457. `jwt-expert` [security] GH:0xfurai
458. `owasp-top10-expert` [security] GH:0xfurai
### Платежи (tool-уровень)
459. `stripe-expert` [payments] GH:0xfurai
460. `braintree-expert` [payments] GH:0xfurai
### Observability
461. `opentelemetry-expert` [ops] GH:0xfurai
462. `loki-expert` [ops] GH:0xfurai
### DS/ML библиотеки
463. `pandas-expert` [data][ml] GH:0xfurai
464. `numpy-expert` [data][ml] GH:0xfurai
465. `scikit-learn-expert` [ml] GH:0xfurai
### Mobile/desktop инструменты
466. `tauri-expert` [desktop] GH:0xfurai — лёгкий десктоп (Rust+web)
467. `swiftui-expert` [mobile] GH:0xfurai
### E-commerce / маркетинг-агенты
468. `Shopify-AI-Toolkit` [ecom] GH:Shopify(official) — products/orders/inventory/GraphQL автоматизация
469. `claude-marketing` (Klaviyo/Shopify/GA4/Looker) [marketing][ecom] GH:thatrebeccarae — 56 скиллов «маркетинг-отдел»
470. `klaviyo-flows` [marketing][ecom] GH:thatrebeccarae — email/SMS-флоу
471. `ga4-analysis` [marketing][analytics] GH:thatrebeccarae — разбор GA4
472. `looker-studio-reporting` [marketing][analytics] GH:thatrebeccarae — отчёты Looker

## G3 — макс производительность (оркестрация/рой/автономные циклы — дорого, мощно)
473. `claude-flow` (Ruflo, 31k★) [orchestration][meta] GH:ruvnet/claude-flow — ведущая платформа swarm-оркестрации, RAG, federation
474. `SPARC` [orchestration][meta] GH:claude-flow — пайплайн spec→pseudocode→architecture→refinement→completion (17 режимов)
475. `metaswarm` [orchestration][meta] GH:dsifry/metaswarm — самоулучшающийся: 18 агентов+13 скиллов, TDD+quality gates, spec-driven
476. `ccswarm` [orchestration][meta] GH:nwiizo/ccswarm — worktree-изоляция, plan→consensus→implement→review→PR
477. `claude-swarm` [orchestration][meta] GH:affaan-m/claude-swarm — декомпозиция задач + rich terminal UI
478. `claude_code_agent_farm` (841★) [orchestration][meta] GH — параллельные Claude-сессии
479. `ralph-claude-code` (837★) [orchestration][meta] GH — автономный dev-цикл с детекцией выхода
480. `claude-code-workflow-orchestration` [orchestration][meta] GH:barkain — плагин: декомпозиция + параллельные агенты + plan mode
481. `gstack` (Garry Tan) [orchestration][meta] GH — мульти-роль setup (product/design/eng/release/docs/QA)
482. `agentsys` (878★) [orchestration][meta] GH — toolkit: плагины+агенты+скиллы+команды

## Анти-overlap для Дополнения B
- **Tool-эксперты (0xfurai) vs язык/фреймворк-про (VOLT/WSH)**: язык целиком → `python-pro`/`typescript-pro` (есть в ядре). Конкретный инструмент/библиотека → `*-expert` (redis/kafka/prisma/playwright). Бери expert ТОЛЬКО когда задача про сам инструмент. Не оба сразу.
- **E2E-тесты**: канон tool-агент → `playwright-expert`; паттерны → `e2e-testing-patterns` (skill, G1). Один на задачу.
- **Оркестрация**: встроенная координация (1 коллекция агентов) → `multi-agent-coordinator`/`codebase-orchestrator` (VOLT, уже в ядре). Тяжёлый внешний автономный рой → `claude-flow`/`metaswarm`/`ccswarm` (G3). Внешний рой = много токенов и автономные правки → ТОЛЬКО под явную задачу и с подтверждением. Не запускать встроенную и внешнюю оркестрацию одновременно.
- **E-com/маркетинг**: Shopify-данные → `shopifyql-skill` (G1); автоматизация магазина → `Shopify-AI-Toolkit`; полный маркетинг-отдел (Klaviyo/GA4/Looker) → `claude-marketing` (G2/G3). Amazon ≠ Shopify — разные каналы, не смешивать каноны.

---

# ДОПОЛНЕНИЕ C (28.06.2026) — финальный заход: официальный Anthropic + наблюдаемость/eval

Закрывает 2 реальных пробела: (1) **официальный маркетплейс Anthropic** (vetted, приоритет №1 над community); (2) **agent observability / eval / cost** (был P1-пробелом из ревью). Новые теги: `[eval][observability]`. Source: `ANTH-OFF` = официальный маркетплейс Anthropic (`/plugin marketplace add anthropics/claude-plugins-official` или `anthropics/skills`) = **verified by Anthropic**.

## G1 — экономия токенов (официальные детерминированные)
483. `anthropic:commit-commands` [git][meta] ANTH-OFF — структурированные коммиты (official)
484. `anthropic:security-guidance` [security] ANTH-OFF — официальные security-подсказки
485. `otel-tracing-setup` [observability][ai] — OpenTelemetry для Claude Code: спаны `claude_code.llm_request` (модель/латентность/токены) и `claude_code.tool`; экспорт в OTLP (Honeycomb/Datadog/Grafana/Langfuse)

## G2 — улучшение производительности
### Официальные воркфлоу Anthropic (приоритет над community-аналогами)
486. `anthropic:feature-dev` [meta][quality] ANTH-OFF — официальный feature-development воркфлоу
487. `anthropic:code-review` [quality] ANTH-OFF — официальное код-ревью (канон-приоритет; community `code-reviewer` — альтернатива)
488. `knowledge-work:sales` [sales] ANTH-OFF — официальный sales-плагин (Anthropic open-sourced)
489. `knowledge-work:legal` [legal] ANTH-OFF — официальный legal
490. `knowledge-work:finance` [finance] ANTH-OFF — официальный finance
491. `knowledge-work:data` [data] ANTH-OFF — официальный data
### Наблюдаемость / eval / guardrails (закрывает P1)
492. `agent-observability` [observability][ai] GH:nexus-labs-automation — LLM-трейсинг, tool calls, мульти-агент координация, cost tracking (14 скиллов)
493. `llm-eval-unit` [eval][test][ai] — unit-evals: роутер выбрал ветку, tool-output = валидный JSON по схеме, retrieval вернул ≥1 релевантный док, дата = ISO-8601
494. `prompt-ab-testing` [eval][ai] GH:nexus-labs — A/B-тест промптов
495. `guardrails-decision-tracing` [ai][security] GH:nexus-labs — guardrails + трассировка решений
496. `datadog-llm-observability` [observability][ai] EXT — Datadog LLM Observability (skills + MCP)
497. `langfuse-tracing` [observability][ai] — Langfuse как OTLP-бэкенд (есть self-host)

## G3 — макс производительность (полные eval/observability системы)
498. `three-layer-eval-suite` [eval][test][ai] — полный eval агента: unit → integration → e2e, разные каденции (best practice 2026)
499. `cost-anomaly-monitor` [observability][ai] — Agent Console: детект cost-draining (skipped checks / retry loops / file rereads) → линк на фиксы
500. `rohitg00:awesome-claude-code-toolkit` [meta] GH — индекс-источник: 135 агентов / 35 скиллов / 176 плагинов / 20 хуков (для будущего расширения)

## Анти-overlap для Дополнения C
- **Официальное > community при равном качестве.** `anthropic:code-review` / наш INST `code-review` — канон; WSH `code-reviewer` — альтернатива. `anthropic:frontend-design` ≈ INST `frontend-design` → не дублировать. `knowledge-work:*` (официальные sales/legal/finance/data) приоритетнее community-аналогов в ядре.
- **Наблюдаемость**: настройка трейсинга → `otel-tracing-setup` (канон, official-паттерн); полная платформа → `agent-observability` (G2) или managed `datadog-llm-observability` (G3/EXT). Не ставить две системы наблюдаемости сразу.
- **Eval**: быстрые проверки шага → `llm-eval-unit` (G2); полный прогон → `three-layer-eval-suite` (G3). Связаны с нашим `40-quality-gate` (детерминированные проверки) — eval автоматизирует то, что чеклист проверяет вручную.

---

# ДОПОЛНЕНИЕ J (01.07.2026) — full-stack project starter (не skill/agent, а стартер-темплейт)

Проверено: di-sukharev/vibe, 283★, Apache 2.0, обновлён 20.06.2026, 46 форков, 1 open issue, реальные unit+integration+e2e тесты (Playwright), DO+Yandex Cloud деплой-автоматизация с собственными тестами. Автор известен по opencommit.

2027. `vibe-template-web` [web][backend][infra] GH:di-sukharev/vibe (master) — full-stack стартер: Bun/Hono backend + React CSR webapp + Astro SSG/SSR website + shared API-контракты. Для нового full-stack web-проекта БЕЗ мобильного клиента. Встроенный агент-intake протокол (свой CLAUDE.md/AGENTS.md), DigitalOcean+Yandex Cloud деплой.
2028. `vibe-template-mobile` [web][mobile][backend][infra] GH:di-sukharev/vibe (mobile branch) — тот же стек + Expo mobile app, payments, Expo Push, Maestro E2E. Использовать вместо web-варианта, когда мобильный клиент нужен с самого начала.

Канон: при старте НОВОГО full-stack проекта (web±mobile) — рассмотреть как стартовую точку через `product-builder` skill, вместо scaffolding с нуля. Не путать с нашим `project-bootstrap` (тот — для самой Claude MD OS, не для пользовательского продукта).

---

# ДОПОЛНЕНИЕ K (01.07.2026) — массовое расширение до 2000+ (VoltAgent/awesome-agent-skills 1174 записей от официальных команд Vercel/Stripe/Cloudflare/Netlify/Supabase/etc + community; srednoff-os 306 собственных named-скиллов Ивана). Источник trust: OFFICIAL > SREDNOFF/VOLT-SK > обычный GH (гейт верификации те же правила).

## G1 (mass expansion, 253 records)

503. `anthropics:theme-factory` [design][ai] OFFICIAL — Style artifacts with professional themes or generate custom themes
504. `anthropics:internal-comms` [ai] OFFICIAL — Write status reports, newsletters, and FAQs
505. `anthropics:template` [ai] OFFICIAL — Basic template for creating new skills
506. `voltagent:create-voltagent` [ai][shell] OFFICIAL — Project setup guide with CLI and manual steps
507. `voltagent:voltagent-best-practices` [ai][arch] OFFICIAL — Architecture and usage patterns for agents, workflows, memory, and servers
508. `voltagent:voltagent-core-reference` [ai] OFFICIAL — Reference for the VoltAgent class options and lifecycle methods
509. `testmu-ai:appium-skill` [ai][mobile] OFFICIAL — Generate Appium mobile automation for Android and iOS in Java, Python, or JS
510. `testmu-ai:behat-skill` [ai][test] OFFICIAL — Generate Behat BDD tests for PHP with Gherkin and Mink
511. `testmu-ai:behave-skill` [ai][test] OFFICIAL — Generate Behave BDD tests for Python with Gherkin and step implementations
512. `testmu-ai:capybara-skill` [ai][test] OFFICIAL — Generate Capybara E2E tests in Ruby with RSpec integration
513. `testmu-ai:cicd-pipeline-skill` [ai][devops][test] OFFICIAL — Generate CI/CD pipelines for tests on GitHub Actions, Jenkins, GitLab CI, and Azure DevOps
514. `testmu-ai:codeception-skill` [ai][test] OFFICIAL — Generate Codeception acceptance, functional, and unit tests in PHP
515. `testmu-ai:cucumber-skill` [ai][test] OFFICIAL — Generate Cucumber BDD tests with Gherkin and step definitions in Java, JS, or Ruby
516. `testmu-ai:cypress-skill` [ai][test][frontend] OFFICIAL — Generate Cypress E2E and component tests in JavaScript or TypeScript
517. `testmu-ai:detox-skill` [ai][test][mobile][frontend] OFFICIAL — Generate Detox gray-box E2E tests for React Native apps in JavaScript
518. `testmu-ai:espresso-skill` [ai][test][mobile] OFFICIAL — Generate Espresso UI tests for Android apps in Kotlin or Java
519. `testmu-ai:flutter-testing-skill` [ai][test] OFFICIAL — Generate Flutter widget, integration, and golden tests in Dart
520. `testmu-ai:gauge-skill` [ai] OFFICIAL — Generate Gauge specs in Markdown with steps in Java, Python, JS, or Ruby
521. `testmu-ai:geb-skill` [ai] OFFICIAL — Generate Geb browser automation in Groovy with Spock and page objects
522. `testmu-ai:hyperexecute-skill` [ai] OFFICIAL — Operate TestMu AI HyperExecute end-to-end: YAML, CLI runs, debugging, and CI wiring
523. `testmu-ai:jasmine-skill` [ai][test] OFFICIAL — Generate Jasmine BDD tests in JavaScript with spies and async support
524. `testmu-ai:jest-skill` [ai][test] OFFICIAL — Generate Jest unit and integration tests in JS/TS with mocking and snapshots
525. `testmu-ai:junit-5-skill` [ai][test] OFFICIAL — Generate JUnit 5 unit and integration tests in Java with Mockito
526. `testmu-ai:karma-skill` [ai][test] OFFICIAL — Generate Karma test-runner configs for browser-based JS testing
527. `testmu-ai:laravel-dusk-skill` [ai][test] OFFICIAL — Generate Laravel Dusk Chrome-based browser tests in PHP
528. `testmu-ai:lettuce-skill` [ai][test] OFFICIAL — Generate Lettuce BDD tests for Python (legacy; prefer Behave)
529. `testmu-ai:mocha-skill` [ai][test] OFFICIAL — Generate Mocha tests in JavaScript with Chai and Sinon
530. `testmu-ai:mstest-skill` [ai][test] OFFICIAL — Generate MSTest tests in C# for .NET
531. `testmu-ai:nemojs-skill` [ml][ai][test] OFFICIAL — Generate Nemo.js Selenium-based tests for Node.js
532. `testmu-ai:nightwatchjs-skill` [ai][test] OFFICIAL — Generate NightwatchJS E2E tests in JavaScript with Selenium WebDriver
533. `testmu-ai:nunit-skill` [ai][test] OFFICIAL — Generate NUnit 3 tests in C# with the constraint model and Moq
534. `testmu-ai:phpunit-skill` [ai][test] OFFICIAL — Generate PHPUnit tests in PHP with data providers and mocking
535. `testmu-ai:playwright-skill` [ai][test] OFFICIAL — Generate Playwright E2E tests in TS, JS, Python, Java, or C#
536. `testmu-ai:protractor-skill` [ai][test][frontend] OFFICIAL — Generate Protractor E2E tests for Angular in JS/TS (deprecated; prefer Playwright/Cypress)
537. `testmu-ai:puppeteer-skill` [ai] OFFICIAL — Generate Puppeteer scripts for browser automation, scraping, and PDF generation
538. `testmu-ai:pytest-skill` [ai][test] OFFICIAL — Generate pytest tests in Python with fixtures, parametrize, and mocking
539. `testmu-ai:reqnroll-skill` [ai][test][mobile] OFFICIAL — Generate Reqnroll BDD tests for web and mobile in C#
540. `testmu-ai:robot-framework-skill` [ai][test] OFFICIAL — Generate Robot Framework keyword-driven tests in Python
541. `testmu-ai:rspec-skill` [ai][test] OFFICIAL — Generate RSpec tests in Ruby with matchers, hooks, and mocking
542. `testmu-ai:selenide-skill` [ai][test][backend] OFFICIAL — Generate Selenide UI tests in Java with auto-waits and a fluent API
543. `testmu-ai:selenium-skill` [ai][test] OFFICIAL — Generate Selenium WebDriver tests in Java, Python, JS, C#, Ruby, or PHP
544. `testmu-ai:serenity-bdd-skill` [ai][test] OFFICIAL — Generate Serenity BDD tests in Java with the Screenplay pattern and reporting
545. `testmu-ai:smartui-skill` [design][ai] OFFICIAL — Generate SmartUI visual regression configs for screenshot comparison
546. `testmu-ai:specflow-skill` [ai][test] OFFICIAL — Generate SpecFlow BDD tests for C#/.NET with Gherkin and step bindings
547. `testmu-ai:testcafe-skill` [ai][test] OFFICIAL — Generate TestCafe automation tests in JavaScript or TypeScript
548. `testmu-ai:testng-skill` [ai][test] OFFICIAL — Generate TestNG tests in Java with data providers and parallel execution
549. `testmu-ai:testunit-skill` [ai][test] OFFICIAL — Generate Test::Unit xUnit-style tests in Ruby
550. `testmu-ai:unittest-skill` [ai][test] OFFICIAL — Generate Python unittest tests with TestCase and setUp/tearDown
551. `testmu-ai:vitest-skill` [ai][test][backend] OFFICIAL — Generate Vitest tests in JS/TS with a Jest-compatible API and ESM
552. `testmu-ai:webdriverio-skill` [ai][test] OFFICIAL — Generate WebdriverIO (WDIO) automation tests in JavaScript or TypeScript
553. `testmu-ai:xcuitest-skill` [ai][test][mobile] OFFICIAL — Generate XCUITest UI tests for iOS/iPadOS apps in Swift
554. `testmu-ai:xunit-skill` [ai][test] OFFICIAL — Generate xUnit.net tests in C# with Fact/Theory and FluentAssertions
555. `zero:zero-gemini` [payments] OFFICIAL — Same Zero tool-discovery and payment layer packaged as a Gemini CLI extension
556. `angular:angular-developer` [frontend] OFFICIAL — Generate Angular code and architectural guidance for components, services, reactivity
557. `angular:angular-new-app` [frontend] OFFICIAL — Create new Angular apps using CLI with modern best practices
558. `supabase:postgres-best-practices` [data] OFFICIAL — PostgreSQL best practices for Supabase
559. `google-gemini:gemini-api-dev` [backend] OFFICIAL — Best practices for developing Gemini-powered apps using the Gemini API
560. `stripe:stripe-best-practices` [payments] OFFICIAL — Best practices for building Stripe integrations
561. `callstackincubator:react-native-best-practices` [mobile][perf][frontend] OFFICIAL — Performance optimization for React Native apps from Callstack
562. `callstackincubator:upgrading-react-native` [mobile][frontend] OFFICIAL — React Native upgrade workflow: templates, dependencies, and common pitfalls
563. `better-auth:best-practices` [security] OFFICIAL — Best practices for Better Auth integration
564. `better-auth:create-auth` [security] OFFICIAL — Create authentication setup with Better Auth
565. `tinybirdco:tinybird-best-practices` [data] OFFICIAL — Tinybird project guidelines for datasources, pipes, endpoints, and SQL
566. `tinybirdco:tinybird-cli-guidelines` [data] OFFICIAL — Tinybird CLI usage guidelines and commands
567. `hashicorp:new-terraform-provider` [infra] OFFICIAL — Scaffold a new Terraform provider project using the Plugin Framework
568. `hashicorp:terraform-style-guide` [infra] OFFICIAL — Generate Terraform HCL code following HashiCorp's official style conventions
569. `sanity-io:sanity-best-practices` [design][docs] OFFICIAL — Best practices for Sanity Studio, GROQ queries, and content workflows
570. `sanity-io:content-modeling-best-practices` [design][docs] OFFICIAL — Guidelines for designing scalable content models in Sanity
571. `sanity-io:seo-aeo-best-practices` [seo] OFFICIAL — SEO and answer engine optimization patterns for content sites
572. `sanity-io:content-experimentation-best-practices` [test] OFFICIAL — Content A/B testing and experimentation workflows
573. `neondatabase:neon-postgres` [data] OFFICIAL — Best practices for Neon Serverless Postgres
574. `clickhouse:clickhouse-best-practices` [data] OFFICIAL — Best practices for working with ClickHouse
575. `clickhouse:clickhouse-architecture-advisor` [data] OFFICIAL — Design ClickHouse architectures and translate best practices into workload-specific decisions
576. `veniceai:venice-image-generate` [ai][api] OFFICIAL — Image generation endpoints and available styles
577. `veniceai:venice-errors` [backend] OFFICIAL — Error handling, retries, and API status codes
578. `vercel-labs:next-best-practices` [frontend] OFFICIAL — Next.js best practices and recommended patterns
579. `cloudflare:workers-best-practices` [infra][devops] OFFICIAL — Review and author Workers code against production best practices and wrangler.jsonc conventions
580. `netlify:netlify-config` [infra][devops] OFFICIAL — Reference for netlify.toml site configuration
581. `netlify:netlify-cli-and-deploy` [devops] OFFICIAL — CLI setup, local dev, and deployment workflows
582. `google-labs-code:remotion` [animation] OFFICIAL — Generate walkthrough videos from Stitch app designs
583. `googleworkspace:gws-modelarmor` [docs][ops] OFFICIAL — Filter user-generated content for safety
584. `expo:expo-tailwind-setup` [design][mobile] OFFICIAL — Set up Tailwind CSS v4 in Expo with NativeWind v5
585. `huggingface:hf-cli` [ml][ai][ops][shell] OFFICIAL — HF CLI tool for Hub operations
586. `trailofbits:culture-index` [docs] OFFICIAL — Index and search culture documentation
587. `trailofbits:dwarf-expert` [security][test] OFFICIAL — DWARF debugging format expertise
588. `trailofbits:modern-python` [security] OFFICIAL — Modern Python tooling with uv, ruff, ty, and pytest best practices
589. `getsentry:sentry-sdk-setup` [ops] OFFICIAL — Set up Sentry in any language or framework — detects platform and routes to the right SDK
590. `getsentry:sentry-feature-setup` [ai][devops][ops] OFFICIAL — Configure advanced Sentry features: AI monitoring, OTel pipelines, and alerts
591. `getsentry:sentry-otel-exporter-setup` [ops] OFFICIAL — Configure the OpenTelemetry Collector with Sentry Exporter
592. `getsentry:sentry-setup-ai-monitoring` [ai][ops] OFFICIAL — Instrument OpenAI, Anthropic, Vercel AI, LangChain, Google GenAI, and Pydantic AI
593. `getsentry:sentry-android-sdk` [mobile][ops] OFFICIAL — Full Sentry SDK setup for Android (Kotlin and Java)
594. `getsentry:sentry-browser-sdk` [ops] OFFICIAL — Full Sentry SDK setup for browser JavaScript
595. `getsentry:sentry-cloudflare-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Cloudflare Workers, Pages, Durable Objects, Queues, and Workflows
596. `getsentry:sentry-cocoa-sdk` [mobile][ops] OFFICIAL — Full Sentry SDK setup for Apple platforms (iOS, macOS, tvOS, watchOS, visionOS)
597. `getsentry:sentry-dotnet-sdk` [ops] OFFICIAL — Full Sentry SDK setup for .NET (ASP.NET Core, MAUI, WPF, WinForms, Blazor, Azure Functions)
598. `getsentry:sentry-elixir-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Elixir, Phoenix, Plug, LiveView, Oban, and Quantum
599. `getsentry:sentry-flutter-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Flutter and Dart across all platforms
600. `getsentry:sentry-go-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Go (net/http, Gin, Echo, Fiber, FastHTTP, Iris, Negroni)
601. `getsentry:sentry-nestjs-sdk` [ops][backend] OFFICIAL — Full Sentry SDK setup for NestJS with Express or Fastify, GraphQL, microservices
602. `getsentry:sentry-nextjs-sdk` [ops][frontend] OFFICIAL — Full Sentry SDK setup for Next.js 13+ (App Router and Pages Router)
603. `getsentry:sentry-node-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Node.js, Bun, and Deno
604. `getsentry:sentry-php-sdk` [ops] OFFICIAL — Full Sentry SDK setup for PHP, Laravel, and Symfony
605. `getsentry:sentry-python-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Python (Django, Flask, FastAPI, Celery, Starlette, AIOHTTP, Tornado)
606. `getsentry:sentry-react-native-sdk` [mobile][ops][frontend] OFFICIAL — Full Sentry SDK setup for React Native and Expo
607. `getsentry:sentry-react-sdk` [ops][frontend] OFFICIAL — Full Sentry SDK setup for React (React Router v5-v7, TanStack Router, Redux, Vite, webpack)
608. `getsentry:sentry-ruby-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Ruby (Rails, Sinatra, Rack, Sidekiq, Resque)
609. `getsentry:sentry-svelte-sdk` [ops] OFFICIAL — Full Sentry SDK setup for Svelte and SvelteKit
610. `microsoft:azure-mgmt-apicenter-dotnet` [backend] OFFICIAL — API inventory and governance
611. `microsoft:azure-mgmt-apicenter-py` [backend] OFFICIAL — API inventory and governance
612. `microsoft:azure-monitor-opentelemetry-py` [infra][devops] OFFICIAL — One-line Application Insights setup
613. `microsoft:azure-appconfiguration-ts` [infra][devops] OFFICIAL — App config, feature flags, dynamic refresh
614. `fal-ai-community:fal-3d` [3d][ai] OFFICIAL — Generate 3D models from text or images
615. `fal-ai-community:fal-generate` [ai] OFFICIAL — Generate images and videos using fal.ai AI models
616. `fal-ai-community:fal-kling-o3` [ai] OFFICIAL — Generate images and videos with Kling O3 — Kling's most powerful model family
617. `fal-ai-community:fal-workflow` [ai] OFFICIAL — Generate workflow JSON files for chaining AI models
618. `WordPress:wp-block-themes` [design] OFFICIAL — Block themes: theme.json, templates, patterns, style variations
619. `WordPress:wp-wpcli-and-ops` [design][docs][ops][shell] OFFICIAL — WP-CLI commands, automation, multisite, search-replace
620. `openai:gh-address-comments` [ai] OFFICIAL — Address review and issue comments on open GitHub PRs via CLI
621. `openai:imagegen` [ai][backend] OFFICIAL — Generate and edit images using OpenAI's Image API for projects
622. `openai:netlify-deploy` [ai][devops][security] OFFICIAL — Automate Netlify deployments with CLI auth, linking, and environment support
623. `openai:security-best-practices` [ai][security] OFFICIAL — Review code for language-specific security vulnerabilities
624. `openai:security-threat-model` [ai][security] OFFICIAL — Generate repo-specific threat models identifying trust boundaries
625. `openai:sora` [ai][backend] OFFICIAL — Generate, remix, and manage short video clips via OpenAI's Sora API
626. `openai:speech` [ai][backend] OFFICIAL — Generate spoken audio from text using OpenAI's API with built-in voices
627. `openai:yeet` [ai] OFFICIAL — Stage, commit, push code, and open a GitHub pull request via CLI
628. `openai:chatgpt-apps` [ai][backend] OFFICIAL — Build, scaffold, and troubleshoot ChatGPT Apps SDK apps with MCP server and widget UI
629. `openai:figma-generate-design` [design][ai] OFFICIAL — Translate app pages and layouts into Figma using design system tokens
630. `openai:figma-generate-library` [design][ai] OFFICIAL — Build or update a professional-grade design system in Figma from a codebase
631. `figma:figma-create-design-system-rules` [design] OFFICIAL — Generate project-specific design system rules for Figma-to-code workflows
632. `figma:figma-generate-design` [design][frontend] OFFICIAL — Build or update screens in Figma from code or description using design system components
633. `figma:figma-generate-library` [design] OFFICIAL — Build or update a design system library in Figma from a codebase
634. `coreyhaines31:ab-test-setup` [test] OFFICIAL — Plan and implement A/B tests or experiments for any digital experience
635. `coreyhaines31:ad-creative` [marketing] OFFICIAL — Generate and iterate ad creative including headlines, descriptions, and primary text
636. `coreyhaines31:ai-seo` [seo][ai] OFFICIAL — Optimize content to appear in AI-generated answers and LLM search results
637. `coreyhaines31:marketing-ideas` [marketing] OFFICIAL — Generate marketing strategies and campaign ideas for SaaS products
638. `coreyhaines31:programmatic-seo` [seo] OFFICIAL — Build SEO-driven page templates for large-scale content generation
639. `realkimbarrett:headline-matrix` [marketing] OFFICIAL — Generate high-performing headline variations across different angles
640. `apollographql:graphql-operations` [test][backend] OFFICIAL — Write GraphQL queries, mutations, and subscriptions following best practices
641. `apollographql:graphql-schema` [seo][backend] OFFICIAL — Reference guide for designing clean, evolvable GraphQL schemas
642. `apollographql:rover` [seo][backend] OFFICIAL — CLI tool for managing GraphQL schemas in Apollo GraphOS
643. `apollographql:rust-best-practices` [backend] OFFICIAL — Rust coding guidelines drawn from Apollo GraphQL's internal handbook
644. `auth0:auth0-quickstart` [security] OFFICIAL — Detect your framework and scaffold Auth0 integration automatically
645. `brave:answers` [ai] OFFICIAL — AI-generated answers grounded in live web search results
646. `brave:bx` [ai] OFFICIAL — CLI tool for web search built for AI agents
647. `brave:local-descriptions` [ai] OFFICIAL — Fetch AI-generated text descriptions for points of interest
648. `brave:news-search` [research][mobile] OFFICIAL — Search Brave's news index with article metadata
649. `browserbase:browser` [test][shell] OFFICIAL — Automate web browser interactions through natural language CLI commands
650. `browserbase:browserbase-cli` [test][shell] OFFICIAL — CLI wrapper around the Browserbase platform
651. `browserbase:fetch` [backend] OFFICIAL — Fetch HTML, JSON, headers, and status codes through the Browserbase API
652. `coderabbitai:code-review` [ai] OFFICIAL — Run AI-powered code reviews through the CodeRabbit CLI
653. `coinbase:monetize-service` [backend] OFFICIAL — Scaffold an Express server that charges USDC per request using x402
654. `datadog-labs:dd-docs` [ai][docs][ops] OFFICIAL — Look up Datadog documentation via the LLM-optimized docs index
655. `datadog-labs:dd-llmo-eval-bootstrap` [ml][ai][ops] OFFICIAL — Analyze production LLM traces and generate evaluators
656. `datadog-labs:dd-logs` [ops] OFFICIAL — Search, filter, and archive Datadog logs through pup CLI
657. `datadog-labs:dd-monitors` [ops] OFFICIAL — Manage Datadog monitors through the pup CLI
658. `datadog-labs:dd-pup` [ops][backend] OFFICIAL — Rust-based CLI (pup) for talking to the Datadog API
659. `firebase:firebase-basics` [security] OFFICIAL — Handle Firebase CLI install, auth, and day-to-day workflow
660. `deanpeters:finance-metrics-quickref` [finance] OFFICIAL — Reference guide for 32+ SaaS finance metrics with formulas and benchmarks
661. `deanpeters:opportunity-solution-tree` [test] OFFICIAL — Generate opportunities and solutions and recommend proof-of-concept tests
662. `phuryn:sql-queries` [data] OFFICIAL — Generate SQL queries from natural language across major dialects
663. `phuryn:create-prd` [devops] OFFICIAL — Create a PRD with 8-section template covering problem to release
664. `phuryn:dummy-dataset` [data] OFFICIAL — Generate realistic dummy datasets in CSV, JSON, or SQL
665. `phuryn:job-stories` [product][pm] OFFICIAL — Create job stories with acceptance criteria in JTBD format
666. `phuryn:prioritization-frameworks` [product][pm] OFFICIAL — Reference guide to 9 prioritization frameworks with templates
667. `phuryn:release-notes` [devops][docs] OFFICIAL — Generate user-facing release notes from tickets or changelogs
668. `phuryn:wwas` [product][pm] OFFICIAL — Create backlog items in Why-What-Acceptance format
669. `phuryn:marketing-ideas` [marketing] OFFICIAL — Generate 5 creative, cost-effective marketing ideas with rationale
670. `phuryn:value-prop-statements` [marketing][sales] OFFICIAL — Generate value prop statements for marketing, sales, and onboarding
671. `phuryn:business-model` [product][pm][business] OFFICIAL — Generate Business Model Canvas with all 9 building blocks
672. `phuryn:lean-canvas` [product][pm] OFFICIAL — Generate Lean Canvas with problem, solution, UVP, and metrics
673. `phuryn:startup-canvas` [product][pm][business] OFFICIAL — Generate Startup Canvas combining Product Strategy and Business Model
674. `phuryn:value-proposition` [product][pm] OFFICIAL — Design value propositions using 6-part JTBD template
675. `phuryn:review-resume` [product][pm] OFFICIAL — PM resume review against 10 best practices including XYZ+S formula
676. `MiniMax-AI:cli` [ai] OFFICIAL — Generate text, image, video, speech, and music via MiniMax AI
677. `MiniMax-AI:frontend-dev` [animation][ai][frontend][backend] OFFICIAL — Full-stack frontend with cinematic animations, AI-generated media via MiniMax API, and generative art
678. `MiniMax-AI:minimax-pdf` [design][ai] OFFICIAL — Generate, fill, and reformat PDFs with a token-based design system and 15 cover styles
679. `MiniMax-AI:minimax-xlsx` [ai] OFFICIAL — Create, read, analyze, and validate Excel/spreadsheet files with zero format loss
680. `duckdb:install-duckdb` [data] OFFICIAL — Install or update DuckDB CLI and extensions with version management
681. `garrytan:qa` [sales][test] OFFICIAL — QA Lead: test your app, find bugs, fix them with atomic commits, auto-generate regression tests
682. `garrytan:setup-browser-cookies` [product][meta] OFFICIAL — Import cookies from your real browser into the headless session
683. `garrytan:codex` [ai] OFFICIAL — Second Opinion via OpenAI Codex CLI: review, adversarial challenge, and open consultation
684. `garrytan:setup-deploy` [3d][devops] OFFICIAL — Deploy Configurator: one-time setup for /land-and-deploy
685. `resend:email-best-practices` [email] OFFICIAL — Email deliverability and design best practices
686. `resend:resend-cli` [email] OFFICIAL — Resend CLI commands and workflows
687. `addyosmani:best-practices` [security] OFFICIAL — Security, modern web APIs, and code quality patterns
688. `mongodb:mongodb-mcp-setup` [data][backend] OFFICIAL — Set up the MongoDB MCP server with authentication and connection configuration
689. `mongodb:mongodb-schema-design` [seo][data] OFFICIAL — Design efficient document schemas with validation and indexing patterns
690. `redis:redis-development` [data][perf] OFFICIAL — Redis development best practices — data structures, query engine, vector search, caching, and performance optimization.
691. `NVIDIA:Megatron-Bridge:build-and-dependency` [ml] OFFICIAL — Dev environment setup for Megatron Bridge — container-based development, uv package management, lockfile regeneration, adding dependencies, 
692. `NVIDIA:Megatron-Bridge:bump-dependency` [ml][devops] OFFICIAL — Bump a pinned dependency (TransformerEngine, Megatron-LM, NRX, etc.), regenerate the lockfile, open a PR, and drive it to green by attaching
693. `NVIDIA:Megatron-Bridge:cicd` [ml][devops] OFFICIAL — CI/CD reference for Megatron Bridge — pipeline structure, commit and PR workflow, CI failure investigation, and common failure patterns.
694. `NVIDIA:Megatron-Bridge:perf-hierarchical-context-parallel` [ml] OFFICIAL — Operational guide for enabling hierarchical context parallelism in Megatron-Bridge, including config knobs, code anchors, pitfalls, and veri
695. `NVIDIA:Megatron-Bridge:perf-megatron-fsdp` [ml] OFFICIAL — Operational guide for enabling Megatron FSDP in Megatron-Bridge, including config knobs, code anchors, pitfalls, and verification.
696. `NVIDIA:Megatron-Bridge:perf-tp-dp-comm-overlap` [ml] OFFICIAL — Operational guide for enabling TP, DP, and PP communication overlap in Megatron-Bridge, including config knobs, code anchors, pitfalls, and 
697. `NVIDIA:Megatron-Bridge:testing` [ml][test] OFFICIAL — Testing reference for Megatron Bridge — unit and functional test layout, tier semantics (L0/L1/L2/flaky), script conventions, running tests 
698. `NVIDIA:Megatron-Core:build-and-dependency` [ml] OFFICIAL — Container-based dev environment setup and dependency management for Megatron-LM.
699. `NVIDIA:Megatron-Core:cicd` [ml][devops] OFFICIAL — CI/CD reference for Megatron-LM.
700. `NVIDIA:NeMo-Evaluator-Launcher:nel-assistant` [ml] OFFICIAL — Interactive config wizard for NeMo Evaluator Launcher (NEL).
701. `NVIDIA:NeMo-RL:cicd` [ml][devops] OFFICIAL — CI/CD reference for NeMo-RL.
702. `NVIDIA:NeMo-RL:config-conventions` [ml] OFFICIAL — Configuration conventions for NeMo-RL.
703. `NVIDIA:NeMo-RL:launch-nemo-rl` [ml][infra][ops] OFFICIAL — Playbook for launching, monitoring, stopping, and debugging NeMo-RL recipes on a Kubernetes cluster via the nrl-k8s CLI.
704. `NVIDIA:NemoClaw:nemoclaw-contributor-create-pr` [ml] OFFICIAL — Create GitHub pull requests that follow the NemoClaw PR template.
705. `NVIDIA:NemoClaw:nemoclaw-contributor-update-docs` [ml][devops][docs] OFFICIAL — Scan recent git commits for changes that affect user-facing behavior, then draft or update the corresponding documentation pages and refresh
706. `NVIDIA:NemoClaw:nemoclaw-user-manage-sandboxes` [ml] OFFICIAL — Explains operational tasks after the quickstart: listing sandboxes, status and health checks, logs, diagnostics, port forwards, multiple san
707. `NVIDIA:TensorRT-LLM:ad-accuracy-debug` [ml][ai][devops][backend] OFFICIAL — > Debug AutoDeploy accuracy regressions vs a reference score (PyTorch backend or published baseline).
708. `NVIDIA:TensorRT-LLM:ad-model-onboard` [ai][devops][test] OFFICIAL — > Translates a HuggingFace model into a prefill-only AutoDeploy custom model using reference custom ops, validates with hierarchical equival
709. `NVIDIA:TensorRT-LLM:perf-nsight-systems` [ai] OFFICIAL — >- Nsight Systems (nsys) CLI for system-level timeline profiling.
710. `NVIDIA:TensorRT-LLM:trtllm-code-contribution` [ai] OFFICIAL — > Best practices for contributing code to TensorRT-LLM.
711. `NVIDIA:TensorRT-LLM:trtllm-serve-config-guide` [ml][ai][devops] OFFICIAL — Generate a source-backed starting `trtllm-serve --config` YAML for basic aggregate single-node PyTorch serving, aligned with checked-in Tens
712. `NVIDIA:cuopt:cuopt-numerical-optimization-api-cli` [backend] OFFICIAL — LP, MILP, and QP (beta) with cuOpt — CLI only (MPS files, cuopt_cli).
713. `NVIDIA:video-search-and-summarization:deploy` [devops] OFFICIAL — Deploy, debug, or tear down any VSS profile using a compose-centric workflow — config (dry-run) with env overrides, review resolved compose,
714. `NVIDIA:video-search-and-summarization:report` [devops] OFFICIAL — Produce video analysis reports by discovering the deployed VSS agent, querying POST /generate for a timestamped captioned summary of the cli
715. `NVIDIA:video-search-and-summarization:vss-frag` [ml] OFFICIAL — Generate video summary reports using the VSS video_search_frag extension with Long Video Summarization (LVS), Enterprise RAG knowledge retri
716. `google:cloud:cloud-sql-basics` [data][infra] OFFICIAL — This file generates or explains Cloud SQL resources.
717. `google:cloud:google-cloud-recipe-onboarding` [infra][devops][finance][payments] OFFICIAL — Guidance for a developer's first steps on Google Cloud, covering account creation, billing setup, project management, and deploying a first 
718. `google:cloud:google-cloud-waf-cost-optimization` [marketing][infra] OFFICIAL — Generates cost optimization guidance for Google Cloud workloads based on the Google Cloud Well-Architected Framework (WAF).
719. `google:cloud:google-cloud-waf-operational-excellence` [3d][marketing][infra] OFFICIAL — Generates operations-focused guidance for Google Cloud workloads based on the design principles and recommendations in the Operational Excel
720. `google:cloud:google-cloud-waf-performance-optimization` [marketing][infra][perf] OFFICIAL — Generates performance-focused guidance for Google Cloud workloads based on the design principles and recommendations in the Performance Opti
721. `google:cloud:google-cloud-waf-reliability` [marketing][infra] OFFICIAL — Generates reliability-focused guidance for Google Cloud workloads based on the design principles and recommendations in the Google Cloud Wel
722. `google:cloud:google-cloud-waf-security` [marketing][infra][security] OFFICIAL — Generates security-focused guidance for Google Cloud workloads based on the design principles and recommendations in the Google Cloud Well-A
723. `google:cloud:google-cloud-waf-sustainability` [marketing][infra] OFFICIAL — Generates sustainability-focused guidance for Google Cloud workloads based on the design principles and recommendations in the Google Cloud 
724. `redhat:cve-skillpack` [infra][product] OFFICIAL — Understand CVEs, check product lifecycle status, gather diagnostics, and file support cases at the right severity — essential Red Hat skills
725. `redhat:openshift-skillpack` [infra] OFFICIAL — Provision, inventory, and report on OpenShift clusters — spanning Assisted Installer, OCM, ROSA, ARO, and kubeconfig fleets — through a sing
726. `blader:humanizer` [ai] VOLT-SK — Remove signs of AI-generated writing from text, making it sound more natural and human
727. `zarazhangrui:frontend-slides` [animation][design][frontend] VOLT-SK — Generate animation-rich HTML presentations with visual style previews
728. `obra:brainstorming` [ai][meta] VOLT-SK — Generate and explore ideas
729. `Shpigford:screenshots` [marketing][test] VOLT-SK — Generate marketing screenshots with Playwright
730. `muthuishere:hand-drawn-diagrams` [ai] VOLT-SK — Generate hand-drawn Excalidraw diagrams from a prompt — animated SVG, hosted edit link, and PNG export. Works with Claude Code, Codex, Gemin
731. `nextlevelbuilder:ui-ux-pro-max-skill` [general] VOLT-SK — UI/UX design patterns and best practices
732. `scarletkc:vexor` [ai] VOLT-SK — Vector-powered CLI for semantic file search with a Claude/Codex skill
733. `ZhangHanDong:makepad-skills` [3d] VOLT-SK — Makepad UI development skills for Rust apps: setup, patterns, shaders, packaging, and troubleshooting.
734. `AvdLee:swiftui-expert-skill` [mobile] VOLT-SK — Modern SwiftUI best practices and iOS 26+ Liquid Glass adoption
735. `efremidze:swift-patterns-skill` [mobile] VOLT-SK — Modern Swift/SwiftUI best practices
736. `Joannis:claude-skills` [ai][backend] VOLT-SK — Swift Server development guidance with linting tool for best practices
737. `rudrankriyam:app-store-connect-cli-skills` [devops][mobile] VOLT-SK — Automate App Store deployments and management using ASC CLI
738. `testdino-hq:playwright-skill` [devops][test] VOLT-SK — 70+ production-tested Playwright automation testing patterns: E2E, POM, CI/CD, migrations, CLI
739. `hamelsmu:generate-synthetic-data` [ai][test] VOLT-SK — Create diverse synthetic test inputs for LLM evals
740. `NeoLabHQ:prompt-engineering` [ai] VOLT-SK — Widely used prompt engineering techniques and patterns, including Anthropic best practices and agent persuasion principles.
741. `sametbrr:llm-wiki-manager` [ai] VOLT-SK — Persistent LLM-managed personal wiki — the model writes, cross-references, and maintains the knowledge base while you curate sources. Implem
742. `Panniantong:Agent-Reach` [shell] VOLT-SK — Multi-platform search CLI for 17 sites including Chinese platforms
743. `sanjay3290:imagen` [backend] VOLT-SK — Generate images using Google Gemini's API
744. `more-io:apple-bridges` [shell] VOLT-SK — Native macOS app access — manage Apple Reminders, Calendar, Contacts, Notes, Mail, and tmux sessions via Swift CLI bridges
745. `zw008:VMware-AIops` [ai][data][ops] VOLT-SK — AI-powered VMware vCenter/ESXi monitoring and operations: inventory queries, health/alarms, VM lifecycle (create, delete, snapshot, clone, m
746. `video-db:skills` [backend] VOLT-SK — Realtime and batch video workflows: capture screen/audio, ingest URLs/YouTube/RTSP, transcribe, index, search, generate subtitles, edit time
747. `talkstream:ru-text` [design][ai] VOLT-SK — Russian text quality: ~1,040 rules for typography, info-style, editorial, UX writing, business correspondence. Cross-platform: Claude Code, 
748. `meodai:skill.color-expert` [a11y] VOLT-SK — Color science expert skill with 286K words of reference material covering OKLCH/OKLAB, palette generation, accessibility/contrast, color nam
749. `ai-generated-asset-art-direction` [ai] SREDNOFF
750. `codebase-map-indexer` [general] SREDNOFF
751. `crawl-indexability-sitemaps` [seo] SREDNOFF
752. `python-cli-package-builder` [shell] SREDNOFF
753. `search-indexing-rag` [seo][ml] SREDNOFF
754. `sitemap-index-sharding` [seo] SREDNOFF
755. `defi-protocol-templates` [trading] WSH

## G2 (mass expansion, 1226 records)

756. `anthropics:docx` [ai] OFFICIAL — Create, edit, and analyze Word documents
757. `anthropics:doc-coauthoring` [ai][security] OFFICIAL — Collaborative document editing and co-authoring
758. `anthropics:pptx` [ai] OFFICIAL — Create, edit, and analyze PowerPoint presentations
759. `anthropics:xlsx` [ai] OFFICIAL — Create, edit, and analyze Excel spreadsheets
760. `anthropics:pdf` [ai] OFFICIAL — Extract text, create PDFs, and handle forms
761. `anthropics:algorithmic-art` [ai] OFFICIAL — Create generative art using p5.js with seeded randomness
762. `anthropics:canvas-design` [design][ai] OFFICIAL — Design visual art in PNG and PDF formats
763. `anthropics:frontend-design` [ai][frontend] OFFICIAL — Frontend design and UI/UX development tools
764. `anthropics:slack-gif-creator` [ai] OFFICIAL — Create animated GIFs optimized for Slack size constraints
765. `anthropics:web-artifacts-builder` [design][ai][frontend] OFFICIAL — Build complex claude.ai HTML artifacts with React and Tailwind
766. `anthropics:mcp-builder` [ai] OFFICIAL — Create MCP servers to integrate external APIs and services
767. `anthropics:webapp-testing` [ai][test] OFFICIAL — Test local web applications using Playwright
768. `anthropics:brand-guidelines` [design][ai] OFFICIAL — Apply Anthropic's brand colors and typography to artifacts
769. `anthropics:skill-creator` [ai] OFFICIAL — Guide for creating skills that extend Claude's capabilities
770. `voltagent:voltagent-docs-bundle` [docs] OFFICIAL — Lookup embedded docs from @voltagent/core for version-matched documentation
771. `testmu-ai:api-skill` [ai][test][backend] OFFICIAL — Suite of API skills for designing, mocking, documenting, securing, and generating tests for REST/GraphQL/gRPC APIs
772. `testmu-ai:test-framework-migration-skill` [ai][test] OFFICIAL — Migrate tests between Selenium, Playwright, Puppeteer, and Cypress
773. `zero:zero` [ai][backend] OFFICIAL — Discover and call external paid tools for Claude Code agents instead of stopping to ask the user to sign up or fetch an API key
774. `composiohq:composio` [ai] OFFICIAL — Connect AI agents to 1000+ external apps with managed authentication
775. `google-gemini:vertex-ai-api-dev` [ai][infra][backend] OFFICIAL — Developing Gemini-powered apps on Google Cloud Vertex AI using the Gen AI SDK
776. `google-gemini:gemini-live-api-dev` [backend] OFFICIAL — Building real-time bidirectional streaming apps with the Gemini Live API
777. `google-gemini:gemini-interactions-api` [backend] OFFICIAL — Building apps with the Gemini Interactions API for text, chat, streaming, and image generation
778. `stripe:upgrade-stripe` [payments][backend] OFFICIAL — Upgrade Stripe SDK and API versions
779. `trycourier:courier-skills` [email] OFFICIAL — Multi-channel notifications via email, SMS, push, and chat
780. `callstackincubator:github` [quality] OFFICIAL — GitHub workflow patterns for PRs, code review, branching
781. `better-auth:explain-error` [security] OFFICIAL — Explain Better Auth error messages
782. `better-auth:providers` [security] OFFICIAL — Better Auth authentication providers
783. `better-auth:emailAndPassword` [security][email] OFFICIAL — Email and password authentication with Better Auth
784. `better-auth:organization` [security] OFFICIAL — Organization management with Better Auth
785. `better-auth:twoFactor` [security] OFFICIAL — Two-factor authentication with Better Auth
786. `tinybirdco:tinybird-python-sdk-guidelines` [data] OFFICIAL — Tinybird Python SDK usage guidelines
787. `tinybirdco:tinybird-typescript-sdk-guidelines` [data] OFFICIAL — Tinybird TypeScript SDK usage guidelines
788. `hashicorp:azure-verified-modules` [infra] OFFICIAL — Azure Verified Modules (AVM) certification standards for Terraform modules
789. `hashicorp:provider-resources` [infra] OFFICIAL — Implement Terraform Provider resources and data sources using the Plugin Framework
790. `hashicorp:provider-test-patterns` [infra][test] OFFICIAL — Acceptance test patterns for Terraform providers using terraform-plugin-testing
791. `hashicorp:provider-actions` [infra] OFFICIAL — Implement Terraform Provider Actions using the Plugin Framework
792. `hashicorp:run-acceptance-tests` [infra][test] OFFICIAL — Run acceptance tests for Terraform providers using Go's test runner
793. `hashicorp:refactor-module` [infra] OFFICIAL — Transform monolithic Terraform configurations into reusable modules
794. `hashicorp:terraform-search-import` [infra] OFFICIAL — Discover existing cloud resources and bulk import them into Terraform state
795. `hashicorp:terraform-stacks` [infra] OFFICIAL — Manage infrastructure across multiple environments, regions, and cloud accounts
796. `hashicorp:terraform-test` [infra][test] OFFICIAL — Built-in testing framework for Terraform configurations with .tftest.hcl files
797. `firecrawl:firecrawl-build` [seo] OFFICIAL — Integrate Firecrawl into application code for web search, scraping, extraction, and browser interaction
798. `firecrawl:firecrawl-build-interact` [seo][security] OFFICIAL — Multi-step Firecrawl browser flows: clicks, form fills, pagination, and auth-aware navigation
799. `firecrawl:firecrawl-build-onboarding` [seo] OFFICIAL — Set up Firecrawl credentials and SDK in a project for the first integration
800. `firecrawl:firecrawl-build-scrape` [seo] OFFICIAL — Integrate Firecrawl `/scrape` for single-page extraction from product code
801. `firecrawl:firecrawl-build-search` [seo] OFFICIAL — Integrate Firecrawl `/search` for query-first discovery with optional content hydration
802. `neondatabase:claimable-postgres` [data] OFFICIAL — Claimable Postgres database provisioning with Neon
803. `neondatabase:neon-postgres-egress-optimizer` [data] OFFICIAL — Optimize Neon Postgres egress and data transfer
804. `clickhouse:chdb-datastore` [data][perf] OFFICIAL — Drop-in pandas replacement with ClickHouse performance across 16+ data sources
805. `clickhouse:chdb-sql` [data][infra][backend] OFFICIAL — In-process ClickHouse SQL engine for Python — query files, databases, and cloud storage without a server
806. `clickhouse:clickhousectl-cloud-deploy` [data][infra][devops] OFFICIAL — Deploy to ClickHouse Cloud and migrate from local setups with clickhousectl
807. `clickhouse:clickhousectl-local-dev` [data] OFFICIAL — Spin up a local ClickHouse development environment from zero with clickhousectl
808. `remotion-dev:remotion` [animation][frontend] OFFICIAL — Programmatic video creation with React
809. `replicate:replicate` [ai][backend] OFFICIAL — Discover, compare, and run AI models using Replicate's API
810. `typefully:typefully` [marketing] OFFICIAL — Create, schedule, and publish social media content across X, LinkedIn, Threads, Bluesky, and Mastodon
811. `veniceai:venice-api-overview` [security][finance][backend] OFFICIAL — API basics, auth modes, pricing, and versioning
812. `veniceai:venice-auth` [trading][security][backend] OFFICIAL — API keys and wallet-based Venice authentication
813. `veniceai:venice-chat` [ai] OFFICIAL — Chat completions, multimodal inputs, tools, and streaming
814. `veniceai:venice-responses` [ai][backend] OFFICIAL — OpenAI-compatible Responses API for Venice
815. `veniceai:venice-embeddings` [ai] OFFICIAL — Embeddings models, dimensions, and encoding formats
816. `veniceai:venice-image-edit` [ai] OFFICIAL — Image edits, upscaling, and background removal
817. `veniceai:venice-audio-speech` [ai] OFFICIAL — Text-to-speech models, voices, formats, and streaming
818. `veniceai:venice-audio-music` [ai][api][backend] OFFICIAL — Music generation queueing, retrieval, and completion endpoints
819. `veniceai:venice-audio-transcription` [ai] OFFICIAL — Audio transcription models and speech-to-text options
820. `veniceai:venice-video` [ai] OFFICIAL — Video generation and transcription workflows
821. `veniceai:venice-models` [ai] OFFICIAL — Model catalog, traits, and compatibility mappings
822. `veniceai:venice-characters` [ai][api] OFFICIAL — Character endpoints and `character_slug` usage
823. `veniceai:venice-api-keys` [trading][backend] OFFICIAL — API key CRUD, rate limits, and Web3 keys
824. `veniceai:venice-billing` [data][finance][payments] OFFICIAL — Balance, usage, and billing analytics endpoints
825. `veniceai:venice-x402` [trading][payments] OFFICIAL — Wallet credits and x402 payments on Base
826. `veniceai:venice-crypto-rpc` [trading] OFFICIAL — JSON-RPC proxying for supported crypto networks
827. `veniceai:venice-augment` [ai][api] OFFICIAL — Search, scraping, and text parsing endpoints
828. `vercel-labs:next-cache-components` [perf][frontend] OFFICIAL — Caching strategies and cache-aware components in Next.js
829. `vercel-labs:next-upgrade` [frontend] OFFICIAL — Upgrade Next.js projects to newer versions
830. `cloudflare:agents-sdk` [ai] OFFICIAL — Build stateful AI agents with scheduling, RPC, and MCP servers
831. `cloudflare:cloudflare-email-service` [email] OFFICIAL — Send transactional email and route inbound mail with Cloudflare Email Sending and Email Routing
832. `cloudflare:durable-objects` [backend] OFFICIAL — Stateful coordination with RPC, SQLite, and WebSockets
833. `cloudflare:sandbox-sdk` [infra][devops] OFFICIAL — Build sandboxed applications for secure, isolated code execution on Workers
834. `cloudflare:web-perf` [perf] OFFICIAL — Audit Core Web Vitals and render-blocking resources
835. `cloudflare:wrangler` [devops] OFFICIAL — Deploy and manage Workers, KV, R2, D1, Vectorize, Queues, Workflows
836. `netlify:netlify-functions` [backend] OFFICIAL — Build serverless API endpoints and background tasks
837. `netlify:netlify-edge-functions` [infra][devops] OFFICIAL — Low-latency edge middleware and geolocation logic
838. `netlify:netlify-blobs` [infra][devops] OFFICIAL — Key-value object storage for files and data
839. `netlify:netlify-db` [data][devops] OFFICIAL — Managed Postgres with deploy preview branching
840. `netlify:netlify-image-cdn` [infra][devops] OFFICIAL — Optimize and transform images via CDN
841. `netlify:netlify-forms` [infra][devops] OFFICIAL — HTML form handling with spam filtering
842. `netlify:netlify-frameworks` [devops] OFFICIAL — Deploy web frameworks with SSR support
843. `netlify:netlify-caching` [perf] OFFICIAL — Configure CDN caching and cache purging
844. `netlify:netlify-deploy` [devops] OFFICIAL — Automated deployment workflow for Netlify sites
845. `netlify:netlify-ai-gateway` [ai] OFFICIAL — Access AI models via unified gateway endpoint
846. `google-labs-code:design-md` [ai] OFFICIAL — Create and manage DESIGN.md files
847. `google-labs-code:enhance-prompt` [ai] OFFICIAL — Improve prompts with design specs and UI/UX vocabulary
848. `google-labs-code:react-components` [marketing][frontend] OFFICIAL — Stitch to React components conversion
849. `google-labs-code:shadcn-ui` [design][frontend] OFFICIAL — Build UI components with shadcn/ui
850. `google-labs-code:stitch-loop` [ai] OFFICIAL — Iterative design-to-code feedback loop
851. `googleworkspace:gws-shared` [docs][ops] OFFICIAL — Shared authentication, global flags, and output formatting
852. `googleworkspace:gws-drive` [docs][ops] OFFICIAL — Manage Google Drive files, folders, and shared drives
853. `googleworkspace:gws-sheets` [docs][ops] OFFICIAL — Read and write Google Sheets spreadsheets
854. `googleworkspace:gws-gmail` [email] OFFICIAL — Send, read, and manage Gmail email
855. `googleworkspace:gws-calendar` [docs][ops] OFFICIAL — Manage Google Calendar calendars and events
856. `googleworkspace:gws-admin-reports` [docs][ops] OFFICIAL — Audit logs and usage reports for Workspace
857. `googleworkspace:gws-docs` [docs][ops] OFFICIAL — Read and write Google Docs documents
858. `googleworkspace:gws-slides` [docs][ops] OFFICIAL — Read and write Google Slides presentations
859. `googleworkspace:gws-tasks` [docs][ops] OFFICIAL — Manage Google Tasks task lists and tasks
860. `googleworkspace:gws-people` [docs][ops] OFFICIAL — Manage Google People contacts and profiles
861. `googleworkspace:gws-chat` [docs][ops] OFFICIAL — Manage Google Chat spaces and messages
862. `googleworkspace:gws-classroom` [docs][ops] OFFICIAL — Manage Google Classroom classes, rosters, and coursework
863. `googleworkspace:gws-forms` [docs][ops] OFFICIAL — Read and write Google Forms
864. `googleworkspace:gws-keep` [docs][ops] OFFICIAL — Manage Google Keep notes
865. `googleworkspace:gws-events` [docs][ops] OFFICIAL — Subscribe to Google Workspace events
866. `googleworkspace:gws-workflow` [docs][ops] OFFICIAL — Cross-service Google Workspace productivity workflows
867. `expo:building-native-ui` [animation][mobile][frontend] OFFICIAL — Build apps with Expo Router, styling, components, navigation, and animations
868. `expo:expo-api-routes` [mobile][backend] OFFICIAL — Create API routes in Expo Router with EAS Hosting
869. `expo:expo-cicd-workflows` [devops][mobile] OFFICIAL — CI/CD workflows for Expo projects
870. `expo:expo-deployment` [devops][mobile] OFFICIAL — Deploy Expo apps to production
871. `expo:expo-dev-client` [mobile] OFFICIAL — Build and distribute Expo dev clients locally or via TestFlight
872. `expo:expo-ui-jetpack-compose` [mobile][frontend] OFFICIAL — Jetpack Compose UI components for Expo
873. `expo:expo-ui-swift-ui` [mobile][frontend] OFFICIAL — SwiftUI components for Expo
874. `expo:native-data-fetching` [mobile][backend] OFFICIAL — Network requests, API calls, caching, and offline support
875. `expo:upgrading-expo` [mobile] OFFICIAL — Upgrade Expo SDK versions
876. `expo:use-dom` [mobile][frontend] OFFICIAL — Run web code in a webview on native using DOM components
877. `huggingface:hugging-face-dataset-viewer` [backend] OFFICIAL — Browse and query HF datasets with the Dataset Viewer API
878. `huggingface:hugging-face-datasets` [data] OFFICIAL — Create and manage datasets with configs and SQL querying
879. `huggingface:hugging-face-evaluation` [ml] OFFICIAL — Model evaluation with vLLM/lighteval and eval tables
880. `huggingface:hugging-face-jobs` [infra] OFFICIAL — Run compute jobs and Python scripts on HF infrastructure
881. `huggingface:hugging-face-model-trainer` [marketing] OFFICIAL — Train models with TRL: SFT, DPO, GRPO, GGUF conversion
882. `huggingface:hugging-face-paper-pages` [ml][ai] OFFICIAL — Create and manage paper pages on HF Hub
883. `huggingface:hugging-face-paper-publisher` [ml][ai] OFFICIAL — Publish papers on HF Hub with model/dataset links
884. `huggingface:hugging-face-tool-builder` [backend] OFFICIAL — Build reusable scripts for HF API operations
885. `huggingface:hugging-face-trackio` [ml] OFFICIAL — Track ML experiments with real-time dashboards
886. `huggingface:hugging-face-vision-trainer` [infra] OFFICIAL — Train vision models on HF infrastructure
887. `huggingface:huggingface-gradio` [devops] OFFICIAL — Build Gradio apps and deploy to HF Spaces
888. `huggingface:transformers.js` [ml] OFFICIAL — Run ML models in the browser with Transformers.js
889. `trailofbits:ask-questions-if-underspecified` [ai] OFFICIAL — Prompt for clarification on ambiguous requirements
890. `trailofbits:building-secure-contracts` [trading][security][legal] OFFICIAL — Smart contract security toolkit with vulnerability scanners for 6 blockchains
891. `trailofbits:burpsuite-project-parser` [security] OFFICIAL — Search and extract data from Burp Suite project files
892. `trailofbits:claude-in-chrome-troubleshooting` [ai] OFFICIAL — Diagnose and fix Claude in Chrome MCP extension connectivity issues
893. `trailofbits:constant-time-analysis` [security] OFFICIAL — Detect compiler-induced timing side-channels in crypto code
894. `trailofbits:differential-review` [security] OFFICIAL — Security-focused diff review with git history analysis
895. `trailofbits:entry-point-analyzer` [trading] OFFICIAL — Identify state-changing entry points in smart contracts
896. `trailofbits:firebase-apk-scanner` [security][mobile] OFFICIAL — Scan Android APKs for Firebase misconfigurations and security vulnerabilities
897. `trailofbits:insecure-defaults` [security] OFFICIAL — Detect insecure default configurations like hardcoded secrets, default credentials, and weak crypto
898. `trailofbits:property-based-testing` [trading][test] OFFICIAL — Property-based testing for multiple languages and smart contracts
899. `trailofbits:semgrep-rule-creator` [security] OFFICIAL — Create and refine Semgrep rules for vulnerability detection
900. `trailofbits:semgrep-rule-variant-creator` [test] OFFICIAL — Port existing Semgrep rules to new target languages with test-driven validation
901. `trailofbits:sharp-edges` [security] OFFICIAL — Identify error-prone APIs and dangerous configurations
902. `trailofbits:spec-to-code-compliance` [trading][legal] OFFICIAL — Specification-to-code compliance checker for blockchain audits
903. `trailofbits:static-analysis` [security] OFFICIAL — Static analysis toolkit with CodeQL, Semgrep, and SARIF
904. `trailofbits:testing-handbook-skills` [test] OFFICIAL — Testing Handbook skills: fuzzers, static analysis, sanitizers
905. `trailofbits:variant-analysis` [security] OFFICIAL — Find similar vulnerabilities via pattern-based analysis
906. `getsentry:sentry-workflow` [ops] OFFICIAL — End-to-end Sentry workflow: fix production issues and review code with Sentry context
907. `getsentry:sentry-fix-issues` [ops] OFFICIAL — Find and fix Sentry issues with stack trace, breadcrumb, and trace context via MCP
908. `getsentry:sentry-code-review` [ops] OFFICIAL — Review code changes using Sentry issue and trace context
909. `getsentry:sentry-pr-code-review` [ops] OFFICIAL — Review PR comments from Seer Bug Prediction and Sentry feedback
910. `getsentry:sentry-create-alert` [ops][email] OFFICIAL — Create Sentry alerts with email, Slack, PagerDuty, Discord, and more
911. `getsentry:sentry-sdk-upgrade` [ops] OFFICIAL — Upgrade the Sentry JavaScript SDK across major versions
912. `getsentry:sentry-sdk-skill-creator` [ops] OFFICIAL — Create a new Sentry SDK skill bundle for a platform
913. `microsoft:cloud-solution-architect` [infra] OFFICIAL — Design well-architected Azure cloud systems
914. `microsoft:continual-learning` [ai] OFFICIAL — Continual learning patterns for Azure AI
915. `microsoft:copilot-sdk` [infra][devops] OFFICIAL — Build applications powered by GitHub Copilot SDK
916. `microsoft:entra-agent-id` [security][backend] OFFICIAL — Microsoft Entra Agent ID OAuth2 identities via Graph API
917. `microsoft:frontend-design-review` [frontend] OFFICIAL — Review and create distinctive frontend interfaces
918. `microsoft:github-issue-creator` [infra][devops] OFFICIAL — Structured GitHub issue reports from notes
919. `microsoft:mcp-builder` [ai][backend] OFFICIAL — MCP server creation guide for LLM tool integration
920. `microsoft:podcast-generation` [ai][backend] OFFICIAL — AI podcast audio with Azure OpenAI Realtime API
921. `microsoft:skill-creator` [ai] OFFICIAL — Guide for creating effective skills for AI coding agents
922. `microsoft:azure-ai-document-intelligence-dotnet` [ai] OFFICIAL — Document text, table, and data extraction
923. `microsoft:azure-ai-openai-dotnet` [ai] OFFICIAL — GPT-4, embeddings, DALL-E, and Whisper client
924. `microsoft:azure-ai-projects-dotnet` [ai] OFFICIAL — AI Foundry project management SDK
925. `microsoft:azure-ai-voicelive-dotnet` [ai] OFFICIAL — Real-time bidirectional voice AI
926. `microsoft:azure-eventgrid-dotnet` [infra][devops] OFFICIAL — Event Grid topic and domain publishing
927. `microsoft:azure-eventhub-dotnet` [infra][devops] OFFICIAL — High-throughput event streaming
928. `microsoft:azure-identity-dotnet` [infra][devops] OFFICIAL — Microsoft Entra ID authentication
929. `microsoft:azure-maps-search-dotnet` [infra][devops] OFFICIAL — Geocoding, routing, and weather services
930. `microsoft:azure-mgmt-apimanagement-dotnet` [backend] OFFICIAL — API Management provisioning via ARM
931. `microsoft:azure-mgmt-applicationinsights-dotnet` [infra][devops] OFFICIAL — Application Insights resource management
932. `microsoft:azure-mgmt-arizeaiobservabilityeval-dotnet` [ai][ops] OFFICIAL — Arize AI observability management
933. `microsoft:azure-mgmt-botservice-dotnet` [infra][devops] OFFICIAL — Bot Service provisioning via ARM
934. `microsoft:azure-mgmt-fabric-dotnet` [infra][devops] OFFICIAL — Microsoft Fabric capacity management
935. `microsoft:azure-mgmt-mongodbatlas-dotnet` [data] OFFICIAL — MongoDB Atlas as ARM resources
936. `microsoft:azure-mgmt-weightsandbiases-dotnet` [devops] OFFICIAL — Weights & Biases deployment management
937. `microsoft:azure-resource-manager-cosmosdb-dotnet` [infra][devops] OFFICIAL — Cosmos DB resource provisioning
938. `microsoft:azure-resource-manager-durabletask-dotnet` [infra][devops] OFFICIAL — Durable Task Scheduler management
939. `microsoft:azure-resource-manager-mysql-dotnet` [backend] OFFICIAL — MySQL Flexible Server management
940. `microsoft:azure-resource-manager-playwright-dotnet` [test] OFFICIAL — Playwright Testing workspace management
941. `microsoft:azure-resource-manager-postgresql-dotnet` [data][backend] OFFICIAL — PostgreSQL Flexible Server management
942. `microsoft:azure-resource-manager-redis-dotnet` [data][perf] OFFICIAL — Azure Cache for Redis provisioning
943. `microsoft:azure-resource-manager-sql-dotnet` [data] OFFICIAL — Azure SQL resource management
944. `microsoft:azure-search-documents-dotnet` [infra][devops] OFFICIAL — Full-text, vector, and hybrid search
945. `microsoft:azure-security-keyvault-keys-dotnet` [security] OFFICIAL — Cryptographic key management
946. `microsoft:azure-servicebus-dotnet` [infra][devops][backend] OFFICIAL — Enterprise messaging with queues and topics
947. `microsoft:m365-agents-dotnet` [infra][devops] OFFICIAL — M365, Teams, and Copilot Studio agents
948. `microsoft:microsoft-azure-webjobs-extensions-authentication-events-dotnet` [security] OFFICIAL — Entra ID custom auth events handler
949. `microsoft:azure-ai-anomalydetector-java` [ai] OFFICIAL — Anomaly detection applications
950. `microsoft:azure-ai-contentsafety-java` [ai] OFFICIAL — Content moderation and safety
951. `microsoft:azure-ai-formrecognizer-java` [ai] OFFICIAL — Document analysis and form extraction
952. `microsoft:azure-ai-projects-java` [ai] OFFICIAL — AI Foundry project management
953. `microsoft:azure-ai-vision-imageanalysis-java` [ai] OFFICIAL — Image captioning, OCR, and object detection
954. `microsoft:azure-ai-voicelive-java` [ai] OFFICIAL — Real-time bidirectional voice AI
955. `microsoft:azure-appconfiguration-java` [infra][devops] OFFICIAL — Centralized app configuration management
956. `microsoft:azure-communication-callautomation-java` [ai] OFFICIAL — Call automation with IVR and AI
957. `microsoft:azure-communication-callingserver-java` [backend] OFFICIAL — CallingServer legacy SDK
958. `microsoft:azure-communication-chat-java` [marketing] OFFICIAL — Real-time chat with threads and receipts
959. `microsoft:azure-communication-common-java` [infra][devops] OFFICIAL — Communication Services common utilities
960. `microsoft:azure-communication-sms-java` [infra][devops] OFFICIAL — SMS sending and delivery reports
961. `microsoft:azure-compute-batch-java` [infra][devops] OFFICIAL — Large-scale parallel and HPC batch jobs
962. `microsoft:azure-cosmos-java` [infra][devops] OFFICIAL — Cosmos DB NoSQL with global distribution
963. `microsoft:azure-data-tables-java` [infra][devops] OFFICIAL — NoSQL key-value table storage
964. `microsoft:azure-eventgrid-java` [infra][devops] OFFICIAL — Event-driven pub/sub messaging
965. `microsoft:azure-eventhub-java` [infra][devops] OFFICIAL — Real-time high-throughput streaming
966. `microsoft:azure-identity-java` [infra][devops] OFFICIAL — Microsoft Entra ID authentication
967. `microsoft:azure-messaging-webpubsub-java` [backend] OFFICIAL — Real-time WebSocket messaging
968. `microsoft:azure-monitor-ingestion-java` [infra][devops] OFFICIAL — Custom log ingestion to Azure Monitor
969. `microsoft:azure-monitor-opentelemetry-exporter-java` [infra][devops] OFFICIAL — OpenTelemetry export to Azure Monitor
970. `microsoft:azure-monitor-query-java` [infra][devops] OFFICIAL — Query Azure Monitor logs and metrics
971. `microsoft:azure-security-keyvault-keys-java` [security] OFFICIAL — Cryptographic key management
972. `microsoft:azure-security-keyvault-secrets-java` [security] OFFICIAL — Secret management for passwords and keys
973. `microsoft:azure-storage-blob-java` [infra][devops] OFFICIAL — Blob storage for file management
974. `microsoft:agent-framework-azure-ai-py` [ai] OFFICIAL — Agent Framework for Azure AI Foundry
975. `microsoft:agents-v2-py` [ai] OFFICIAL — Foundry Agents SDK — container-based agents with custom images
976. `microsoft:azure-ai-contentsafety-py` [ai] OFFICIAL — Harmful content detection
977. `microsoft:azure-ai-contentunderstanding-py` [ai] OFFICIAL — Multimodal content extraction
978. `microsoft:azure-ai-ml-py` [ml][ai] OFFICIAL — Azure ML workspace and job management
979. `microsoft:azure-ai-projects-py` [ai] OFFICIAL — AI Foundry project client and agents
980. `microsoft:azure-ai-textanalytics-py` [ai][data] OFFICIAL — NLP: sentiment, entities, key phrases
981. `microsoft:azure-ai-transcription-py` [ai] OFFICIAL — Speech-to-text transcription
982. `microsoft:azure-ai-translation-document-py` [ai] OFFICIAL — Batch document translation
983. `microsoft:azure-ai-translation-text-py` [ai] OFFICIAL — Real-time text translation
984. `microsoft:azure-ai-vision-imageanalysis-py` [ai] OFFICIAL — Image captions, tags, OCR, objects
985. `microsoft:azure-ai-voicelive-py` [ai] OFFICIAL — Real-time bidirectional voice AI
986. `microsoft:azure-appconfiguration-py` [infra][devops] OFFICIAL — Feature flags and dynamic settings
987. `microsoft:azure-containerregistry-py` [infra][devops] OFFICIAL — Container image and registry management
988. `microsoft:azure-cosmos-db-py` [infra][devops] OFFICIAL — Cosmos DB with Python/FastAPI patterns
989. `microsoft:azure-cosmos-py` [infra][devops] OFFICIAL — Cosmos DB NoSQL client library
990. `microsoft:azure-data-tables-py` [infra][devops] OFFICIAL — NoSQL key-value table storage
991. `microsoft:azure-eventgrid-py` [infra][devops] OFFICIAL — Event-driven pub/sub routing
992. `microsoft:azure-eventhub-py` [infra][devops] OFFICIAL — High-throughput event streaming
993. `microsoft:azure-identity-py` [infra][devops] OFFICIAL — Microsoft Entra ID authentication
994. `microsoft:azure-keyvault-py` [security] OFFICIAL — Secrets, keys, and certificate management
995. `microsoft:azure-messaging-webpubsubservice-py` [backend] OFFICIAL — Real-time WebSocket messaging
996. `microsoft:azure-mgmt-apimanagement-py` [backend] OFFICIAL — API Management service administration
997. `microsoft:azure-mgmt-botservice-py` [infra][devops] OFFICIAL — Bot Service resource management
998. `microsoft:azure-mgmt-fabric-py` [infra][devops] OFFICIAL — Microsoft Fabric capacity management
999. `microsoft:azure-monitor-ingestion-py` [infra][devops] OFFICIAL — Custom log ingestion to Azure Monitor
1000. `microsoft:azure-monitor-opentelemetry-exporter-py` [infra][devops] OFFICIAL — OpenTelemetry export to Application Insights
1001. `microsoft:azure-monitor-query-py` [infra][devops] OFFICIAL — Query Azure Monitor logs and metrics
1002. `microsoft:azure-search-documents-py` [infra][devops] OFFICIAL — Full-text, vector, and hybrid search
1003. `microsoft:azure-servicebus-py` [infra][devops][backend] OFFICIAL — Enterprise messaging with queues and topics
1004. `microsoft:azure-speech-to-text-rest-py` [infra][devops][api] OFFICIAL — REST speech-to-text for short audio
1005. `microsoft:azure-storage-blob-py` [infra][devops] OFFICIAL — Blob object storage client
1006. `microsoft:azure-storage-file-datalake-py` [infra][devops] OFFICIAL — Hierarchical data lake storage
1007. `microsoft:azure-storage-file-share-py` [infra][devops] OFFICIAL — SMB file share management
1008. `microsoft:azure-storage-queue-py` [infra][devops][backend] OFFICIAL — Simple message queuing
1009. `microsoft:fastapi-router-py` [security] OFFICIAL — FastAPI routers with CRUD and auth
1010. `microsoft:m365-agents-py` [infra][devops] OFFICIAL — M365, Teams, and Copilot Studio agents
1011. `microsoft:pydantic-models-py` [seo][backend] OFFICIAL — Pydantic models for API schemas
1012. `microsoft:azure-cosmos-rust` [infra][devops] OFFICIAL — Cosmos DB NoSQL client
1013. `microsoft:azure-eventhub-rust` [infra][devops] OFFICIAL — Event Hubs streaming client
1014. `microsoft:azure-identity-rust` [infra][devops] OFFICIAL — Microsoft Entra ID authentication
1015. `microsoft:azure-keyvault-certificates-rust` [infra][devops] OFFICIAL — Key Vault certificate management
1016. `microsoft:azure-keyvault-keys-rust` [infra][devops] OFFICIAL — Key Vault cryptographic key management
1017. `microsoft:azure-keyvault-secrets-rust` [security] OFFICIAL — Key Vault secret storage
1018. `microsoft:azure-storage-blob-rust` [infra][devops] OFFICIAL — Blob object storage client
1019. `microsoft:azure-ai-contentsafety-ts` [ai] OFFICIAL — Content safety for text and images
1020. `microsoft:azure-ai-document-intelligence-ts` [ai] OFFICIAL — Document text and table extraction
1021. `microsoft:azure-ai-projects-ts` [ai] OFFICIAL — AI Foundry project client and agents
1022. `microsoft:azure-ai-translation-ts` [ai] OFFICIAL — Text and document translation
1023. `microsoft:azure-ai-voicelive-ts` [ai] OFFICIAL — Real-time bidirectional voice AI
1024. `microsoft:azure-cosmos-ts` [infra][devops] OFFICIAL — Cosmos DB NoSQL CRUD and queries
1025. `microsoft:azure-eventhub-ts` [infra][devops] OFFICIAL — High-throughput event streaming
1026. `microsoft:azure-identity-ts` [infra][devops] OFFICIAL — Microsoft Entra ID authentication
1027. `microsoft:azure-keyvault-keys-ts` [infra][devops] OFFICIAL — Cryptographic key management
1028. `microsoft:azure-keyvault-secrets-ts` [security] OFFICIAL — Secret storage and retrieval
1029. `microsoft:azure-microsoft-playwright-testing-ts` [test] OFFICIAL — Playwright tests at scale on Azure
1030. `microsoft:azure-monitor-opentelemetry-ts` [infra][devops] OFFICIAL — Application Insights tracing and metrics
1031. `microsoft:azure-postgres-ts` [data][backend] OFFICIAL — PostgreSQL Flexible Server connection
1032. `microsoft:azure-search-documents-ts` [infra][devops] OFFICIAL — Vector/hybrid search with semantic ranking
1033. `microsoft:azure-servicebus-ts` [infra][devops][backend] OFFICIAL — Messaging with queues and topics
1034. `microsoft:azure-storage-blob-ts` [infra][devops] OFFICIAL — Blob upload, download, and management
1035. `microsoft:azure-storage-file-share-ts` [infra][devops][ops] OFFICIAL — SMB file share operations
1036. `microsoft:azure-storage-queue-ts` [infra][devops][ops][backend] OFFICIAL — Queue message operations
1037. `microsoft:azure-web-pubsub-ts` [backend] OFFICIAL — Real-time WebSocket pub/sub messaging
1038. `microsoft:frontend-ui-dark-ts` [animation][design][frontend] OFFICIAL — Dark-themed React with Tailwind and animations
1039. `microsoft:m365-agents-ts` [infra][devops] OFFICIAL — M365, Teams, and Copilot Studio agents
1040. `microsoft:react-flow-node-ts` [frontend] OFFICIAL — React Flow node components with Zustand
1041. `microsoft:zustand-store-ts` [infra][devops] OFFICIAL — Zustand stores with middleware patterns
1042. `fal-ai-community:fal-audio` [ai] OFFICIAL — Text-to-speech and speech-to-text using fal.ai audio models
1043. `fal-ai-community:fal-image-edit` [ai] OFFICIAL — AI-powered image editing with style transfer and object removal
1044. `fal-ai-community:fal-lip-sync` [ai] OFFICIAL — Create talking head videos and lip sync audio to video
1045. `fal-ai-community:fal-platform` [ai][finance] OFFICIAL — Platform APIs for model management, pricing, and usage tracking
1046. `fal-ai-community:fal-realtime` [ai][backend] OFFICIAL — Real-time and streaming AI image generation
1047. `fal-ai-community:fal-restore` [ai] OFFICIAL — Restore and fix image quality — deblur, denoise, fix faces, restore documents
1048. `fal-ai-community:fal-train` [ai] OFFICIAL — Train custom AI models (LoRA) on fal.ai for personalized image generation
1049. `fal-ai-community:fal-tryon` [ai] OFFICIAL — Virtual try-on — see how clothes look on a person
1050. `fal-ai-community:fal-upscale` [ai] OFFICIAL — Upscale and enhance image and video resolution using AI
1051. `fal-ai-community:fal-video-edit` [ai] OFFICIAL — Edit existing videos using AI — remix style, upscale, remove background, add audio
1052. `fal-ai-community:fal-vision` [design][ai] OFFICIAL — Analyze images — segment objects, detect, OCR, describe, visual Q&A
1053. `WordPress:wordpress-router` [design][docs] OFFICIAL — Classifies WordPress repos and routes to the right workflow
1054. `WordPress:wp-project-triage` [design][docs][devops] OFFICIAL — Detects project type, tooling, and versions automatically
1055. `WordPress:wp-block-development` [design][docs] OFFICIAL — Gutenberg blocks: block.json, attributes, rendering, deprecations
1056. `WordPress:wp-plugin-development` [security][backend] OFFICIAL — Plugin architecture, hooks, settings API, security
1057. `WordPress:wp-rest-api` [seo][security][backend] OFFICIAL — REST API routes/endpoints, schema, auth, and response shaping
1058. `WordPress:wp-interactivity-api` [frontend][backend] OFFICIAL — Frontend interactivity with data-wp-* directives and stores
1059. `WordPress:wp-abilities-api` [backend] OFFICIAL — Capability-based permissions and REST API authentication
1060. `WordPress:wp-performance` [data][perf][backend] OFFICIAL — Profiling, caching, database optimization, Server-Timing
1061. `WordPress:wp-phpstan` [design][docs] OFFICIAL — PHPStan static analysis for WordPress projects
1062. `WordPress:wp-playground` [design][docs] OFFICIAL — WordPress Playground for instant local environments
1063. `WordPress:wpds` [design] OFFICIAL — WordPress Design System
1064. `openai:cloudflare-deploy` [ai][devops] OFFICIAL — Deploy apps to Cloudflare using Workers, Pages, and platform services
1065. `openai:develop-web-game` [ai][test] OFFICIAL — Build and test web games iteratively using Playwright with time-stepping
1066. `openai:doc` [ai] OFFICIAL — Read, create, and edit .docx documents with formatting and layout fidelity
1067. `openai:gh-fix-ci` [ai][devops] OFFICIAL — Debug and fix failing GitHub Actions PR checks using log inspection
1068. `openai:jupyter-notebook` [ai] OFFICIAL — Create clean, reproducible Jupyter notebooks for experiments and tutorials
1069. `openai:linear` [ai] OFFICIAL — Manage issues, projects, and team workflows in Linear
1070. `openai:notion-knowledge-capture` [ai] OFFICIAL — Convert conversations into structured, searchable Notion wiki entries
1071. `openai:notion-meeting-intelligence` [ai] OFFICIAL — Prep meetings by pulling Notion context and tailoring agendas
1072. `openai:notion-research-documentation` [ai][docs] OFFICIAL — Research Notion content and synthesize findings into structured briefs
1073. `openai:notion-spec-to-implementation` [ai] OFFICIAL — Convert Notion specs into linked implementation plans and tasks
1074. `openai:openai-docs` [ai][docs] OFFICIAL — Provide authoritative guidance from OpenAI developer documentation
1075. `openai:pdf` [design][ai] OFFICIAL — Read, create, and review PDFs with layout and visual formatting integrity
1076. `openai:playwright` [ai][test] OFFICIAL — Automate real browser interactions for navigation, forms, and scraping
1077. `openai:render-deploy` [ai][infra][devops] OFFICIAL — Deploy applications to Render's cloud platform using Git-backed services
1078. `openai:screenshot` [ai] OFFICIAL — Capture desktop, app windows, or pixel regions across OS platforms
1079. `openai:security-ownership-map` [ai][security] OFFICIAL — Map people-to-file ownership, compute bus factor, and identify risks
1080. `openai:sentry` [ai][ops] OFFICIAL — Inspect Sentry issues, summarize production errors, and pull health data
1081. `openai:spreadsheet` [design][ai] OFFICIAL — Create, edit, analyze, and visualize spreadsheets with formulas
1082. `openai:transcribe` [ai] OFFICIAL — Transcribe audio files to text with optional speaker diarization
1083. `openai:vercel-deploy` [ai][devops] OFFICIAL — Deploy applications and websites to Vercel with preview or production options
1084. `openai:aspnet-core` [ai] OFFICIAL — Build, review, and architect ASP.NET Core apps (Blazor, MVC, Minimal APIs, etc.)
1085. `openai:figma` [design][ai][backend] OFFICIAL — Use the Figma MCP server to fetch design context and translate nodes into production code
1086. `openai:figma-code-connect-components` [design][ai][frontend] OFFICIAL — Connect Figma design components to code components using Code Connect
1087. `openai:figma-create-design-system-rules` [design][ai][backend] OFFICIAL — Rules for implementing Figma designs using the Figma MCP server
1088. `openai:figma-create-new-file` [design][ai] OFFICIAL — Create a new blank Figma file or FigJam file
1089. `openai:figma-implement-design` [design][ai] OFFICIAL — Translate Figma designs into production-ready code with 1:1 visual fidelity
1090. `openai:figma-use` [design][ai] OFFICIAL — Prerequisite skill for every use_figma tool call — write/read actions in Figma context
1091. `openai:frontend-skill` [design][ai][frontend] OFFICIAL — Create visually strong landing pages, websites, and app UIs with restrained composition
1092. `openai:playwright-interactive` [ai][test] OFFICIAL — Persistent browser and Electron interaction via js_repl for iterative UI debugging
1093. `openai:slides` [ai] OFFICIAL — Create and edit .pptx presentation decks with PptxGenJS
1094. `openai:winui-app` [ai] OFFICIAL — Bootstrap and develop modern WinUI 3 desktop apps with C# and Windows App SDK
1095. `figma:figma-code-connect-components` [design][frontend] OFFICIAL — Connect Figma design components to code components using Code Connect
1096. `figma:figma-create-new-file` [design] OFFICIAL — Create a new blank Figma Design or FigJam file
1097. `figma:figma-implement-design` [design] OFFICIAL — Translate Figma designs into production-ready application code with 1:1 fidelity
1098. `coreyhaines31:analytics-tracking` [data][devops] OFFICIAL — Set up and audit analytics tracking and measurement pipelines
1099. `coreyhaines31:churn-prevention` [payments] OFFICIAL — Build cancellation flows, save offers, and recover failed payments
1100. `coreyhaines31:cold-email` [email] OFFICIAL — Write B2B cold emails and follow-up sequences that convert
1101. `coreyhaines31:competitor-alternatives` [seo] OFFICIAL — Build competitor comparison and alternative landing pages for SEO
1102. `coreyhaines31:content-strategy` [marketing][product] OFFICIAL — Plan content strategy and decide what topics and formats to prioritize
1103. `coreyhaines31:copy-editing` [marketing] OFFICIAL — Edit and improve existing marketing copy for clarity and impact
1104. `coreyhaines31:copywriting` [marketing] OFFICIAL — Write and rewrite marketing copy for landing pages, homepages, and ads
1105. `coreyhaines31:email-sequence` [marketing][email] OFFICIAL — Build email sequences, drip campaigns, and lifecycle email flows
1106. `coreyhaines31:form-cro` [marketing][sales] OFFICIAL — Optimize lead capture and contact forms to improve conversion
1107. `coreyhaines31:free-tool-strategy` [seo][sales] OFFICIAL — Plan and build free tools for lead generation and SEO value
1108. `coreyhaines31:launch-strategy` [marketing][product] OFFICIAL — Plan product launches, feature announcements, and go-to-market strategies
1109. `coreyhaines31:marketing-psychology` [marketing] OFFICIAL — Apply psychological principles and behavioral science to copy and design
1110. `coreyhaines31:onboarding-cro` [marketing] OFFICIAL — Optimize post-signup onboarding and user activation to improve time-to-value
1111. `coreyhaines31:page-cro` [marketing] OFFICIAL — Improve conversion rates on any marketing page including homepages and landing pages
1112. `coreyhaines31:paid-ads` [marketing] OFFICIAL — Create and optimize paid campaigns on Google, Meta, LinkedIn, and more
1113. `coreyhaines31:paywall-upgrade-cro` [marketing] OFFICIAL — Design and optimize upgrade screens, paywalls, and upsell modals
1114. `coreyhaines31:popup-cro` [marketing] OFFICIAL — Create and optimize popups, modals, and slide-ins for conversions
1115. `coreyhaines31:pricing-strategy` [finance] OFFICIAL — Define pricing, packaging, and monetization strategy for SaaS products
1116. `coreyhaines31:product-marketing-context` [marketing] OFFICIAL — Create and maintain a product marketing context document for consistent messaging
1117. `coreyhaines31:referral-program` [marketing] OFFICIAL — Design and optimize referral, affiliate, and word-of-mouth programs
1118. `coreyhaines31:revops` [marketing][sales] OFFICIAL — Streamline revenue operations, lead lifecycle, and marketing-to-sales handoff
1119. `coreyhaines31:sales-enablement` [sales] OFFICIAL — Create pitch decks, one-pagers, objection handling docs, and demo scripts
1120. `coreyhaines31:schema-markup` [seo] OFFICIAL — Add and optimize schema markup and structured data for better SEO
1121. `coreyhaines31:seo-audit` [seo] OFFICIAL — Audit and diagnose technical and on-page SEO issues on a site
1122. `coreyhaines31:signup-flow-cro` [marketing] OFFICIAL — Optimize signup, registration, and trial activation flows for higher conversion
1123. `coreyhaines31:site-architecture` [marketing][arch] OFFICIAL — Plan and restructure page hierarchy, navigation, and URL structure
1124. `coreyhaines31:social-content` [marketing] OFFICIAL — Create and schedule social media content for LinkedIn, Twitter/X, and Instagram
1125. `realkimbarrett:avatar-extraction` [marketing] OFFICIAL — Define exactly who the buyer is, what they want, what they've tried, and what's driving their decisions
1126. `realkimbarrett:offer-extraction` [marketing][product] OFFICIAL — Turn a product or service into a compelling, high-converting offer
1127. `realkimbarrett:schwartz-awareness-mapper` [marketing] OFFICIAL — Determine audience awareness level and the correct messaging approach
1128. `realkimbarrett:mechanism-builder` [marketing] OFFICIAL — Explain why your solution works and others failed with a unique mechanism
1129. `realkimbarrett:objection-crusher` [marketing] OFFICIAL — Identify and neutralize buyer objections and hesitation
1130. `realkimbarrett:ad-angle-multiplier` [test] OFFICIAL — Expand a core idea into multiple distinct ad angles for creative testing
1131. `realkimbarrett:scroll-stopping-creative` [animation] OFFICIAL — Create ad concepts that stop attention in the first 3 seconds
1132. `realkimbarrett:conversion-path-builder` [marketing] OFFICIAL — Design the optimal funnel from click to conversion and booked calls
1133. `realkimbarrett:performance-diagnosis` [marketing][perf] OFFICIAL — Diagnose why campaigns are underperforming — low conversion, high CPL, bad ads
1134. `realkimbarrett:generic-language-killer` [ai] OFFICIAL — Remove vague, corporate, or AI-sounding language and replace it with clear, specific, human wording
1135. `binance:crypto-market-rank` [general] OFFICIAL — Query crypto market rankings including trending tokens, smart money inflows, meme rankings, and top trader PnL leaderboards
1136. `binance:meme-rush` [marketing][ai] OFFICIAL — Track real-time meme token lists from launchpads (Pump.fun, Four.meme) and AI-powered hot market topics ranked by net inflow
1137. `binance:query-address-info` [trading] OFFICIAL — Retrieve all token holdings and portfolio positions for any wallet address on BSC, Base, or Solana
1138. `binance:query-token-audit` [security] OFFICIAL — Audit token security to detect scams, honeypots, and malicious contracts across BSC, Base, Solana, and Ethereum
1139. `binance:query-token-info` [legal] OFFICIAL — Search tokens and fetch metadata, real-time market data, and K-Line candlestick charts by keyword or contract address
1140. `binance:trading-signal` [trading] OFFICIAL — Monitor on-chain Smart Money buy/sell signals with price, max gain, and exit rate data on Solana and BSC
1141. `binance:spot` [trading][backend] OFFICIAL — Place and manage spot trading orders on Binance via API key authentication, supporting mainnet and testnet
1142. `apollographql:apollo-client` [frontend][backend] OFFICIAL — Build React applications with Apollo Client 4
1143. `apollographql:apollo-connectors` [backend] OFFICIAL — Integrate REST APIs into GraphQL supergraphs using Apollo Connectors
1144. `apollographql:apollo-federation` [seo][backend] OFFICIAL — Write Apollo Federation 2 subgraph schemas and compose them into a supergraph
1145. `apollographql:apollo-kotlin` [mobile][backend] OFFICIAL — A GraphQL client for Android, JVM, and Kotlin Multiplatform projects
1146. `apollographql:apollo-mcp-server` [ai][backend] OFFICIAL — Connect AI agents to GraphQL APIs through the Model Context Protocol
1147. `apollographql:apollo-router` [backend] OFFICIAL — Version-aware configuration generator for the Rust-based Apollo Router
1148. `apollographql:apollo-router-plugin-creator` [backend] OFFICIAL — Write native Rust plugins for Apollo Router
1149. `apollographql:apollo-server` [backend] OFFICIAL — Build GraphQL servers using Apollo Server 5
1150. `apollographql:skill-creator` [backend] OFFICIAL — Create and structure Agent Skills focused on Apollo GraphQL
1151. `auth0:auth0-android` [mobile] OFFICIAL — Add authentication to native Android apps using the Auth0 SDK
1152. `auth0:auth0-angular` [frontend] OFFICIAL — Add authentication to Angular apps using @auth0/auth0-angular
1153. `auth0:auth0-aspnetcore-api` [backend] OFFICIAL — Add JWT access token validation to ASP.NET Core APIs
1154. `auth0:auth0-express` [security] OFFICIAL — Add session-based authentication to Express.js apps
1155. `auth0:auth0-fastify` [security] OFFICIAL — Add session-based authentication to Fastify web apps
1156. `auth0:auth0-fastify-api` [backend] OFFICIAL — Secure Fastify API endpoints with JWT Bearer token validation
1157. `auth0:auth0-mfa` [security] OFFICIAL — Add Multi-Factor Authentication to Auth0-powered apps
1158. `auth0:auth0-migration` [security] OFFICIAL — Migrate users and auth flows from other providers to Auth0
1159. `auth0:auth0-nextjs` [frontend] OFFICIAL — Add authentication to Next.js apps
1160. `auth0:auth0-nuxt` [frontend] OFFICIAL — Add Auth0 authentication to Nuxt 3/4 apps with encrypted cookie sessions
1161. `auth0:auth0-react` [frontend] OFFICIAL — Add authentication to React SPAs using @auth0/auth0-react
1162. `auth0:auth0-react-native` [mobile][frontend] OFFICIAL — Add authentication to React Native and Expo mobile apps
1163. `auth0:auth0-vue` [frontend] OFFICIAL — Add authentication to Vue.js apps
1164. `brave:images-search` [backend] OFFICIAL — Search for images using the Brave Search API
1165. `brave:llm-context` [ai] OFFICIAL — Return pre-extracted web content (text, tables, code) from Brave Search
1166. `brave:local-pois` [research][business] OFFICIAL — Retrieve detailed local business and POI information
1167. `brave:spellcheck` [research] OFFICIAL — Check search queries for spelling errors and get corrections
1168. `brave:suggest` [backend] OFFICIAL — Query autocomplete suggestions via the Brave Search API
1169. `brave:videos-search` [backend] OFFICIAL — Search for videos across the web via the Brave Search API
1170. `brave:web-search` [backend] OFFICIAL — Search the web via Brave's Search API with ranked results
1171. `browserbase:cookie-sync` [test] OFFICIAL — Export cookies from local Chrome into a Browserbase persistent context
1172. `browserbase:functions` [infra][devops] OFFICIAL — Deploy browser automation scripts as serverless cloud functions
1173. `browserbase:search` [backend] OFFICIAL — Search the web via the Browserbase API with structured results
1174. `browserbase:ui-test` [test] OFFICIAL — Run adversarial UI tests by analyzing git diffs in a real browser
1175. `coderabbitai:autofix` [quality] OFFICIAL — Fetch unresolved CodeRabbit review comments from GitHub PRs and apply fixes
1176. `coinbase:authenticate-wallet` [trading][email][payments] OFFICIAL — Handle sign-in for the Coinbase payments wallet via email OTP
1177. `coinbase:fund` [trading] OFFICIAL — Add USDC to a Coinbase-powered wallet through Coinbase Onramp
1178. `coinbase:pay-for-service` [backend] OFFICIAL — Call paid API endpoints that use the x402 protocol with automatic USDC
1179. `coinbase:query-onchain-data` [trading] OFFICIAL — Query decoded onchain data (events, tx, blocks) on Base
1180. `coinbase:search-for-service` [trading] OFFICIAL — Search and browse the x402 bazaar marketplace
1181. `coinbase:send-usdc` [trading] OFFICIAL — Send USDC to any Ethereum address or ENS name on Base
1182. `coinbase:trade` [backend] OFFICIAL — Swap and trade tokens on Base using the CDP Swap API
1183. `coinbase:x402` [payments][backend] OFFICIAL — Discover and call paid API endpoints using the x402 payment protocol
1184. `datadog-labs:dd-apm` [ops] OFFICIAL — Query Datadog APM data directly from your editor
1185. `datadog-labs:dd-llmo-eval-trace-rca` [ai][ops] OFFICIAL — Root-cause LLM app failures using eval traces
1186. `datadog-labs:dd-llmo-experiment-analyzer` [ai][ops] OFFICIAL — Analyze single or comparative LLM experiment results
1187. `firebase:developing-genkit-dart` [ai] OFFICIAL — Build AI apps with the Genkit Dart SDK
1188. `firebase:developing-genkit-go` [ai] OFFICIAL — Build AI apps with the Genkit Go SDK
1189. `firebase:developing-genkit-js` [ai] OFFICIAL — Build AI-powered apps with Firebase Genkit in Node.js
1190. `firebase:firebase-ai-logic-basics` [ai][mobile] OFFICIAL — Call Gemini models from web and mobile apps via Firebase AI Logic
1191. `firebase:firebase-app-hosting-basics` [devops][frontend] OFFICIAL — Deploy and manage full-stack web apps (Next.js, Angular, etc.)
1192. `firebase:firebase-auth-basics` [security] OFFICIAL — Set up Firebase Authentication with sign-in providers
1193. `firebase:firebase-data-connect-basics` [data][infra][backend] OFFICIAL — Build Firebase Data Connect backends backed by Cloud SQL
1194. `firebase:firebase-firestore-enterprise-native-mode` [general] OFFICIAL — Set up and use Firestore Enterprise Native Mode
1195. `firebase:firebase-firestore-standard` [infra] OFFICIAL — Complete guide for Cloud Firestore Standard Edition
1196. `firebase:firebase-hosting-basics` [devops] OFFICIAL — Deploy static sites, SPAs, and microservices to Firebase Hosting
1197. `firebase:firebase-security-rules-auditor` [security] OFFICIAL — Audit Firestore security rules and flag risky patterns
1198. `flutter:flutter-adding-home-screen-widgets` [mobile] OFFICIAL — Add home screen widgets to Flutter apps on Android and iOS
1199. `flutter:flutter-animating-apps` [animation] OFFICIAL — Implement animated effects, transitions, and motion
1200. `flutter:flutter-architecting-apps` [mobile][arch] OFFICIAL — Structure a Flutter app using layered architecture
1201. `flutter:flutter-building-forms` [mobile] OFFICIAL — Build Flutter forms with validation and user input
1202. `flutter:flutter-building-layouts` [mobile] OFFICIAL — Build and fix layouts using the constraint system (Row, Column, Stack)
1203. `flutter:flutter-building-plugins` [mobile] OFFICIAL — Create Flutter plugins that bridge Dart with platform code
1204. `flutter:flutter-caching-data` [mobile] OFFICIAL — Implement offline-first caching strategies
1205. `flutter:flutter-embedding-native-views` [ai][mobile] OFFICIAL — Embed native Android, iOS, and macOS views in Flutter widgets
1206. `flutter:flutter-handling-concurrency` [mobile] OFFICIAL — Run heavy work in background Dart isolates
1207. `flutter:flutter-handling-http-and-json` [mobile] OFFICIAL — Handle HTTP requests and JSON serialization
1208. `flutter:flutter-improving-accessibility` [a11y] OFFICIAL — Configure Flutter for screen readers and assistive tech
1209. `flutter:flutter-interoperating-with-native-apis` [mobile] OFFICIAL — Bridge Flutter with native platform APIs
1210. `flutter:flutter-localizing-apps` [mobile] OFFICIAL — Configure Flutter for multiple languages and regions
1211. `flutter:flutter-managing-state` [mobile] OFFICIAL — Manage local widget state and shared application state
1212. `flutter:flutter-reducing-app-size` [mobile] OFFICIAL — Measure and optimize Flutter app bundle sizes
1213. `flutter:flutter-setting-up-on-linux` [mobile] OFFICIAL — Set up a Linux machine for Flutter desktop development
1214. `flutter:flutter-setting-up-on-macos` [mobile] OFFICIAL — Set up a macOS machine for Flutter development
1215. `flutter:flutter-setting-up-on-windows` [mobile] OFFICIAL — Set up a Windows machine for Flutter development
1216. `flutter:flutter-testing-apps` [test] OFFICIAL — Implement unit, widget, and integration tests
1217. `flutter:flutter-theming-apps` [mobile] OFFICIAL — Customize Flutter app appearance through the theming system
1218. `flutter:flutter-working-with-databases` [data] OFFICIAL — Build a structured data layer using SQLite
1219. `deanpeters:acquisition-channel-advisor` [ml][test] OFFICIAL — Evaluate channels using unit economics and recommend scale/test/kill decisions
1220. `deanpeters:ai-shaped-readiness-advisor` [ai] OFFICIAL — Assess automation vs. redesign opportunities across five competencies
1221. `deanpeters:business-health-diagnostic` [product][pm][business] OFFICIAL — Diagnose SaaS health, identify red flags, and prioritize recovery actions
1222. `deanpeters:customer-journey-map` [product][pm] OFFICIAL — Map customer experience across touchpoints using the NNGroup framework
1223. `deanpeters:eol-message` [product][pm] OFFICIAL — Communicate product or feature deprecation gracefully
1224. `deanpeters:epic-hypothesis` [product][pm] OFFICIAL — Turn initiatives into testable hypotheses with measurable success metrics
1225. `deanpeters:jobs-to-be-done` [product][pm] OFFICIAL — Understand customer objectives using the JTBD framework
1226. `deanpeters:pestel-analysis` [legal] OFFICIAL — Analyze external factors across Political, Economic, Social, Tech, Environmental, and Legal dimensions
1227. `deanpeters:pol-probe` [test] OFFICIAL — Define lightweight validation experiments to test hypotheses
1228. `deanpeters:positioning-statement` [product][pm] OFFICIAL — Define target audience, problem solved, and differentiation using Geoffrey Moore's framework
1229. `deanpeters:press-release` [amazon][devops] OFFICIAL — Clarify product vision with a future press release using Amazon's Working Backwards method
1230. `deanpeters:problem-statement` [product][pm] OFFICIAL — Frame customer problems with evidence before jumping to solutions
1231. `deanpeters:proto-persona` [product][pm] OFFICIAL — Create hypothesis-driven personas before conducting full research
1232. `deanpeters:recommendation-canvas` [ai] OFFICIAL — Document AI-powered product recommendations
1233. `deanpeters:saas-economics-efficiency-metrics` [product][pm] OFFICIAL — Calculate unit economics and capital efficiency including CAC, LTV, payback, and Rule of 40
1234. `deanpeters:saas-revenue-growth-metrics` [marketing] OFFICIAL — Track revenue, retention, and growth metrics including MRR/ARR, churn, NRR, and expansion
1235. `deanpeters:storyboard` [design] OFFICIAL — Visualize user journeys with 6-frame narrative storyboards
1236. `deanpeters:user-story` [product][pm] OFFICIAL — Write user stories with acceptance criteria using Mike Cohn and Gherkin formats
1237. `deanpeters:user-story-mapping` [product][pm] OFFICIAL — Organize stories by user workflow using Jeff Patton's story mapping approach
1238. `deanpeters:user-story-splitting` [product][pm] OFFICIAL — Break down large stories using 8 proven splitting patterns
1239. `deanpeters:context-engineering-advisor` [product][pm] OFFICIAL — Diagnose context stuffing vs. engineering and guide memory and retrieval design
1240. `deanpeters:customer-journey-mapping-workshop` [product][pm] OFFICIAL — Guide journey mapping sessions with pain point identification
1241. `deanpeters:discovery-interview-prep` [test] OFFICIAL — Plan customer interviews using Mom Test style based on research goals
1242. `deanpeters:epic-breakdown-advisor` [product][pm] OFFICIAL — Split epics into stories using Richard Lawrence's 9 splitting patterns
1243. `deanpeters:feature-investment-advisor` [ml] OFFICIAL — Evaluate features using ROI and strategic value scoring
1244. `deanpeters:finance-based-pricing-advisor` [ml][finance] OFFICIAL — Evaluate pricing changes using financial impact analysis
1245. `deanpeters:lean-ux-canvas` [product][pm] OFFICIAL — Set up hypothesis-driven planning using Jeff Gothelf's Lean UX Canvas v2
1246. `deanpeters:pol-probe-advisor` [product][pm] OFFICIAL — Recommend prototype type: Feasibility, Task-Focused, Narrative, Synthetic, or Vibe
1247. `deanpeters:positioning-workshop` [product][pm] OFFICIAL — Guide positioning definition with adaptive discovery questions
1248. `deanpeters:prioritization-advisor` [product][pm] OFFICIAL — Recommend the right prioritization framework (RICE, ICE, Kano, etc.) for your situation
1249. `deanpeters:problem-framing-canvas` [sales] OFFICIAL — Lead through MITRE Problem Framing: Look Inward, Outward, and Reframe
1250. `deanpeters:tam-sam-som-calculator` [product][pm] OFFICIAL — Project market size with real-world data and citations
1251. `deanpeters:user-story-mapping-workshop` [devops] OFFICIAL — Walk through creating story maps with backbone and release slices
1252. `deanpeters:workshop-facilitation` [product][pm] OFFICIAL — Add step-by-step facilitation with numbered recommendations to any workshop
1253. `deanpeters:discovery-process` [product][pm] OFFICIAL — Full discovery cycle: frame problem → research → synthesize → validate (3-4 weeks)
1254. `deanpeters:executive-onboarding-playbook` [animation] OFFICIAL — 30-60-90 day diagnostic playbook for VP/CPO onboarding transitions
1255. `deanpeters:prd-development` [product][pm] OFFICIAL — Structured PRD process: problem → personas → solution → metrics → stories (2-4 days)
1256. `deanpeters:product-strategy-session` [product][pm] OFFICIAL — Full strategy session: positioning → framing → exploration → roadmap (2-4 weeks)
1257. `deanpeters:roadmap-planning` [product][pm] OFFICIAL — Strategic roadmap process: inputs → epics → prioritize → sequence → communicate (1-2 weeks)
1258. `deanpeters:skill-authoring-workflow` [product][pm][meta] OFFICIAL — Meta workflow for authoring skills: choose path → validate → update docs → package
1259. `phuryn:ab-test-analysis` [test] OFFICIAL — Analyze A/B test results with statistical significance and recommendations
1260. `phuryn:cohort-analysis` [product][pm] OFFICIAL — Cohort retention curves, feature adoption, and segment insights
1261. `phuryn:brainstorm-okrs` [product][pm] OFFICIAL — Brainstorm team OKRs aligned with company objectives
1262. `phuryn:outcome-roadmap` [product][pm] OFFICIAL — Transform output roadmaps into outcome-focused strategic plans
1263. `phuryn:pre-mortem` [product][pm] OFFICIAL — Run pre-mortem risk analysis on PRDs and launch plans
1264. `phuryn:retro` [product][pm] OFFICIAL — Facilitate structured sprint retrospectives with action items
1265. `phuryn:sprint-plan` [product][pm] OFFICIAL — Plan sprints with capacity, story selection, and risk mapping
1266. `phuryn:stakeholder-map` [product][pm][api] OFFICIAL — Build stakeholder maps with power/interest grid and comms plan
1267. `phuryn:summarize-meeting` [product][pm] OFFICIAL — Summarize meeting transcripts into structured notes and actions
1268. `phuryn:user-stories` [product][pm][compliance] OFFICIAL — Create INVEST-compliant user stories with 3 C's structure
1269. `phuryn:beachhead-segment` [product][pm] OFFICIAL — Identify the first beachhead market segment for product launch
1270. `phuryn:competitive-battlecard` [sales] OFFICIAL — Create sales-ready battlecards against specific competitors
1271. `phuryn:growth-loops` [marketing] OFFICIAL — Identify growth loops across 5 flywheel types for traction
1272. `phuryn:gtm-motions` [animation] OFFICIAL — Identify best GTM motions across 7 types including PLG and ABM
1273. `phuryn:gtm-strategy` [product][pm] OFFICIAL — Create GTM strategy with channels, messaging, and launch timeline
1274. `phuryn:ideal-customer-profile` [product][pm] OFFICIAL — Identify ICP with demographics, behaviors, and JTBD
1275. `phuryn:competitor-analysis` [product][pm] OFFICIAL — Analyze competitors with strengths, weaknesses, and differentiation
1276. `phuryn:customer-journey-map` [animation] OFFICIAL — Map customer journeys with touchpoints, emotions, and opportunities
1277. `phuryn:market-segments` [product][pm] OFFICIAL — Identify 3-5 customer segments with JTBD and product fit
1278. `phuryn:market-sizing` [product][pm] OFFICIAL — Estimate TAM, SAM, SOM with top-down and bottom-up approaches
1279. `phuryn:sentiment-analysis` [product][pm] OFFICIAL — Analyze user feedback with sentiment scores and JTBD insights
1280. `phuryn:user-personas` [product][pm] OFFICIAL — Create 3 user personas with JTBD, pains, and gains
1281. `phuryn:user-segmentation` [product][pm] OFFICIAL — Segment users by behavior, JTBD, and needs from feedback data
1282. `phuryn:north-star-metric` [product][pm] OFFICIAL — Define North Star Metric and input metrics constellation
1283. `phuryn:positioning-ideas` [product][pm] OFFICIAL — Brainstorm positioning ideas differentiated from competitors
1284. `phuryn:product-name` [design] OFFICIAL — Brainstorm 5 memorable product names aligned to brand values
1285. `phuryn:analyze-feature-requests` [design] OFFICIAL — Prioritize feature requests by theme, impact, effort, and risk
1286. `phuryn:brainstorm-experiments-existing` [test] OFFICIAL — Design experiments to test assumptions for existing products
1287. `phuryn:brainstorm-experiments-new` [product][pm] OFFICIAL — Design lean pretotypes for new product validation
1288. `phuryn:brainstorm-ideas-existing` [product][pm] OFFICIAL — Brainstorm product ideas from PM, Designer, Engineer perspectives
1289. `phuryn:brainstorm-ideas-new` [product][pm] OFFICIAL — Brainstorm feature ideas for new products in early discovery
1290. `phuryn:identify-assumptions-existing` [product][pm] OFFICIAL — Identify risky assumptions across Value, Usability, Viability, Feasibility
1291. `phuryn:identify-assumptions-new` [product][pm] OFFICIAL — Identify risky assumptions for new products across 8 risk categories
1292. `phuryn:interview-script` [product][pm] OFFICIAL — Create structured customer interview scripts with JTBD probing
1293. `phuryn:metrics-dashboard` [product][pm] OFFICIAL — Define product metrics dashboard with sources and alert thresholds
1294. `phuryn:opportunity-solution-tree` [product][pm] OFFICIAL — Build Opportunity Solution Trees based on Teresa Torres' method
1295. `phuryn:prioritize-assumptions` [product][pm] OFFICIAL — Prioritize assumptions with Impact × Risk matrix and experiments
1296. `phuryn:prioritize-features` [product][pm] OFFICIAL — Prioritize backlog by impact, effort, risk, and strategic alignment
1297. `phuryn:summarize-interview` [product][pm] OFFICIAL — Summarize interview transcripts with JTBD and action items
1298. `phuryn:ansoff-matrix` [marketing] OFFICIAL — Ansoff Matrix analysis across 4 growth strategy quadrants
1299. `phuryn:monetization-strategy` [product][pm] OFFICIAL — Brainstorm 3-5 monetization strategies with validation experiments
1300. `phuryn:pestle-analysis` [legal] OFFICIAL — PESTLE analysis across Political, Economic, Social, Tech, Legal, Environmental
1301. `phuryn:porters-five-forces` [product][pm] OFFICIAL — Porter's Five Forces competitive analysis with strategic insights
1302. `phuryn:pricing-strategy` [finance] OFFICIAL — Design pricing strategies with competitive analysis and WTP estimation
1303. `phuryn:product-strategy` [product][pm] OFFICIAL — Create product strategy using 9-section Product Strategy Canvas
1304. `phuryn:product-vision` [product][pm] OFFICIAL — Brainstorm inspiring, achievable product vision statements
1305. `phuryn:swot-analysis` [product][pm] OFFICIAL — SWOT analysis with actionable recommendations per quadrant
1306. `phuryn:draft-nda` [product][pm] OFFICIAL — Draft NDAs covering information types, jurisdiction, and clauses
1307. `phuryn:grammar-check` [product][pm] OFFICIAL — Identify grammar and flow errors with targeted fix suggestions
1308. `phuryn:privacy-policy` [legal] OFFICIAL — Draft privacy policies with GDPR compliance considerations
1309. `MiniMax-AI:fullstack-dev` [ai][data][security][backend] OFFICIAL — Backend architecture with REST API design, auth flows, real-time features, and database integration
1310. `MiniMax-AI:android-native-dev` [ai][mobile][a11y] OFFICIAL — Android native development with Kotlin/Jetpack Compose, Material Design 3, and accessibility
1311. `MiniMax-AI:ios-application-dev` [ai][mobile][legal] OFFICIAL — iOS development with UIKit, SnapKit, and SwiftUI covering navigation, Dark Mode, and HIG compliance
1312. `MiniMax-AI:shader-dev` [3d][ai] OFFICIAL — GLSL shader techniques for ray marching, fluid simulation, particle systems, and procedural generation
1313. `MiniMax-AI:gif-sticker-maker` [ai][backend] OFFICIAL — Convert photos into animated GIF stickers in Funko Pop / Pop Mart style via MiniMax API
1314. `MiniMax-AI:pptx-generator` [ai] OFFICIAL — Create and edit PowerPoint presentations from scratch with PptxGenJS
1315. `MiniMax-AI:minimax-docx` [ai] OFFICIAL — Professional DOCX document creation and editing using OpenXML SDK
1316. `duckdb:attach-db` [seo][data] OFFICIAL — Attach a DuckDB database file for interactive querying with automatic schema exploration
1317. `duckdb:query` [data] OFFICIAL — Run SQL queries against attached databases or ad-hoc against files using Friendly SQL dialect
1318. `duckdb:read-file` [data] OFFICIAL — Read any data file (CSV, JSON, Parquet, Avro, Excel, spatial) locally or from remote storage
1319. `duckdb:duckdb-docs` [data][docs] OFFICIAL — Search DuckDB and DuckLake documentation using full-text search over HTTPS
1320. `duckdb:read-memories` [ai][data] OFFICIAL — Search past Claude Code session logs to recover context from previous conversations
1321. `greensock:gsap-core` [animation][backend] OFFICIAL — Core API with gsap.to(), from(), fromTo(), easing, duration, stagger, and defaults
1322. `greensock:gsap-timeline` [animation] OFFICIAL — Timelines with sequencing, position parameter, labels, nesting, and playback control
1323. `greensock:gsap-scrolltrigger` [animation] OFFICIAL — ScrollTrigger for scroll-linked animations, pinning, scrub, and refresh handling
1324. `greensock:gsap-plugins` [animation] OFFICIAL — Plugins including ScrollToPlugin, Flip, Draggable, SplitText, SVG, and physics
1325. `greensock:gsap-utils` [animation] OFFICIAL — Utility functions like clamp, mapRange, interpolate, snap, selector, and wrap
1326. `greensock:gsap-react` [animation][frontend] OFFICIAL — React integration with useGSAP hook, refs, gsap.context(), cleanup, and SSR
1327. `greensock:gsap-performance` [animation][perf] OFFICIAL — Performance tips for transforms, will-change, batching, and ScrollTrigger optimization
1328. `greensock:gsap-frameworks` [animation][frontend] OFFICIAL — Vue, Svelte, and other frameworks with lifecycle, scoping, and cleanup patterns
1329. `garrytan:office-hours` [product][meta] OFFICIAL — YC Office Hours: six forcing questions that reframe your product before you write code
1330. `garrytan:plan-ceo-review` [product][meta] OFFICIAL — CEO/Founder plan review with four modes: Expansion, Selective Expansion, Hold Scope, Reduction
1331. `garrytan:plan-eng-review` [test] OFFICIAL — Eng Manager review: lock in architecture, data flow, diagrams, edge cases, and tests
1332. `garrytan:plan-design-review` [ai] OFFICIAL — Senior Designer review: rates each design dimension 0-10, explains what a 10 looks like, AI Slop detection
1333. `garrytan:design-consultation` [design] OFFICIAL — Build a complete design system from scratch with creative risks and realistic product mockups
1334. `garrytan:design-review` [design] OFFICIAL — Designer Who Codes: visual audit then fixes with atomic commits and before/after screenshots
1335. `garrytan:review` [product][meta][quality][devops] OFFICIAL — Staff Engineer code review: finds bugs that pass CI but blow up in production
1336. `garrytan:investigate` [test] OFFICIAL — Systematic root-cause debugging: no fixes without investigation, traces data flow, tests hypotheses
1337. `garrytan:qa-only` [product][meta][test] OFFICIAL — QA Reporter: same methodology as /qa but report only, no code changes
1338. `garrytan:cso` [security] OFFICIAL — Chief Security Officer: OWASP Top 10 + STRIDE threat model with zero false-positive exclusions
1339. `garrytan:ship` [devops][test] OFFICIAL — Release Engineer: sync main, run tests, audit coverage, push, open PR
1340. `garrytan:land-and-deploy` [devops] OFFICIAL — Merge the PR, wait for CI and deploy, verify production health
1341. `garrytan:canary` [devops][perf][ops] OFFICIAL — SRE post-deploy monitoring: watches for console errors, performance regressions, and page failures
1342. `garrytan:benchmark` [perf] OFFICIAL — Performance Engineer: baseline page load times, Core Web Vitals, and resource sizes
1343. `garrytan:document-release` [devops][docs] OFFICIAL — Technical Writer: update all project docs to match what you just shipped
1344. `garrytan:retro` [product][meta] OFFICIAL — Eng Manager weekly retro with per-person breakdowns and shipping streaks
1345. `garrytan:browse` [product][meta][test] OFFICIAL — Real Chromium browser for QA: real clicks, real screenshots, ~100ms per command
1346. `garrytan:autoplan` [product][meta] OFFICIAL — One command, fully reviewed plan: runs CEO → design → eng review automatically
1347. `garrytan:careful` [product][meta] OFFICIAL — Safety Guardrails: warns before destructive commands (rm -rf, DROP TABLE, force-push)
1348. `garrytan:guard` [product][meta] OFFICIAL — Full Safety: /careful + /freeze in one command for maximum safety
1349. `garrytan:unfreeze` [product][meta][arch] OFFICIAL — Unlock: remove the /freeze boundary
1350. `garrytan:gstack-upgrade` [product][meta] OFFICIAL — Self-Updater: upgrade gstack to latest version
1351. `makenotion:knowledge-capture` [docs] OFFICIAL — Transform conversations into structured Notion documentation pages with proper organization and linking
1352. `makenotion:meeting-intelligence` [marketing] OFFICIAL — Prepare meeting materials by gathering Notion context and creating pre-reads and agendas
1353. `makenotion:spec-to-implementation` [product] OFFICIAL — Turn product/tech specs into concrete Notion tasks with acceptance criteria and progress tracking
1354. `resend:resend` [email][backend] OFFICIAL — Send and manage emails via the Resend API
1355. `resend:react-email` [email][frontend] OFFICIAL — Build emails with React Email components
1356. `resend:agent-email-inbox` [ai][email] OFFICIAL — AI agent email inbox management
1357. `addyosmani:performance` [perf] OFFICIAL — Loading speed, runtime efficiency, and resource optimization
1358. `addyosmani:core-web-vitals` [general] OFFICIAL — LCP, INP, and CLS-specific optimizations
1359. `addyosmani:accessibility` [legal][a11y] OFFICIAL — WCAG compliance, screen reader support, and keyboard navigation
1360. `addyosmani:seo` [seo] OFFICIAL — Search engine optimization, crawlability, and structured data
1361. `mongodb:mongodb-connection` [data] OFFICIAL — Optimize MongoDB client connection pools, timeouts, and serverless patterns
1362. `mongodb:atlas-stream-processing` [data][devops] OFFICIAL — Build, operate, and debug Atlas Stream Processing pipelines with Kafka, S3, and Lambda integrations
1363. `mongodb:mongodb-natural-language-querying` [data][devops] OFFICIAL — Translate natural language into MongoDB queries and aggregation pipelines
1364. `mongodb:mongodb-query-optimizer` [data][perf] OFFICIAL — Analyze and optimize query performance using Atlas Performance Advisor
1365. `mongodb:mongodb-search-and-ai` [ai][data] OFFICIAL — Implement Atlas Search and AI-powered recommendations with vector search
1366. `NVIDIA:CUDA-Q:cudaq-guide` [test] OFFICIAL — CUDA-Q onboarding guide for installation, test programs, GPU simulation, QPU hardware, and quantum applications.
1367. `NVIDIA:DALI:dali-dynamic-mode` [devops] OFFICIAL — Use when writing DALI data loading or preprocessing code with `nvidia.dali.experimental.dynamic` (ndd), or when converting DALI pipeline-mod
1368. `NVIDIA:Megatron-Bridge:adding-model-support` [ml][ai] OFFICIAL — Guide for adding support for new LLM or VLM models in Megatron-Bridge.
1369. `NVIDIA:Megatron-Bridge:linting-and-formatting` [ml] OFFICIAL — Code style and quality rules for Megatron Bridge — ruff configuration, naming conventions, type hints, mypy rules, docstrings, copyright hea
1370. `NVIDIA:Megatron-Bridge:mlm-bridge-training` [ml] OFFICIAL — Run Megatron-LM (MLM) and Megatron Bridge training with mock or real data.
1371. `NVIDIA:Megatron-Bridge:multi-node-slurm` [ml] OFFICIAL — Convert single-node scripts to multi-node Slurm sbatch jobs and debug common multi-node failures.
1372. `NVIDIA:Megatron-Bridge:nemo-rl-e2e-testing` [ml][test] OFFICIAL — External NeMo-RL end-to-end validation workflow for Megatron-Bridge model/provider changes, including downstream compatibility checks, exter
1373. `NVIDIA:Megatron-Bridge:parity-testing` [marketing][ml][test] OFFICIAL — Structured framework for verifying numerical parity of HF<->MCore weight conversions.
1374. `NVIDIA:Megatron-Bridge:perf-activation-recompute` [ml] OFFICIAL — Validate and use selective and full activation recompute in Megatron Bridge to reduce GPU memory usage at the cost of extra compute.
1375. `NVIDIA:Megatron-Bridge:perf-cpu-offloading` [ml] OFFICIAL — Validate and use CPU offloading in Megatron Bridge, including layer-level activation offloading and fractional optimizer state offloading wi
1376. `NVIDIA:Megatron-Bridge:perf-cuda-graphs` [ml] OFFICIAL — Validate and use CUDA graph capture in Megatron Bridge, including local full-iteration graphs and Transformer Engine scoped graphs for atten
1377. `NVIDIA:Megatron-Bridge:perf-expert-parallel-overlap` [ml][backend] OFFICIAL — Validate and use MoE expert-parallel communication overlap in Megatron-Bridge, including overlap_moe_expert_parallel_comm, delay_wgrad_compu
1378. `NVIDIA:Megatron-Bridge:perf-memory-tuning` [ml] OFFICIAL — Techniques for reducing peak GPU memory in Megatron Bridge — expandable segments, parallelism resizing, activation recompute, CPU offloading
1379. `NVIDIA:Megatron-Bridge:perf-moe-comm-overlap` [ml] OFFICIAL — MoE expert-parallel communication overlap in Megatron Bridge.
1380. `NVIDIA:Megatron-Bridge:perf-moe-hardware-configs` [ml] OFFICIAL — Representative MoE training playbooks by hardware platform and model family.
1381. `NVIDIA:Megatron-Bridge:perf-moe-long-context` [ml] OFFICIAL — Long-context MoE training guidance for Megatron Bridge.
1382. `NVIDIA:Megatron-Bridge:perf-moe-optimization-workflow` [ml] OFFICIAL — Systematic workflow for MoE training optimization in Megatron Bridge, based on the Megatron-Core MoE paper.
1383. `NVIDIA:Megatron-Bridge:perf-moe-vlm-training` [ml] OFFICIAL — Practical guidance for training MoE VLMs in Megatron Bridge.
1384. `NVIDIA:Megatron-Bridge:perf-parallelism-strategies` [ml] OFFICIAL — Operational guide for choosing and combining parallelism strategies in Megatron Bridge, including sizing rules, hardware topology mapping, a
1385. `NVIDIA:Megatron-Bridge:perf-sequence-packing` [ml] OFFICIAL — Validate and use packed sequences and long-context training in Megatron-Bridge, distinguishing offline packed SFT for LLMs from in-batch pac
1386. `NVIDIA:Megatron-Bridge:recipe-recommender` [ml] OFFICIAL — Recommend and customize Megatron Bridge recipes for a user's model, GPU count, and training goal.
1387. `NVIDIA:Megatron-Bridge:resiliency` [ml] OFFICIAL — Resiliency features in Megatron Bridge including fault tolerance, straggler detection, in-process restart, preemption, and re-run state mach
1388. `NVIDIA:Megatron-Bridge:verl-e2e-testing` [ml][test] OFFICIAL — External verl end-to-end validation workflow for Megatron-Bridge model/provider changes.
1389. `NVIDIA:Megatron-Core:bump-base-image` [ml] OFFICIAL — Bump the NVIDIA PyTorch base image (`nvcr.io/nvidia/pytorch:<YY.MM>-py3`) used by Megatron-LM CI.
1390. `NVIDIA:Megatron-Core:create-issue` [ml][devops] OFFICIAL — Investigate a failing GitHub Actions run or job and create a GitHub issue for the failure.
1391. `NVIDIA:Megatron-Core:linting-and-formatting` [ml] OFFICIAL — Linting and formatting for Megatron-LM.
1392. `NVIDIA:Megatron-Core:nightly-sync` [ml] OFFICIAL — Domain knowledge for the nightly main-to-dev sync workflow.
1393. `NVIDIA:Megatron-Core:onboard-gb200-1node-tests` [ml][test] OFFICIAL — Onboard 1-node GitHub MR functional tests for GB200 from existing mr-scoped 2-node tests.
1394. `NVIDIA:Megatron-Core:respond-to-issue` [ml] OFFICIAL — Research and draft a response to a GitHub issue or question from an external contributor.
1395. `NVIDIA:Megatron-Core:run-on-slurm` [ml] OFFICIAL — How to launch distributed Megatron-LM training jobs on a SLURM cluster.
1396. `NVIDIA:Megatron-Core:split-pr` [ml] OFFICIAL — Split a PR into multiple PRs to reduce the number of required CODEOWNERS reviewer groups.
1397. `NVIDIA:Megatron-Core:testing` [ml][test] OFFICIAL — Test system for Megatron-LM.
1398. `NVIDIA:Megatron-Core:update-golden-values` [ml][devops] OFFICIAL — Refresh golden values from a GitHub Actions workflow run (failing-only or all jobs), score the change with average normalized relative diffe
1399. `NVIDIA:Model-Optimizer:accessing-mlflow` [ml] OFFICIAL — Query and browse evaluation results stored in MLflow.
1400. `NVIDIA:Model-Optimizer:debug` [infra] OFFICIAL — Run commands inside a remote Docker container via the file-based command relay (tools/debugger).
1401. `NVIDIA:Model-Optimizer:deployment` [ai][devops][backend] OFFICIAL — Serve a quantized or unquantized LLM checkpoint as an OpenAI-compatible API endpoint using vLLM, SGLang, or TRT-LLM.
1402. `NVIDIA:Model-Optimizer:evaluation` [ml] OFFICIAL — Evaluates accuracy of quantized or unquantized LLMs using NeMo Evaluator Launcher (NEL).
1403. `NVIDIA:Model-Optimizer:launching-evals` [ml][ai] OFFICIAL — Run, monitor, analyze, and debug LLM evaluations via nemo-evaluator-launcher.
1404. `NVIDIA:Model-Optimizer:monitor` [ml][devops] OFFICIAL — Monitor submitted jobs (PTQ, evaluation, deployment) on SLURM clusters.
1405. `NVIDIA:Model-Optimizer:ptq` [ml] OFFICIAL — This skill should be used when the user asks to "quantize a model", "run PTQ", "post-training quantization", "NVFP4 quantization", "FP8 quan
1406. `NVIDIA:Model-Optimizer:release-cherry-pick` [devops] OFFICIAL — Cherry-pick merged PRs labeled for a release branch into that branch, then open a PR and apply the cherry-pick-done label.
1407. `NVIDIA:NeMo-Evaluator:byob` [ml][ai] OFFICIAL — Create custom LLM evaluation benchmarks using the BYOB decorator framework.
1408. `NVIDIA:NeMo-Evaluator-Launcher:accessing-mlflow` [ml] OFFICIAL — Query and browse evaluation results stored in MLflow.
1409. `NVIDIA:NeMo-Evaluator-Launcher:launching-evals` [ml][ai] OFFICIAL — Run, monitor, analyze, and debug LLM evaluations via nemo-evaluator-launcher.
1410. `NVIDIA:NeMo-Gym:add-benchmark` [ml] OFFICIAL — > Guide for adding a new benchmark or training environment to NeMo-Gym.
1411. `NVIDIA:NeMo-Gym:nemo-gym-debugging` [ml] OFFICIAL — >- Use when debugging a Nemo Gym run or reward profiling job.
1412. `NVIDIA:NeMo-Gym:nemo-gym-docs` [ml] OFFICIAL — > Maintain the NeMo Gym Fern docs site — add, update, move, or remove pages under fern/.
1413. `NVIDIA:NeMo-Gym:nemo-gym-pivot-datasets` [ml][backend] OFFICIAL — >- Use when creating, validating, or documenting Nemo Gym pivot datasets from rollout, trajectory, chat-completion, Responses API, or tool-c
1414. `NVIDIA:NeMo-Gym:nemo-gym-reward-profiling` [ml] OFFICIAL — >- Use to help users get started with Nemo Gym reward profiling.
1415. `NVIDIA:NeMo-RL:auto-research` [ml][test] OFFICIAL — Autonomous NeMo-RL research agent workflow for directed hypothesis testing and open-ended discovery.
1416. `NVIDIA:NeMo-RL:brev-etiquette` [ml][security] OFFICIAL — Brev instance operating guidance for NeMo-RL agents working in /home/ubuntu/RL with limited workspace disk, a larger /ephemeral volume, and 
1417. `NVIDIA:NeMo-RL:build-and-dependency` [ml] OFFICIAL — Build and dependency management for NeMo-RL.
1418. `NVIDIA:NeMo-RL:contributing` [ml] OFFICIAL — Contribution conventions for NeMo-RL.
1419. `NVIDIA:NeMo-RL:copyright` [ml] OFFICIAL — NVIDIA copyright header requirements for NeMo-RL.
1420. `NVIDIA:NeMo-RL:docs` [ml][docs] OFFICIAL — Documentation conventions for NeMo-RL.
1421. `NVIDIA:NeMo-RL:error-handling` [ml] OFFICIAL — Error handling guidelines for NeMo-RL.
1422. `NVIDIA:NeMo-RL:linting-and-formatting` [ml] OFFICIAL — Code style guidelines for NeMo-RL (Python and shell).
1423. `NVIDIA:NeMo-RL:review-pr` [ml] OFFICIAL — Interactive code review for NVIDIA-NeMo/RL pull requests.
1424. `NVIDIA:NeMo-RL:session-memory` [ml] OFFICIAL — Manage durable working-session memory for coding agents.
1425. `NVIDIA:NeMo-RL:testing` [ml][test] OFFICIAL — Testing conventions for NeMo-RL.
1426. `NVIDIA:NemoClaw:nemoclaw-maintainer-cross-issue-sweep` [ml] OFFICIAL — Scans other open issues to find ones a given PR may also fix or accidentally break.
1427. `NVIDIA:NemoClaw:nemoclaw-maintainer-cut-release-tag` [ml][devops] OFFICIAL — Cut a new semver release — bump all version strings via bump-version.ts, open a release PR, and after merge tag main and push.
1428. `NVIDIA:NemoClaw:nemoclaw-maintainer-day` [ml] OFFICIAL — Runs the daytime maintainer loop for NemoClaw, prioritizing items labeled with the current version target.
1429. `NVIDIA:NemoClaw:nemoclaw-maintainer-evening` [ml] OFFICIAL — Runs the end-of-day maintainer handoff for NemoClaw.
1430. `NVIDIA:NemoClaw:nemoclaw-maintainer-find-review-pr` [ml][security] OFFICIAL — Finds open GitHub PRs with security and priority-high labels, links each to its issue, detects duplicates (multiple PRs fixing the same issu
1431. `NVIDIA:NemoClaw:nemoclaw-maintainer-morning` [ml] OFFICIAL — Runs the morning maintainer standup for NemoClaw.
1432. `NVIDIA:NemoClaw:nemoclaw-maintainer-normalize-title-tags` [ml] OFFICIAL — Normalizes GitHub issue and PR titles by removing any bracketed [NemoClaw] tag case-insensitively, even when the tag appears later in the ti
1433. `NVIDIA:NemoClaw:nemoclaw-maintainer-pr-comparator` [ml] OFFICIAL — Compares competing PRs that target the same issue and recommends which one to merge.
1434. `NVIDIA:NemoClaw:nemoclaw-maintainer-triage` [ml][ai] OFFICIAL — AI-assisted label triage for NVIDIA/NemoClaw issues and PRs.
1435. `NVIDIA:NemoClaw:nemoclaw-skills-guide` [ml] OFFICIAL — Start here.
1436. `NVIDIA:NemoClaw:nemoclaw-user-agent-skills` [ml] OFFICIAL — Describes the agent skills shipped with NemoClaw and how to access them by cloning the repository.
1437. `NVIDIA:NemoClaw:nemoclaw-user-configure-inference` [ml][backend] OFFICIAL — Connects NemoClaw to a local inference server.
1438. `NVIDIA:NemoClaw:nemoclaw-user-configure-security` [ml][security] OFFICIAL — Presents a risk framework for every configurable security control in NemoClaw.
1439. `NVIDIA:NemoClaw:nemoclaw-user-deploy-remote` [ml][devops] OFFICIAL — Explains how to run NemoClaw on a remote GPU instance, including the deprecated Brev compatibility path and the preferred installer plus onb
1440. `NVIDIA:NemoClaw:nemoclaw-user-get-started` [ml][ai] OFFICIAL — Installs NemoClaw, launches a sandbox, and runs the first agent prompt.
1441. `NVIDIA:NemoClaw:nemoclaw-user-manage-policy` [ml] OFFICIAL — Adds, removes, or modifies allowed endpoints in the sandbox policy.
1442. `NVIDIA:NemoClaw:nemoclaw-user-monitor-sandbox` [ml] OFFICIAL — Inspects sandbox health, traces agent behavior, and diagnoses problems.
1443. `NVIDIA:NemoClaw:nemoclaw-user-overview` [ml] OFFICIAL — Explains how OpenClaw, OpenShell, and NemoClaw form the ecosystem, NemoClaw's position in the stack, what NemoClaw adds beyond the community
1444. `NVIDIA:TensorRT-LLM:ad-add-fusion-transformation` [ai][devops][payments] OFFICIAL — > Claude Code skill (trtllm-agent-toolkit): implement or extend TensorRT-LLM AutoDeploy fusion transforms under transform/library/ in a Tens
1445. `NVIDIA:TensorRT-LLM:ad-conf-check` [ai][devops][backend] OFFICIAL — > Check whether AutoDeploy YAML configs were actually applied by analyzing server logs and optionally graph dumps (AD_DUMP_GRAPHS_DIR).
1446. `NVIDIA:TensorRT-LLM:ad-graph-dump` [ai][devops] OFFICIAL — > Enable and interpret TensorRT-LLM AutoDeploy FX graph text dumps via AD_DUMP_GRAPHS_DIR.
1447. `NVIDIA:TensorRT-LLM:ad-layer-visualizer` [design][ai][devops] OFFICIAL — > Visualize a specific transformer decoder layer from an AutoDeploy FX graph text dump as a hierarchical DOT/PNG diagram.
1448. `NVIDIA:TensorRT-LLM:exec-local-compile` [ai][infra] OFFICIAL — Compile TensorRT-LLM on a compute node inside a Docker container.
1449. `NVIDIA:TensorRT-LLM:exec-slurm-compile` [ai] OFFICIAL — Compile TensorRT-LLM on a SLURM cluster.
1450. `NVIDIA:TensorRT-LLM:kernel-cute-writing` [ai][backend] OFFICIAL — > Write and implement GPU kernels using NVIDIA CuTe DSL (CUTLASS 4.x Python API) — NOT for Triton, CUDA C++, or conceptual explanations.
1451. `NVIDIA:TensorRT-LLM:kernel-tileir-optimization` [ai][backend] OFFICIAL — > Optimize existing Triton kernels for NVIDIA TileIR backend on Blackwell GPUs (sm_100+).
1452. `NVIDIA:TensorRT-LLM:kernel-triton-writing` [ai] OFFICIAL — > ONLY for OpenAI Triton (@triton.jit) kernel development.
1453. `NVIDIA:TensorRT-LLM:perf-analysis` [ai][perf] OFFICIAL — > Performance analysis coordination workflow.
1454. `NVIDIA:TensorRT-LLM:perf-host-analysis` [ai] OFFICIAL — > Analyze host/CPU overhead in TensorRT-LLM inference from nsys traces.
1455. `NVIDIA:TensorRT-LLM:perf-host-optimization` [ai] OFFICIAL — Profiles and optimizes TensorRT-LLM host/CPU overhead using line_profiler (with nsys support planned).
1456. `NVIDIA:TensorRT-LLM:perf-nsight-compute-analysis` [ai] OFFICIAL — > Analyze ncu (NVIDIA Nsight Compute) profiling output: SOL% bottleneck classification, roofline analysis, occupancy diagnosis, memory hiera
1457. `NVIDIA:TensorRT-LLM:perf-optimization` [ai][perf] OFFICIAL — > Performance optimization coordination playbook.
1458. `NVIDIA:TensorRT-LLM:perf-torch-cuda-graphs` [marketing][ml][ai][backend] OFFICIAL — >- Apply CUDA Graphs to PyTorch workloads — API selection (torch.compile, PyTorch make_graphed_callables, TE make_graphed_callables, MCore C
1459. `NVIDIA:TensorRT-LLM:perf-torch-sync-free` [ml][ai] OFFICIAL — >- Identify and eliminate host-device synchronizations in PyTorch code.
1460. `NVIDIA:TensorRT-LLM:perf-workload-profiling` [marketing][ai] OFFICIAL — > Code instrumentation for timing workloads.
1461. `NVIDIA:TensorRT-LLM:trtllm-codebase-exploration` [ai] OFFICIAL — > Systematic approach to exploring the TensorRT-LLM codebase before implementing new features or optimizations.
1462. `NVIDIA:TensorRT-LLM:trtllm-flashinfer-upgrade` [ai] OFFICIAL — >- Upgrade flashinfer-python version in TensorRT-LLM.
1463. `NVIDIA:TensorRT-LLM:trtllm-moe-develop` [ml][ai] OFFICIAL — >- Review, design, and refactor TensorRT-LLM PyTorch MoE code for architecture fit, clean code, maintainability, and testability.
1464. `NVIDIA:TileGym:adding-cutile-kernel` [ml] OFFICIAL — Add a new cuTile GPU kernel operator to TileGym.
1465. `NVIDIA:TileGym:converting-cutile-to-julia` [ml] OFFICIAL — Converts cuTile Python GPU kernels (@ct.kernel) to cuTile.jl Julia equivalents.
1466. `NVIDIA:TileGym:converting-cutile-to-triton` [ml] OFFICIAL — Converts cuTile GPU kernels (@ct.kernel) to Triton (@triton.jit).
1467. `NVIDIA:TileGym:cutile-autotuning` [ml][test] OFFICIAL — Use when adding, modifying, optimizing, or debugging CuTile autotuning code.
1468. `NVIDIA:TileGym:cutile-python` [ml] OFFICIAL — Expert cuTile programming assistant.
1469. `NVIDIA:TileGym:improve-cutile-kernel-perf` [perf] OFFICIAL — Iteratively optimize cuTile kernel performance through systematic profiling, bottleneck analysis, IR comparison, and targeted tuning.
1470. `NVIDIA:TileGym:monkey-patch-kernels-to-transformers` [ml] OFFICIAL — Integrate TileGym kernels into Hugging Face `transformers` models by replacing the library's submodule(s) and certain class(es)' implementat
1471. `NVIDIA:cuopt:cuopt-developer` [test][backend] OFFICIAL — Modify, build, test, debug, and contribute to NVIDIA cuOpt (C++/CUDA, Python, server, CI).
1472. `NVIDIA:cuopt:cuopt-install` [infra][backend] OFFICIAL — Install cuOpt for Python, C, or as a server (pip, conda, Docker) — system requirements, install commands, and verification.
1473. `NVIDIA:cuopt:cuopt-numerical-optimization-api-c` [backend] OFFICIAL — LP, MILP, and QP (beta) with cuOpt — C API only.
1474. `NVIDIA:cuopt:cuopt-numerical-optimization-api-python` [backend] OFFICIAL — Solve Linear Programming (LP), Mixed-Integer Linear Programming (MILP), and Quadratic Programming (QP, beta) with the Python API.
1475. `NVIDIA:cuopt:cuopt-routing-api-python` [backend] OFFICIAL — Vehicle routing (VRP, TSP, PDP) with cuOpt — Python API only.
1476. `NVIDIA:cuopt:cuopt-server-api-python` [backend] OFFICIAL — cuOpt REST server — start server, endpoints, Python/curl client examples.
1477. `NVIDIA:cuopt:cuopt-server-common` [backend] OFFICIAL — cuOpt REST server — what it does and how requests flow.
1478. `NVIDIA:cuopt:cuopt-user-rules` [backend] OFFICIAL — Base rules for end users calling NVIDIA cuOpt (routing/LP/MILP/QP/install/server).
1479. `NVIDIA:cuopt:numerical-optimization-formulation` [ml] OFFICIAL — Numerical optimization (LP, MILP, QP) — concepts, problem-text parsing, and formulation patterns.
1480. `NVIDIA:cuopt:routing-formulation` [ml] OFFICIAL — Vehicle routing (VRP, TSP, PDP) — problem types and data requirements.
1481. `NVIDIA:cuopt:skill-evolution` [ml] OFFICIAL — After solving a non-trivial problem, detect generalizable learnings and propose skill updates so future interactions benefit automatically.
1482. `NVIDIA:nemotron-voice-agent:nemotron-voice-agent-deploy` [ml][infra][devops] OFFICIAL — Deploy Nemotron Voice Agent on Workstation (x86), Jetson Thor, or Cloud NIMs.
1483. `NVIDIA:rag:rag-blueprint` [ml][devops] OFFICIAL — "NVIDIA RAG Blueprint — deploy, configure, troubleshoot, and manage.
1484. `NVIDIA:video-search-and-summarization:alerts` [devops] OFFICIAL — Manage and monitor VSS alerts after the alerts profile is deployed.
1485. `NVIDIA:video-search-and-summarization:rt-vlm` [backend] OFFICIAL — > Use this skill when working with the RTVI VLM or RT-VLM microservice API on VSS 3.1.
1486. `NVIDIA:video-search-and-summarization:video-analytics` [data][backend] OFFICIAL — Query video analytics data and metrics from Elastic search via the VA-MCP server (port 9901).
1487. `NVIDIA:video-search-and-summarization:video-search` [ml] OFFICIAL — Search video archives using natural language — find events, objects, actions, and people across recorded video using fusion search (Cosmos E
1488. `NVIDIA:video-search-and-summarization:video-summarization` [ml] OFFICIAL — Summarize a video by calling the VLM NIM or the Long Video Summarization (LVS) microservice directly.
1489. `NVIDIA:video-search-and-summarization:video-understanding` [ml] OFFICIAL — Call the vss agent to run video understanding on video to answer a text question.
1490. `NVIDIA:video-search-and-summarization:vios` [ml][api] OFFICIAL — Query VIOS REST APIs: sensor list, recording timelines, video clip extraction, snapshot capture, add/delete sensors and streams
1491. `google:cloud:agent-platform-skill-registry` [infra] OFFICIAL — Interact with the Gemini Enterprise Agent Platform Skill Registry to create and search for available skills.
1492. `google:cloud:alloydb-basics` [data][infra] OFFICIAL — Manages clusters, instances, and backups for AlloyDB for PostgreSQL, and integrates with AlloyDB model context protocol (MCP) tools for auto
1493. `google:cloud:bigquery-basics` [ml][ai][data][infra] OFFICIAL — Manages datasets, tables, and jobs in BigQuery, and integrates with BigQuery ML and Gemini for advanced data analytics and AI-driven insight
1494. `google:cloud:cloud-run-basics` [infra] OFFICIAL — Manages Cloud Run services, jobs, and worker pools.
1495. `google:cloud:firebase-basics` [infra][mobile] OFFICIAL — Use this skill whenever you are working on a project that uses Firebase products or services, especially for mobile or web apps.
1496. `google:cloud:gemini-agents-api` [infra][backend] OFFICIAL — Manages custom Agent resources on Gemini Enterprise Agent Platform.
1497. `google:cloud:gemini-api` [ai][infra][backend] OFFICIAL — Guides the usage of the Gemini API on Agent Platform with the Google Gen AI SDK.
1498. `google:cloud:gemini-interactions-api` [infra][backend] OFFICIAL — Guides the usage of Gemini Interactions API on Gemini Enterprise Agent Platform.
1499. `google:cloud:gke-basics` [infra] OFFICIAL — Plan, create, and configure production-ready Google Kubernetes Engine (GKE) clusters using the golden path Autopilot configuration.
1500. `google:cloud:google-cloud-networking-observability` [infra][ops] OFFICIAL — Investigates Google Cloud networking issues by analyzing logs, metrics, and diagnostics.
1501. `google:cloud:google-cloud-recipe-auth` [infra][security] OFFICIAL — Provides expert guidance on authenticating and authorizing to Google Cloud services and APIs, covering human users, service identities, Appl
1502. `redhat:openshift-virtualization` [infra] OFFICIAL — Manage the full VM lifecycle on OpenShift Virtualization — create, clone, snapshot, restore, rebalance, and report — through a single conver
1503. `cypress-io:cypress-author` [test][frontend] OFFICIAL — Creates, updates, and fixes Cypress E2E and component tests.
1504. `cypress-io:cypress-explain` [test][frontend] OFFICIAL — Explains Cypress E2E and component tests, and answers questions about Cypress use and behavior.
1505. `cypress-io:cypress-docs` [test][docs] OFFICIAL — Search and extract Cypress information from official documentation.
1506. `qdrant:skills` [devops][perf][ops] VOLT-SK — Agent skills for Qdrant vector search, covering scaling, performance optimization, search quality, monitoring, deployment, model migration, 
1507. `BrianRWagner:ai-marketing-skills` [marketing][sales][ai] VOLT-SK — 17 marketing frameworks for cold outreach, homepage audit, social cards, and more
1508. `wshuyi:x-article-publisher-skill` [general] VOLT-SK — Publish articles to X/Twitter
1509. `CosmoBlk:email-marketing-bible` [marketing][ai][email] VOLT-SK — 55K-word email marketing guide as an AI skill
1510. `Xquik-dev:x-twitter-scraper` [general] VOLT-SK — Tweet search, profile tweets, follower export, media, posting, replies, MCP
1511. `Xquik-dev:tweetclaw` [general] VOLT-SK — Post tweets, replies, DMs; search, monitor, run giveaways
1512. `SHADOWPR0:beautiful_prose` [ai][legal] VOLT-SK — Hard-edged writing style contract for timeless, forceful English prose without AI tics
1513. `MohamedAbdallah-14:unslop` [ai] VOLT-SK — Removes named AI writing tells (tricolons, em-dash pileups, hedging stacks, sycophancy openers, stock vocab like "delve"/"crucial"). Split l
1514. `Eronred:aso-skills` [marketing][mobile][backend] VOLT-SK — 30+ App Store Optimization skills for keyword research, metadata optimization, competitor analysis, creative optimization, and mobile growth
1515. `degausai:wonda` [ai] VOLT-SK — AI content creation: images, video, music, audio, editing, publishing
1516. `gitroomhq:postiz-agent` [general] VOLT-SK — Schedule social media posts across 28+ platforms programmatically
1517. `indranilbanerjee:digital-marketing-pro` [seo][marketing][ai] VOLT-SK — 150-skill engagement methodology — 12-Part Strategy Flow, 25 specialist agents, EU AI Act Article 50 ready (C2PA signing), 6-platform AEO/GE
1518. `nowork-studio:NotFair` [seo][marketing] VOLT-SK — SEO, GEO, Google Ads, and Meta Ads skills with live data
1519. `PSPDFKit-labs:nutrient-agent-skill` [ai][backend] VOLT-SK — Document processing with Nutrient DWS API: convert (PDF/DOCX/XLSX/PPTX/HTML/images), extract text/tables, OCR (20+ languages), redact PII (p
1520. `notiondevs:Notion Skills for Claude` [ai] VOLT-SK — Skills for working with Notion
1521. `op7418:NanoBanana-PPT-Skills` [ai] VOLT-SK — AI-powered PPT generation with document analysis and styled images
1522. `gokapso:integrate-whatsapp` [backend] VOLT-SK — Connect WhatsApp, set up webhooks, and send messages
1523. `gokapso:automate-whatsapp` [backend] VOLT-SK — Build WhatsApp automations with workflows and agents
1524. `gokapso:observe-whatsapp` [backend][test] VOLT-SK — Debug WhatsApp delivery issues and run health checks
1525. `PleasePrompto:notebooklm-skill` [ai] VOLT-SK — Interact with NotebookLM for document-based conversations
1526. `obra:superpowers-lab` [ai] VOLT-SK — Lab environment for Claude superpowers
1527. `obra:writing-plans` [docs] VOLT-SK — Create strategic documentation
1528. `obra:executing-plans` [ai][meta] VOLT-SK — Implement and run strategic plans
1529. `obra:dispatching-parallel-agents` [ai][meta] VOLT-SK — Coordinate multiple simultaneous agents
1530. `obra:sharing-skills` [ai][meta] VOLT-SK — Distribute and communicate capabilities
1531. `obra:using-superpowers` [ai][meta] VOLT-SK — Leverage core platform capabilities
1532. `op7418:Youtube-clipper-skill` [general] VOLT-SK — YouTube clip generation and editing with automated workflows
1533. `ognjengt:founder-skills` [ai] VOLT-SK — Claude skills for founders with packaged startup workflows
1534. `EveryInc:charlie-cfo-skill` [general] VOLT-SK — Bootstrapped CFO financial management inspired by Charlie Munger
1535. `openaccountants:openaccountants` [general] VOLT-SK — 371 tax classification skills across 134 countries
1536. `wrsmith108:linear-claude-skill` [ai] VOLT-SK — Manage Linear issues, projects, and teams
1537. `hanfang:claude-memory-skill` [ai] VOLT-SK — Minimal, low-friction hierarchical memory system with background agents and filesystem-based persistence
1538. `kreuzberg-dev:kreuzberg` [mobile] VOLT-SK — Extract text, tables, and metadata from 62+ document formats
1539. `Paramchoudhary:ResumeSkills` [animation] VOLT-SK — 20 specialized skills for resume optimization, ATS analysis, interview prep, and career transitions
1540. `RoundTable02:tutor-skills` [general] VOLT-SK — Transform docs or codebases into Obsidian StudyVaults with interactive quizzes
1541. `NeoLabHQ:write-concisely` [docs] VOLT-SK — Applies the famous *The Elements of Style* book principles to make documentation and writing clearer and more professional by eliminating wo
1542. `ReScienceLab:opc-skills` [seo][ai] VOLT-SK — Agent skills for solopreneurs with SEO, geo, and LLM tools
1543. `SeanZoR:claude-speed-reader` [ai] VOLT-SK — Speed read Claude's responses at 600+ WPM using RSVP with Spritz-style ORP highlighting
1544. `Digidai:product-manager-skills` [product][pm] VOLT-SK — Senior PM agent with 30+ frameworks and SaaS metrics
1545. `deusyu:translate-book` [general] VOLT-SK — Translate books (PDF/DOCX/EPUB) via parallel sub-agents with resume
1546. `mvanhorn:last30days-skill` [general] VOLT-SK — Research any topic across Reddit, X, YouTube, HN, Polymarket, and the web, ranked by upvotes, likes, and real money instead of editors
1547. `santifer:career-ops` [ml][ai] VOLT-SK — 14-skill collection for AI-powered job search: JD evaluation with A-F scoring, ATS-optimized PDF generation, portal scanners (Greenhouse/Ash
1548. `pattern-ai-labs:agentcall` [ai] VOLT-SK — Let your AI agents join Google Meet, Zoom, Teams calls and collaborate like a real team-mate.
1549. `robzolkos:skill-rails-upgrade` [general] VOLT-SK — Analyze Rails apps and provide upgrade assessments
1550. `antonbabenko:terraform-skill` [infra][devops][test] VOLT-SK — Terraform and OpenTofu patterns: testing, modules, state, CI/CD.
1551. `zxkane:aws-skills` [infra] VOLT-SK — AWS development with infrastructure automation and cloud architecture patterns
1552. `Rootly-AI-Labs:rootly-incident-responder` [ml][ai][ops][backend] VOLT-SK — AI-powered incident response with ML similarity matching, solution suggestions, and on-call coordination. Requires [Rootly MCP Server](https
1553. `conorluddy:ios-simulator-skill` [mobile] VOLT-SK — Control iOS Simulator
1554. `ramzesenok:iOS-Accessibility-Audit-Skill` [mobile][a11y] VOLT-SK — Audit iOS App against Accessibility norms
1555. `truongduy2611:app-store-preflight-skills` [sales][mobile] VOLT-SK — Scan iOS/macOS projects to catch common mistakes that lead to App Store rejection before submission
1556. `coderabbitai:skills` [quality] VOLT-SK — Code review and PR autofix workflows for coding agents
1557. `sanjay3290:postgres` [data] VOLT-SK — Execute safe read-only SQL queries against PostgreSQL databases
1558. `jthack:ffuf-claude-skill` [ai][security] VOLT-SK — Web fuzzing with ffuf
1559. `lackeyjb:playwright-skill` [test] VOLT-SK — Browser automation with Playwright
1560. `ibelick:ui-skills` [general] VOLT-SK — Opinionated, evolving constraints to guide agents when building interfaces
1561. `ehmo:platform-design-skills` [a11y] VOLT-SK — 300+ design rules from Apple HIG, Material Design 3, and WCAG 2.2 for cross-platform apps
1562. `obra:test-driven-development` [test] VOLT-SK — Write tests before implementing code
1563. `obra:subagent-driven-development` [ai][meta] VOLT-SK — Development using multiple sub-agents
1564. `obra:systematic-debugging` [ai][meta][test] VOLT-SK — Methodical problem-solving in code
1565. `obra:root-cause-tracing` [ai][meta] VOLT-SK — Investigate and identify fundamental problems
1566. `obra:testing-skills-with-subagents` [test] VOLT-SK — Collaborative testing approaches
1567. `obra:testing-anti-patterns` [test] VOLT-SK — Identify ineffective testing practices
1568. `obra:finishing-a-development-branch` [ai][meta][git] VOLT-SK — Complete Git code branches
1569. `obra:requesting-code-review` [ai][meta][quality] VOLT-SK — Initiate code review processes
1570. `obra:receiving-code-review` [ai][meta][quality] VOLT-SK — Process and incorporate code feedback
1571. `obra:using-git-worktrees` [ai][meta][git] VOLT-SK — Manage multiple Git working trees
1572. `obra:verification-before-completion` [ai][meta] VOLT-SK — Validate work before finalizing
1573. `obra:condition-based-waiting` [ai][meta] VOLT-SK — Manage conditional pauses or delays
1574. `obra:commands` [ai][meta] VOLT-SK — Create and manage command structures
1575. `obra:writing-skills` [ai][meta] VOLT-SK — Develop and document capabilities
1576. `fvadicamo:dev-agent-skills` [quality][git] VOLT-SK — Git and GitHub workflow skills for commits, PRs, and code reviews
1577. `omkamal:pypict-skill` [test] VOLT-SK — Pairwise test generation
1578. `massimodeluisa:recursive-decomposition-skill` [general] VOLT-SK — Handle long-context tasks (100+ files, 50k+ tokens) through recursive decomposition strategies based on RLM research
1579. `rameerez:claude-code-startup-skills` [ai] VOLT-SK — Skills for building and running software startups, apps, and SaaS
1580. `zscole:model-hierarchy-skill` [general] VOLT-SK — Cost-optimized model routing based on task complexity
1581. `CloudAI-X:threejs-skills` [3d] VOLT-SK — Three.js skills for creating 3D elements and interactive experiences
1582. `Leonxlnx:taste-skill` [animation][design][ai][frontend] VOLT-SK — High-agency frontend skill that gives AI good taste with tunable design variance, motion intensity, and visual density to stop generic UI sl
1583. `NeoLabHQ:reflexion` [ai] VOLT-SK — Self-refinement loop that forces the LLM to reflect on previous output and correct itself.
1584. `NeoLabHQ:sdd` [ai] VOLT-SK — Spec-driven development workflow that transforms prompts into production-ready implementations through structured planning, architecture des
1585. `NeoLabHQ:ddd` [ai][arch] VOLT-SK — Domain-driven development skills that also include Clean Architecture, SOLID principles, and design patterns.
1586. `NeoLabHQ:sadd` [ai][quality] VOLT-SK — Dispatches independent subagents for individual tasks with code review checkpoints between iterations for rapid, controlled development.
1587. `NeoLabHQ:kaizen` [ai] VOLT-SK — Applies continuous improvement methodology with multiple analytical approaches, based on Japanese Kaizen philosophy and Lean methodology.
1588. `hamelsmu:eval-audit` [ai][devops] VOLT-SK — Audit LLM eval pipelines and surface problems
1589. `hamelsmu:error-analysis` [ai][devops] VOLT-SK — Systematically identify failure modes in LLM pipelines
1590. `hamelsmu:write-judge-prompt` [ml][ai] VOLT-SK — Design LLM-as-Judge evaluators for subjective criteria
1591. `hamelsmu:validate-evaluator` [ml][ai] VOLT-SK — Calibrate LLM judges against human labels
1592. `hamelsmu:evaluate-rag` [ml] VOLT-SK — Evaluate RAG retrieval and generation quality
1593. `uucz:moyu` [general] VOLT-SK — Anti-over-engineering skill with 5 variants and 10 platforms
1594. `hamelsmu:build-review-interface` [ai] VOLT-SK — Build annotation interfaces for reviewing LLM traces
1595. `mattpocock:skills` [quality][arch][git][devops] VOLT-SK — 17 dev workflow skills: PRD writing, TDD, codebase architecture, git guardrails, issue triage, refactoring plans, and more
1596. `wrsmith108:varlock-claude-skill` [ai][security] VOLT-SK — Secure environment variable management ensuring secrets are never exposed in Claude sessions, terminals, logs, or git commits
1597. `Skill_Seekers` [ai][docs] VOLT-SK — Automatically convert documentation websites, GitHub repositories, and PDFs into Claude AI skills in minutes
1598. `NoizAI:skills` [infra] VOLT-SK — Human-like TTS workflows with local/cloud APIs and app delivery
1599. `Kevin7Qi:codex-collab` [ai] VOLT-SK — Collaborate with Codex from Claude Code
1600. `ethos-link:rails-conventions` [general] VOLT-SK — Rails 8 conventions for consistent production code changes
1601. `mcollina:skills` [security][docs] VOLT-SK — 11 skills by Matteo Collina: Node.js, Fastify, TypeScript, OAuth, Git/GitHub, ESLint neostandard, documentation (Diataxis), Node.js core int
1602. `hqhq1025:skill-optimizer` [ai] VOLT-SK — Diagnose and optimize Agent Skills (SKILL.md) with real session data and research-backed static analysis. Works with Claude Code, Codex, and
1603. `LambdaTest:agent-skills` [ai][test] VOLT-SK — TestMu AI (Formerly LambdaTest) Skills is a curated collection of Agent Skills that teach AI coding assistants how to write production-grade
1604. `metalbear-co:skills` [infra][test] VOLT-SK — Skills that let agents code and test against your Kubernetes cluster using mirrord
1605. `dembrandt:dembrandt-skills` [design][a11y] VOLT-SK — UX and design system skills: hierarchy, typography, accessibility, interactions
1606. `GanyuanRan:Aegis` [ai] VOLT-SK — Evidence-driven method pack for AI coding agents
1607. `baskduf:codex-fable5` [general] VOLT-SK — Evidence-based workflow gates for Codex
1608. `muratcankoylan:context-fundamentals` [ai][meta] VOLT-SK — Understand what context is, why it matters, and the anatomy of context in agent systems
1609. `muratcankoylan:context-degradation` [ai][meta][devops] VOLT-SK — Recognize patterns of context failure: lost-in-middle, poisoning, distraction, and clash
1610. `muratcankoylan:context-compression` [ml] VOLT-SK — Design and evaluate compression strategies for long-running sessions
1611. `muratcankoylan:context-optimization` [ai][meta] VOLT-SK — Apply compaction, masking, and caching strategies
1612. `muratcankoylan:memory-systems` [ai][meta][arch] VOLT-SK — Design short-term, long-term, and graph-based memory architectures
1613. `muratcankoylan:tool-design` [ai][meta][arch] VOLT-SK — Build tools that agents can use effectively, including architectural reduction patterns
1614. `muratcankoylan:evaluation` [ml] VOLT-SK — Build evaluation frameworks for agent systems
1615. `k-kolomeitsev:data-structure-protocol` [ai] VOLT-SK — Graph-based long-term memory skill for AI (LLM) coding agents — faster context, fewer tokens, safer refactors
1616. `awrshift:claude-memory-kit` [ai] VOLT-SK — Persistent memory with hooks, wiki, and daily synthesis for multi-project workflows
1617. `transloadit:skills` [general] VOLT-SK — Transloadit skill collection (6)
1618. `honeydew-ai:honeydew-ai-coding-agents-plugins` [ai] VOLT-SK — 11 skills for the Honeydew semantic layer over Snowflake, Databricks, and BigQuery: model exploration, entity/relation/attribute/metric/cont
1619. `raintree-technology:apple-hig-skills` [mobile][frontend] VOLT-SK — Apple Human Interface Guidelines as 14 agent skills covering platforms, foundations, components, patterns, inputs, and technologies for iOS,
1620. `K-Dense-AI:claude-scientific-skills` [ai] VOLT-SK — Scientific research and analysis skills
1621. `NotMyself:claude-win11-speckit-update-skill` [ai] VOLT-SK — Windows 11 system management
1622. `jeffersonwarrior:claudisms` [general] VOLT-SK — SMS messaging integration
1623. `SHADOWPR0:security-bluebook-builder` [security] VOLT-SK — Build security Blue Books for sensitive apps
1624. `obra:defense-in-depth` [security] VOLT-SK — Multi-layered security approaches
1625. `huifer:Claude-Ally-Health` [ai] VOLT-SK — A health assistant skill for medical information analysis, symptom tracking, and wellness guidance.
1626. `frmoretto:clarity-gate` [ml] VOLT-SK — Epistemic quality verification for RAG systems
1627. `wanshuiyin:Auto-claude-code-research-in-sleep` [ml][ai][devops] VOLT-SK — Autonomous ML research with cross-model review loops and GPU deployment
1628. `zechenzhangAGI:AI-research-SKILLs` [ml][ai] VOLT-SK — 77 AI research skills for model training, inference, and MLOps
1629. `Orchestra-Research:AI-research-SKILLs` [ml][ai] VOLT-SK — 20-module AI research skill library for model architecture, training, and ML paper writing
1630. `komal-SkyNET:claude-skill-homeassistant` [ai] VOLT-SK — Supercharge and manage Home Assistant workflows
1631. `hanhuark:mechanical-engineering-research-skill` [general] VOLT-SK — Thermal-fluid research writing, proposals, DOE, and presentation feedback
1632. `prompt-security:clawsec` [ai][security] VOLT-SK — Security skill suite with drift detection, automated audits, and skill integrity verification
1633. `BehiSecc:vibesec` [data] VOLT-SK — Helps write secure code by preventing common vulnerabilities including IDOR, XSS, SQL injection, SSRF, and weak authentication, approaching 
1634. `lawvable:awesome-legal-skills` [legal] VOLT-SK — Curated agent skills for automating legal workflows
1635. `peas:genealogy-research` [general] VOLT-SK — Genealogy research agent with OCR, FamilySearch, YAML data, and human-in-the-loop
1636. `materials-simulation-skills` [meta] VOLT-SK — Agent skills for computational materials science: numerical stability, time-stepping, linear solvers, mesh generation, simulation validation
1637. `Ericyoung-183:alpha-insights` [ai] VOLT-SK — Harness-enforced business research for Claude Code and Codex
1638. `takechanman1228:claude-ecom` [ai] VOLT-SK — Ecommerce CSV to business review with KPI decomposition
1639. `aklofas:kicad-happy` [ai] VOLT-SK — AI-powered KiCad electronics design review and analysis
1640. `bitwize-music-studio:claude-ai-music-skills` [ai] VOLT-SK — Full-lifecycle AI music album production
1641. `czlonkowski:n8n-code-javascript` [devops][backend] VOLT-SK — JavaScript in n8n Code nodes with data access patterns
1642. `czlonkowski:n8n-code-python` [devops][backend] VOLT-SK — Python coding in n8n Code nodes with limitations
1643. `czlonkowski:n8n-expression-syntax` [devops][backend] VOLT-SK — n8n expression syntax with {{}} and $json/$node variables
1644. `czlonkowski:n8n-mcp-tools-expert` [devops][backend] VOLT-SK — MCP tools guide with tool selection and node formats
1645. `czlonkowski:n8n-node-configuration` [ai] VOLT-SK — Node configuration with dependency rules and AI connections
1646. `czlonkowski:n8n-validation-expert` [devops][backend] VOLT-SK — Fix n8n validation errors with error catalog
1647. `czlonkowski:n8n-workflow-patterns` [ai][data] VOLT-SK — Workflow patterns for webhook, HTTP, database, and AI tasks
1648. `3d-accessibility-fallbacks` [3d][a11y] SREDNOFF
1649. `3d-asset-pipeline-agent` [3d][devops] SREDNOFF
1650. `3d-experience-brief-intake` [3d] SREDNOFF
1651. `3d-interaction-gesture-design` [3d] SREDNOFF
1652. `3d-lighting-camera-composition` [3d] SREDNOFF
1653. `3d-performance-budget-gate` [3d][perf] SREDNOFF
1654. `3d-product-configurator` [3d] SREDNOFF
1655. `3d-visual-screenshot-validator` [3d][design] SREDNOFF
1656. `accessibility-remediation-sprint` [a11y] SREDNOFF
1657. `accessibility-specialist-agent` [a11y] SREDNOFF
1658. `accessibility-wcag-aa` [a11y] SREDNOFF
1659. `admin-crud-ux-patterns` [design] SREDNOFF
1660. `ads-landing-page-message-match` [marketing] SREDNOFF
1661. `ads-reporting-roas-dashboard` [marketing] SREDNOFF
1662. `agent-browser-automation-qa` [test] SREDNOFF
1663. `agent-instruction-migration` [devops] SREDNOFF
1664. `agents-sdk-production-workflow` [ai] SREDNOFF
1665. `ai-evals-regression-suite` [ai] SREDNOFF
1666. `ai-search-geo-audit` [seo][ai] SREDNOFF
1667. `analytics-engineer-agent` [data] SREDNOFF
1668. `android-jetpack-compose-builder` [mobile] SREDNOFF
1669. `android-reviewer-agent` [mobile] SREDNOFF
1670. `animation-motion-polish` [animation] SREDNOFF
1671. `animation-scroll-performance` [animation][perf] SREDNOFF
1672. `anti-ai-slop-design-critic` [ai] SREDNOFF
1673. `api-contract-test-generator` [test][legal][backend] SREDNOFF
1674. `api-interface-design` [backend] SREDNOFF
1675. `api-platform-agent` [backend] SREDNOFF
1676. `app-analytics-crash-reporting` [data] SREDNOFF
1677. `app-ci-cd-release-automation` [devops] SREDNOFF
1678. `app-store-aso-metadata` [mobile] SREDNOFF
1679. `app-store-release-agent` [devops] SREDNOFF
1680. `app-store-testflight-release` [devops][mobile] SREDNOFF
1681. `astro-islands-seo` [seo][frontend] SREDNOFF
1682. `attribution-incrementality-review` [marketing] SREDNOFF
1683. `auth-oauth-session-architecture` [security] SREDNOFF
1684. `backend-engineer-agent` [backend] SREDNOFF
1685. `background-jobs-queues` [backend] SREDNOFF
1686. `billing-entitlements-state-machine` [finance][payments] SREDNOFF
1687. `brand-theme-factory` [design] SREDNOFF
1688. `browser-devtools-qa` [test] SREDNOFF
1689. `cache-invalidation-design` [perf] SREDNOFF
1690. `canonical-redirect-audit` [seo] SREDNOFF
1691. `checkout-trust-risk-ux` [payments] SREDNOFF
1692. `ci-cd-automation` [devops] SREDNOFF
1693. `ci-failure-triage` [devops] SREDNOFF
1694. `clasp-local-dev-deploy` [devops] SREDNOFF
1695. `cloud-infrastructure-agent` [infra] SREDNOFF
1696. `cms-editorial-layouts` [design] SREDNOFF
1697. `code-copy-provenance-review` [marketing] SREDNOFF
1698. `code-simplification` [quality] SREDNOFF
1699. `codebase-archaeologist-agent` [general] SREDNOFF
1700. `coding-agent-evals-harness` [general] SREDNOFF
1701. `competitor-serp-gap-analysis` [seo] SREDNOFF
1702. `component-librarian-agent` [frontend] SREDNOFF
1703. `component-provenance-license-review` [frontend] SREDNOFF
1704. `component-storybook-workshop` [test][frontend] SREDNOFF
1705. `content-brief-keyword-map` [general] SREDNOFF
1706. `content-decay-pruning` [general] SREDNOFF
1707. `content-design-microcopy` [marketing] SREDNOFF
1708. `content-strategist-agent` [general] SREDNOFF
1709. `context-engineering` [general] SREDNOFF
1710. `conversion-rate-optimizer-agent` [marketing] SREDNOFF
1711. `conversion-tracking-gtm-ga4` [marketing] SREDNOFF
1712. `copy-adapt-component-pipeline` [marketing][devops][frontend] SREDNOFF
1713. `core-web-vitals-frontend` [frontend] SREDNOFF
1714. `crawler-analyst-agent` [seo] SREDNOFF
1715. `creative-landing-page-builder` [general] SREDNOFF
1716. `cross-language-test-gate` [test] SREDNOFF
1717. `cross-platform-design-parity` [general] SREDNOFF
1718. `crypto-market-research` [general] SREDNOFF
1719. `customer-support-ops-agent` [ops] SREDNOFF
1720. `dark-mode-theme-system` [design] SREDNOFF
1721. `dashboard-ux-information-density` [general] SREDNOFF
1722. `data-engineer-agent` [general] SREDNOFF
1723. `data-import-export-pipeline` [devops] SREDNOFF
1724. `data-table-grid-ux` [general] SREDNOFF
1725. `data-visualization-agent` [design] SREDNOFF
1726. `database-engineer-agent` [data] SREDNOFF
1727. `database-schema-migration-auditor` [seo][data] SREDNOFF
1728. `debugging-error-recovery` [test] SREDNOFF
1729. `defi-protocol-analysis` [trading] SREDNOFF
1730. `dependency-license-risk-audit` [general] SREDNOFF
1731. `dependency-minimalism-gate` [general] SREDNOFF
1732. `dependency-upgrade-agent` [general] SREDNOFF
1733. `deprecation-migration` [devops] SREDNOFF
1734. `design-brief-autogenerator` [general] SREDNOFF
1735. `design-brief-intake-router` [general] SREDNOFF
1736. `design-qa-agent-v2` [test] SREDNOFF
1737. `design-qa-scorecard` [test] SREDNOFF
1738. `design-system-component-qa` [frontend] SREDNOFF
1739. `design-system-lead-agent` [sales] SREDNOFF
1740. `design-token-compiler` [design] SREDNOFF
1741. `design-token-extraction` [design] SREDNOFF
1742. `devops-platform-agent` [devops] SREDNOFF
1743. `docs-developer-portal-seo` [seo] SREDNOFF
1744. `docs-information-architect-agent` [arch] SREDNOFF
1745. `documentation-adrs` [docs] SREDNOFF
1746. `ecommerce-faceted-navigation-seo` [seo] SREDNOFF
1747. `ecommerce-product-page-ux` [product] SREDNOFF
1748. `education-ai-guardrails` [ai] SREDNOFF
1749. `email-deliverability-transactional` [email] SREDNOFF
1750. `empty-state-error-recovery-design` [general] SREDNOFF
1751. `entity-knowledge-graph-seo` [seo] SREDNOFF
1752. `exchange-api-ccxt-integration` [trading][backend] SREDNOFF
1753. `experiment-analyst-agent` [general] SREDNOFF
1754. `expo-eas-release-gate` [devops][mobile] SREDNOFF
1755. `feature-flag-rollout` [general] SREDNOFF
1756. `figma-to-code-implementation` [design] SREDNOFF
1757. `file-upload-storage-pipeline` [devops] SREDNOFF
1758. `finance-billing-agent` [finance][payments] SREDNOFF
1759. `firebase-app-backend` [backend] SREDNOFF
1760. `firebase-auth-security-rules` [security] SREDNOFF
1761. `firebase-google-cloud-agent` [infra] SREDNOFF
1762. `floating-ui-overlay-positioning` [general] SREDNOFF
1763. `forms-checkout-ux` [payments] SREDNOFF
1764. `frontend-design-critic-agent` [frontend] SREDNOFF
1765. `frontend-design-system` [frontend] SREDNOFF
1766. `frontend-implementation-agent` [frontend] SREDNOFF
1767. `frontend-ui-engineering` [frontend] SREDNOFF
1768. `fullstack-integrator-agent` [general] SREDNOFF
1769. `fuzzing-security-tests` [security][test] SREDNOFF
1770. `geo-ai-search-readiness-v2` [seo][ai] SREDNOFF
1771. `git-workflow-versioning` [git] SREDNOFF
1772. `gltf-asset-pipeline` [3d][devops] SREDNOFF
1773. `gltf-optimization-pipeline-v2` [3d][devops] SREDNOFF
1774. `google-ads-account-audit` [marketing] SREDNOFF
1775. `google-workspace-addons` [general] SREDNOFF
1776. `google-workspace-apps-script` [general] SREDNOFF
1777. `growth-design-message-match` [marketing] SREDNOFF
1778. `growth-engineer-agent` [marketing] SREDNOFF
1779. `growth-experiment-backlog` [marketing] SREDNOFF
1780. `headless-component-composition` [frontend] SREDNOFF
1781. `healthcare-ai-research-guardrails` [ai] SREDNOFF
1782. `heuristic-usability-review` [general] SREDNOFF
1783. `hiring-ai-fairness-review` [ai] SREDNOFF
1784. `iconography-illustration-system` [design] SREDNOFF
1785. `image-video-seo` [seo] SREDNOFF
1786. `in-app-purchases-subscriptions` [general] SREDNOFF
1787. `interaction-state-matrix` [general] SREDNOFF
1788. `internal-linking-ia` [general] SREDNOFF
1789. `international-hreflang-seo` [seo] SREDNOFF
1790. `internationalized-rtl-ui` [general] SREDNOFF
1791. `ios-reviewer-agent` [mobile] SREDNOFF
1792. `ios-swiftui-app-builder` [mobile] SREDNOFF
1793. `issue-to-pr-agent` [general] SREDNOFF
1794. `javascript-seo-rendering` [seo] SREDNOFF
1795. `keyword-query-negative-mining` [general] SREDNOFF
1796. `landing-page-conversion-design` [marketing] SREDNOFF
1797. `language-runtime-router` [general] SREDNOFF
1798. `language-specialist-agent` [general] SREDNOFF
1799. `legal-risk-reviewer-agent` [legal] SREDNOFF
1800. `llms-txt-ai-crawler-access` [seo][ai] SREDNOFF
1801. `local-seo-entity-pages` [seo] SREDNOFF
1802. `localization-i18n-engineering` [general] SREDNOFF
1803. `localization-lead-agent` [sales] SREDNOFF
1804. `log-file-crawl-analysis` [seo] SREDNOFF
1805. `mcp-integration-builder` [general] SREDNOFF
1806. `mcp-security-review` [security] SREDNOFF
1807. `meta-ads-creative-testing` [marketing][test] SREDNOFF
1808. `migration-lead-agent` [sales] SREDNOFF
1809. `ml-ai-engineer-agent` [ml][ai] SREDNOFF
1810. `mobile-app-permissions-privacy` [mobile][legal] SREDNOFF
1811. `mobile-architect-agent` [mobile] SREDNOFF
1812. `mobile-asset-budget-audit` [mobile] SREDNOFF
1813. `mobile-crash-analytics-gate` [data][mobile] SREDNOFF
1814. `mobile-e2e-device-testing` [test][mobile] SREDNOFF
1815. `mobile-first-qa` [mobile] SREDNOFF
1816. `mobile-offline-first-review` [mobile] SREDNOFF
1817. `mobile-performance-agent` [mobile][perf] SREDNOFF
1818. `mobile-permissions-privacy-gate` [mobile][legal] SREDNOFF
1819. `mobile-release-reviewer-agent` [devops][mobile] SREDNOFF
1820. `mobile-ux-platform-parity` [mobile] SREDNOFF
1821. `monorepo-boundary-architecture` [arch] SREDNOFF
1822. `motion-design-agent` [animation] SREDNOFF
1823. `motion-design-system` [animation] SREDNOFF
1824. `multi-brand-whitelabel-ui` [design] SREDNOFF
1825. `multi-tenant-saas-architecture` [arch] SREDNOFF
1826. `multilingual-content-localization-seo` [seo] SREDNOFF
1827. `mutation-testing-strategy` [test] SREDNOFF
1828. `navigation-ia-ux` [general] SREDNOFF
1829. `nextjs-app-router-seo` [seo][frontend] SREDNOFF
1830. `nextjs-production-app-architecture` [frontend] SREDNOFF
1831. `no-code-low-code-agent` [general] SREDNOFF
1832. `node-package-release-engineering` [devops] SREDNOFF
1833. `nuxt-seo-module-workflow` [seo][frontend] SREDNOFF
1834. `observability-instrumentation` [ops] SREDNOFF
1835. `onboarding-product-tour-ux` [product] SREDNOFF
1836. `onchain-data-analytics` [trading][data] SREDNOFF
1837. `operations-automation-agent` [ops] SREDNOFF
1838. `paid-search-risk-agent` [general] SREDNOFF
1839. `performance-max-structure` [perf] SREDNOFF
1840. `performance-optimization` [perf] SREDNOFF
1841. `performance-sre-agent` [perf][ops] SREDNOFF
1842. `playwright-screenshot-baselines` [test] SREDNOFF
1843. `portfolio-risk-rebalancing` [trading] SREDNOFF
1844. `ppc-budget-bid-optimizer` [marketing] SREDNOFF
1845. `ppc-landing-quality-score-gate` [marketing] SREDNOFF
1846. `ppc-policy-compliance-check` [marketing][legal] SREDNOFF
1847. `ppc-strategist-agent` [marketing] SREDNOFF
1848. `pr-review-response-agent` [general] SREDNOFF
1849. `premium-saas-ui-polish` [general] SREDNOFF
1850. `pricing-onboarding-ux` [finance] SREDNOFF
1851. `privacy-compliance-agent` [legal] SREDNOFF
1852. `product-builder` [product] SREDNOFF
1853. `product-manager-agent` [product] SREDNOFF
1854. `programmatic-seo-pages` [seo] SREDNOFF
1855. `programming-agent-pack-selector` [general] SREDNOFF
1856. `prompt-injection-defense` [ai] SREDNOFF
1857. `prompt-security-agent` [ai][security] SREDNOFF
1858. `property-based-testing` [test] SREDNOFF
1859. `pwa-offline-installability` [general] SREDNOFF
1860. `qa-automation-agent` [test] SREDNOFF
1861. `quality-cost-skill-kernel` [quality] SREDNOFF
1862. `r3f-scene-pattern-library` [3d] SREDNOFF
1863. `rag-evaluation-agent` [ml] SREDNOFF
1864. `react-aria-advanced-interactions` [frontend] SREDNOFF
1865. `react-native-expo-app-builder` [mobile][frontend] SREDNOFF
1866. `react-three-fiber-components` [frontend] SREDNOFF
1867. `realtime-websockets-sse` [backend] SREDNOFF
1868. `record-replay-skill-miner` [general] SREDNOFF
1869. `refactoring-coach-agent` [quality] SREDNOFF
1870. `release-manager-agent` [devops] SREDNOFF
1871. `release-notes-changelog-automation` [devops][docs] SREDNOFF
1872. `requirements-analyst-agent` [general] SREDNOFF
1873. `responsive-layout-system` [general] SREDNOFF
1874. `robots-xrobots-meta-controls` [seo] SREDNOFF
1875. `scroll-driven-3d-storytelling` [3d][animation] SREDNOFF
1876. `search-console-api-automation` [backend] SREDNOFF
1877. `search-console-ga4-diagnostics` [general] SREDNOFF
1878. `search-content-editor-agent` [general] SREDNOFF
1879. `secrets-env-rotation` [security] SREDNOFF
1880. `security-hardening` [security] SREDNOFF
1881. `security-reviewer-agent` [security] SREDNOFF
1882. `seo-ab-testing-causal-review` [seo][test] SREDNOFF
1883. `seo-ci-quality-gate` [seo] SREDNOFF
1884. `seo-migration-redirects` [seo] SREDNOFF
1885. `seo-technical-auditor-agent` [seo] SREDNOFF
1886. `serp-feature-rich-result-planner` [seo] SREDNOFF
1887. `serp-to-page-brief-generator` [seo] SREDNOFF
1888. `shader-and-postprocessing-review` [3d] SREDNOFF
1889. `shader-material-design` [3d] SREDNOFF
1890. `site-crawler-automation` [seo] SREDNOFF
1891. `smart-contract-security-review` [security][legal] SREDNOFF
1892. `solidity-foundry-test-suite` [trading][test] SREDNOFF
1893. `source-driven-development` [general] SREDNOFF
1894. `source-first-api-verifier` [backend] SREDNOFF
1895. `source-ranking-roi-selector` [general] SREDNOFF
1896. `spec-driven-development` [general] SREDNOFF
1897. `sql-query-plan-optimizer` [data] SREDNOFF
1898. `sre-incident-commander-agent` [ops] SREDNOFF
1899. `staff-debugger-agent` [test] SREDNOFF
1900. `storybook-interaction-tests` [test] SREDNOFF
1901. `structured-data-schema-org` [seo] SREDNOFF
1902. `supply-chain-sbom-sca` [security] SREDNOFF
1903. `swiftui-state-data-flow` [mobile] SREDNOFF
1904. `technical-seo-audit` [seo] SREDNOFF
1905. `technical-writer-agent` [docs] SREDNOFF
1906. `test-architect-agent` [test] SREDNOFF
1907. `test-driven-development` [test] SREDNOFF
1908. `three-vs-babylon-vs-model-viewer` [3d] SREDNOFF
1909. `threejs-scene-architecture` [3d] SREDNOFF
1910. `tokenomics-whitepaper-review` [trading] SREDNOFF
1911. `topical-authority-cluster-builder` [general] SREDNOFF
1912. `trading-risk-analyst-agent` [trading] SREDNOFF
1913. `trading-strategy-backtesting` [trading] SREDNOFF
1914. `trust-safety-content-moderation-ux` [general] SREDNOFF
1915. `turbo-mode-controller` [general] SREDNOFF
1916. `turbo-source-benchmark` [general] SREDNOFF
1917. `turbo-validation-gate` [general] SREDNOFF
1918. `typescript-strictness-migration` [devops] SREDNOFF
1919. `typography-readability-system` [design] SREDNOFF
1920. `ui-component-source-router` [frontend] SREDNOFF
1921. `ux-researcher-agent` [general] SREDNOFF
1922. `visual-hierarchy-layout-review` [design] SREDNOFF
1923. `visual-qa-agent` [design] SREDNOFF
1924. `visual-regression-design-gate` [design] SREDNOFF
1925. `wallet-transaction-flow` [trading] SREDNOFF
1926. `web-rendering-edge-ssr-seo` [seo] SREDNOFF
1927. `web3-crypto-security-agent` [trading][security] SREDNOFF
1928. `webapp-visual-regression` [design] SREDNOFF
1929. `webgl-performance-agent` [3d][perf] SREDNOFF
1930. `webgl-webgpu-performance` [3d][perf] SREDNOFF
1931. `xr-ar-web-experiences` [3d] SREDNOFF
1932. `gitops-workflow` [general] WSH
1933. `k8s-security-policies` [security] WSH
1934. `similarity-search-patterns` [general] WSH
1935. `temporal-python-testing` [test] WSH
1936. `projection-patterns` [general] WSH
1937. `debugging-strategies` [test] WSH
1938. `nft-standards` [general] WSH
1939. `web3-testing` [trading][test] WSH
1940. `multi-cloud-architecture` [infra] WSH
1941. `hybrid-cloud-networking` [infra] WSH
1942. `cost-optimization` [general] WSH
1943. `istio-traffic-management` [general] WSH
1944. `linkerd-patterns` [general] WSH
1945. `mtls-configuration` [general] WSH
1946. `service-mesh-observability` [ops] WSH
1947. `pci-compliance` [legal] WSH
1948. `billing-automation` [finance][payments] WSH
1949. `async-python-patterns` [general] WSH
1950. `python-testing-patterns` [test] WSH
1951. `python-packaging` [general] WSH
1952. `python-performance-optimization` [perf] WSH
1953. `uv-package-manager` [general] WSH
1954. `typescript-advanced-types` [general] WSH
1955. `nodejs-backend-patterns` [backend] WSH
1956. `javascript-testing-patterns` [test] WSH
1957. `modern-javascript-patterns` [general] WSH
1958. `security-requirement-extraction` [security] WSH
1959. `threat-mitigation-mapping` [general] WSH
1960. `data-storytelling` [animation] WSH
1961. `accessibility-compliance` [legal][a11y] WSH
1962. `gdpr-data-handling` [legal] WSH
1963. `postmortem-writing` [general] WSH
1964. `on-call-handoff-patterns` [ops] WSH
1965. `rust-async-patterns` [general] WSH
1966. `go-concurrency-patterns` [general] WSH
1967. `memory-safety-patterns` [general] WSH
1968. `context-driven-development` [general] WSH
1969. `track-management` [general] WSH
1970. `workflow-patterns` [general] WSH
1971. `task-coordination-strategies` [general] WSH
1972. `team-communication-protocols` [general] WSH
1973. `team-composition-patterns` [general] WSH
1974. `anti-reversing-techniques` [general] WSH
1975. `binary-analysis-patterns` [general] WSH
1976. `memory-forensics` [general] WSH
1977. `protocol-reverse-engineering` [general] WSH
1978. `startup-metrics-framework` [general] WSH
1979. `team-composition-analysis` [general] WSH
1980. `dotnet-backend-patterns` [backend] WSH
1981. `evaluation-methodology` [ml] WSH

## G3 (mass expansion, 45 records)

1982. `cloudflare:cloudflare` [ai][infra][security] OFFICIAL — Comprehensive Cloudflare platform skill covering Workers, Pages, storage, AI, networking, security, and IaC
1983. `trailofbits:audit-context-building` [security][arch] OFFICIAL — Deep architectural context via ultra-granular code analysis
1984. `realkimbarrett:full-funnel-campaign-orchestrator` [marketing] OFFICIAL — Coordinate all skills to build a complete ads + funnel campaign end-to-end
1985. `flutter:flutter-implementing-navigation-and-routing` [mobile] OFFICIAL — Handle routing, navigation, and deep linking
1986. `deanpeters:altitude-horizon-framework` [product][pm][devops] OFFICIAL — Navigate the PM→Director mindset shift covering scope, time horizons, and failure modes
1987. `deanpeters:company-research` [product][pm] OFFICIAL — Deep-dive competitor or company analysis
1988. `deanpeters:director-readiness-advisor` [animation] OFFICIAL — Coach the PM→Director transition across four key situations
1989. `deanpeters:vp-cpo-readiness-advisor` [animation] OFFICIAL — Coach the Director→VP/CPO transition including a CEO interview framework
1990. `phuryn:test-scenarios` [test] OFFICIAL — Create comprehensive test scenarios from user stories
1991. `garrytan:freeze` [product][meta][test] OFFICIAL — Edit Lock: restrict file edits to one directory while debugging
1992. `makenotion:research-documentation` [docs] OFFICIAL — Search Notion workspace, synthesize findings, and create comprehensive research reports
1993. `addyosmani:web-quality-audit` [seo][perf][a11y] OFFICIAL — Comprehensive quality review across performance, accessibility, SEO, and best practices categories
1994. `NVIDIA:Megatron-Bridge:perf-moe-dispatcher-selection` [ml] OFFICIAL — Choose the right MoE token dispatcher (`alltoall`, DeepEP, or HybridEP) for the hardware, EP degree, and optimization stage.
1995. `NVIDIA:NemoClaw:nemoclaw-maintainer-security-code-review` [ml][security] OFFICIAL — Performs a comprehensive security review of code changes in a GitHub PR or issue.
1996. `NVIDIA:NemoClaw:nemoclaw-user-reference` [ml] OFFICIAL — Describes the NemoClaw plugin and blueprint architecture and how they orchestrate the OpenClaw sandbox.
1997. `NVIDIA:deepstream:deepstream-dev` [backend] OFFICIAL — NVIDIA DeepStream SDK 9.0 development with Python pyservicemaker API.
1998. `NVIDIA:deepstream:deepstream-import-vision-model` [devops] OFFICIAL — > Use this skill to bring any vision model from HuggingFace or NVIDIA NGC into an NVIDIA DeepStream pipeline with end-to-end automation: ONN
1999. `redhat:sre-skillpack` [ops] OFFICIAL — Discover, remediate, and verify CVEs across your RHEL fleet — orchestrating Red Hat Lightspeed and Ansible Automation Platform through a sin
2000. `AgriciDaniel:claude-seo` [seo][ai] VOLT-SK — Universal SEO skill for comprehensive website analysis and optimization
2001. `smixs:creative-director-skill` [ml][ai] VOLT-SK — AI creative director with recursive self-assessment: 20+ methodologies (SIT, TRIZ, Bisociation, SCAMPER, Synectics), 3-axis evaluation calib
2002. `Shpigford:readme` [docs] VOLT-SK — Generate comprehensive project documentation
2003. `Charlie85270:Dorothy` [ai] VOLT-SK — Orchestrate multiple AI CLI agents with automations and MCP servers
2004. `sanjay3290:deep-research` [general] VOLT-SK — Autonomous multi-step research using Gemini Deep Research Agent
2005. `alinaqi:claude-bootstrap` [ai][security][test] VOLT-SK — Opinionated project initialization with security-first guardrails, spec-driven atomic todos, LLM testing patterns, and CLI tool orchestratio
2006. `NeoLabHQ:code-review` [security][test] VOLT-SK — Comprehensive PR code review using specialized agents: bug-hunter, security-auditor, code-quality-reviewer, contracts-reviewer, historical-c
2007. `mukul975:Anthropic-Cybersecurity-Skills` [ai][infra][security] VOLT-SK — 753 cybersecurity skills across 38 domains: cloud security, pentesting, red teaming, DFIR, malware analysis, threat intel, and more (MITRE A
2008. `ShunsukeHayashi:agent-skill-bus` [ai] VOLT-SK — Self-improving task orchestration for AI agent systems
2009. `Lum1104:understand-anything` [ai] VOLT-SK — Interactive codebase knowledge graphs via multi-agent LLM analysis
2010. `foryourhealth111-pixel:Vibe-Skills` [test] VOLT-SK — A skills governed plug-and-play harness for staged, test-driven skill orchestration
2011. `muratcankoylan:multi-agent-patterns` [ai][meta][arch] VOLT-SK — Master orchestrator, peer-to-peer, and hierarchical multi-agent architectures
2012. `helius-labs:helius-skills` [trading] VOLT-SK — Ship Solana apps end-to-end; transaction sending, asset queries, real-time streaming, token swaps, prediction markets, browser wallets, and 
2013. `3d-art-director-agent` [3d] SREDNOFF
2014. `brand-art-director-agent` [design] SREDNOFF
2015. `codex-subagent-orchestration` [meta] SREDNOFF
2016. `design-system-migration-plan` [devops] SREDNOFF
2017. `growth-design-director-agent` [marketing] SREDNOFF
2018. `principal-architect-agent` [arch] SREDNOFF
2019. `principal-code-reviewer-agent` [quality] SREDNOFF
2020. `push-notifications-deep-links` [email] SREDNOFF
2021. `seo-director-agent` [seo] SREDNOFF
2022. `skill-catalog-orchestrator` [meta] SREDNOFF
2023. `supervisor-orchestrator-agent` [meta] SREDNOFF
2024. `turbo-multi-agent-review` [general] SREDNOFF
2025. `ui-art-director-agent` [general] SREDNOFF
2026. `workflow-orchestration-patterns` [meta] WSH
