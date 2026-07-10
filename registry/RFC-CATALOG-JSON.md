# RFC: machine-readable catalog export (CORE-300.json)

> RU сначала, English below. / Russian first, English mirror below.

---

## RU

### Мотивация

`CORE-300.md` — единственный источник каталога (2027 записей), и он отлично читается
человеком и грепается агентом. Но внешним инструментам (установщики скиллов, селекторы,
дашборды) приходится каждый раз заново реализовывать разбор markdown-формата. Первый
такой потребитель — фабрика агентов Zavod, которая строит SQLite-индекс каталога и
ставит скиллы по нему.

Предложение: markdown остаётся источником истины, рядом появляется **генерируемый**
`CORE-300.json` — той же природы, что PROFILE.lock (производный артефакт).

Связь с существующим `core-catalog-index.json` (кэш `routing-lib.ps1`, некоммитимый):
это внутренний mtime-кэш для роутеров с их полями (`num/group:int/line`). Новый
`CORE-300.json` — другой слой: **публичный контракт** для внешних потребителей
(коммитится, стабильная схема с `schema_version`, кроссплатформенная генерация).
Внутренний кэш можно со временем читать из того же JSON, но этот RFC его не трогает.

### Что добавляет этот PR

- `registry/gen-catalog-json.sh` — генератор `CORE-300.md → CORE-300.json`
  (bash 3.2+, из зависимостей только `jq`, который уже нужен хукам; вывод
  детерминированный — без таймстампов).
- `registry/gen-catalog-json.sh --check` — гейт для CI: падает, если JSON отстал от
  markdown (по аналогии с validate-catalog-format).
- `registry/gen-catalog-json.ps1` — PowerShell-порт (генерирует
  `CORE-300.windows.json`; `-Check` валидирует канонический JSON структурно —
  количество и id записей). Канонический артефакт генерирует bash-версия.
  Порт написан без локального прогона (нет pwsh) — прошу проверить на Windows.
- `registry/CORE-300.json` — сгенерированный экспорт (2027 записей).

### Формат записи

```json
{
  "id": 148,
  "name": "fastapi-developer",
  "tags": ["backend"],
  "source": "VOLT",
  "source_raw": "VOLT",
  "group": "G2",
  "description": null
}
```

Обёртка: `{schema_version: 1, source: "CORE-300.md", entries: [...], count: N}`.
`source` — код источника до `:` (для `GH:owner/repo` → `GH`), полная строка — в
`source_raw`. `group` выводится из ближайшего предыдущего заголовка `## G…` — каталог
рос дополнениями, секции G1/G2/G3 повторяются, а нумерация не монотонна по документу,
поэтому парсер трактует каждую строку записи независимо.

### Замеченный дрейф формата (не чинится этим PR)

У 5 записей отсутствует код источника — тегам сразу следует описание:
485, 493, 497, 498, 499 (`otel-tracing-setup` и соседние). В JSON у них
`source: null`. Возможно, стоит присвоить им источник (похоже на `SREDNOFF`/`LOCAL`)
— оставляю на решение автора.

**Найдено при внедрении (10.07.2026, тем же принципом «не чинить чужим PR»):** ещё 4
записи получают `group: null` — 501/502 (`accessibility-agents`/`playwright-skill`)
и 2027/2028 (`vibe-template-web`/`vibe-template-mobile`). Причина не в источнике, а в
том, что перед ними в документе стоит подзаголовок `## Анти-overlap для ...`, который
сбрасывает трекер группы в парсере (он реагирует на любой `## `, не только на
`## G...`). Те же 4 записи семантически принадлежат предыдущей G-секции — это
структурная особенность CORE-300.md (документ рос дополнениями), а не баг генератора.
Не чиню в рамках этого внедрения — тот же принцип, что и с 5 source-null записями.

### Найденный и исправленный баг (10.07.2026)

`gen-catalog-json.ps1` не парсился на реальном Windows PowerShell 5.1: строка 38
содержала буквальный em-dash (`—`) внутри `.IndexOf(" — ")`. Без BOM PS5.1 читает
`.ps1` как ANSI, и non-ASCII байт ломает токенизатор — тот же класс бага, что уже
ловился в этом репо на кириллице в комментариях (см. CHANGELOG v1.12). Исправлено
построением разделителя через `[char]0x2014` вместо
буквального символа, чтобы сам файл остался ASCII-only (правило репо для всех `.ps1`).
После фикса: 2027/2027 записей, `-Check` проходит против канонического
bash-сгенерированного `CORE-300.json`, счётчик непустых `description` совпадает
1432/1432 между bash- и PS-версией.

### Открытые вопросы — решение

1. **Коммитить `CORE-300.json` в репозиторий — да.** Та же логика, что у
   `PROFILE.lock.md`: производный артефакт, который потребителям не нужно
   регенерировать самим, коммитится рядом с источником.
2. **`--check` в CI и doctor — да, добавлено.** См. `.github/workflows/ci.yml`
   (job `registry-and-evals`) и `scripts/doctor.ps1`/`.sh` (новый чек «catalog JSON
   in sync»).
3. **`schema_version` bump-протокол — определён.** Bump `schema_version` только при
   удалении поля или изменении его типа/семантики. Добавление нового необязательного
   поля не требует bump (потребители обязаны игнорировать неизвестные поля). Записать
   это правило прямо в шапке `CORE-300.json` через отдельное поле не нужно — оно
   живёт здесь, в RFC, как канонической спецификации формата.

### Провенанс

Идея и первая реализация — внешний вклад через PR на публичный репозиторий:
[elysosss/srednoff-os-for-claude#1](https://github.com/srednoff888-art/srednoff-os-for-claude/pull/1)
(RU/EN, сгенерирован Claude Code). Внедрено через приватный source-of-truth пайплайн
(а не прямой git-merge PR, т.к. публичный репозиторий целиком генерируется скриптом
`build_public_release.py` из `~/.claude/templates/claude-md-os` + `~/.claude/registry`)
с исправлением описанного выше PS-бага и документацией 4 доп. `group: null` записей.

---

## EN

### Motivation

`CORE-300.md` is the single source of truth for the catalog (2027 entries) — great for
humans and for agent-side grep, but every external tool (skill installers, selectors,
dashboards) has to re-implement the markdown line grammar. The first such consumer is
the Zavod agent factory, which builds a SQLite index of the catalog and installs skills
from it.

Proposal: markdown stays canonical; a **generated** `CORE-300.json` lives next to it —
same nature as PROFILE.lock (derived artifact).

Relation to the existing `core-catalog-index.json` (the uncommitted `routing-lib.ps1`
cache): that one is an internal mtime cache for the routers with router-shaped fields
(`num/group:int/line`). The new `CORE-300.json` is a different layer: a **public
contract** for external consumers (committed, stable `schema_version`ed schema,
cross-platform generation). The internal cache could eventually read from this JSON,
but this RFC does not touch it.

### What this PR adds

- `registry/gen-catalog-json.sh` — `CORE-300.md → CORE-300.json` generator (bash 3.2+,
  the only dependency is `jq`, already required by the hooks; deterministic output, no
  timestamps).
- `registry/gen-catalog-json.sh --check` — CI gate: fails when the JSON is stale
  relative to the markdown (mirrors validate-catalog-format).
- `registry/gen-catalog-json.ps1` — PowerShell port (writes `CORE-300.windows.json`;
  `-Check` validates the canonical JSON structurally — record count and ids). The bash
  version produces the canonical artifact. The port was written without a local run
  (no pwsh here) — please verify on Windows.
- `registry/CORE-300.json` — the generated export (2027 records).

### Record format

See the JSON sample above. Wrapper: `{schema_version: 1, source: "CORE-300.md",
entries: [...], count: N}`. `source` is the source code up to `:` (`GH:owner/repo` →
`GH`), the full string is kept in `source_raw`. `group` derives from the nearest
preceding `## G…` header — the catalog grew via appendices, G-sections repeat and entry
numbering is not monotonic in document order, so the parser treats each record line
independently.

### Format drift noticed (not fixed by this PR)

5 records have no source code — tags are followed directly by the description:
485, 493, 497, 498, 499 (`otel-tracing-setup` and neighbors). They get `source: null`
in the JSON. They look like `SREDNOFF`/`LOCAL` entries — author's call.

### Open questions

1. Commit `CORE-300.json` to the repo (my suggestion — yes, so consumers can fetch the
   raw file without cloning) or generate it only in CI releases?
2. Wire `--check` into the existing CI workflow and `doctor`?
3. Does `schema_version` need a bump protocol for field-set changes?
