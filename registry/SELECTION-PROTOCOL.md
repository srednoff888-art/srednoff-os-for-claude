# SELECTION-PROTOCOL — how to choose skills per project (without loading full context)

**Principle #1 — quality of the solution comes first; economy is only a tie-breaker.** Choose skills/agents/model by what the task needs for a quality result. If two paths give the SAME quality, take the cheaper/faster one. Never lower quality to save tokens. G1/G2/G3 = how much power the task actually needs, not "always pick cheap".

Goal: on every project (new or existing), attach **only what's relevant** from the core registry, without loading `CORE-300.md` in full (this is about saving CONTEXT, not about lowering solution quality).

## Algorithm (run by the agent at the start of work in a repo)

1. **Classify the project in one pass** — from files/manifests, without reading everything:
   - `package.json` + `next.config.*` → `[web][frontend]` (+ `[ai]` if `ai`/`@anthropic`/`openai` present)
   - `requirements.txt`/`pyproject.toml` → `[backend]`/`[data]`/`[ml]`
   - `*.tf`, `Dockerfile`, `k8s/` → `[infra][devops]`
   - trading/`ccxt`/`backtest` → `[trading]`
   - Amazon/FBA/listings → `[amazon][business][marketing]`
   - outreach/CRM/emails → `[sales][marketing]`
   - `*.ps1`, Windows target → `[windows]`
   - content/landing/SEO → `[seo][marketing][web]`
2. **Pick 1-4 dominant tags.** No more — it dilutes relevance.
3. **Assemble the set:**
   - **GROUP 1**: take everything matching the tags + universal meta skills (`github-research`, `production-review`, `context-manager`, `before-you-build`, OS commands). They're cheap/save tokens — take generously.
   - **GROUP 2**: take 3-7 records strictly on the dominant stack tags. Targeted.
   - **GROUP 3**: **don't attach up front**, but if the task genuinely needs G3-level quality (a full security audit, serious architecture, deep research, an ML pipeline, multi-agent work) — **use it, don't downgrade to save tokens**. Call it for an explicit task, warn about the cost. Only economize G1/G2 when they deliver the SAME quality.
4. **Apply the anti-overlap map** at the bottom of `CORE-300.md`: one canonical pick per capability.
5. **Don't load full descriptions into context.** `grep` by tag in `CORE-300.md`, take the names, activate them selectively. Record the choice in one line in your report/ExecPlan.

## Selection commands (grep by tag)

```powershell
Select-String -Path "$env:USERPROFILE\.claude\registry\CORE-300.md" -Pattern "\[web\]|\[ai\]" | Select-Object -First 40
```

```bash
grep -E "\[trading\]|\[ml\]" ~/.claude/registry/CORE-300.md
```

## Example profiles (illustrative — build your own per project)

| Project type | Dominant tags | GROUP 2 core (examples) | GROUP 3 on demand |
|---|---|---|---|
| Next.js SaaS / marketing site | `[web][frontend][seo][ai]` | nextjs-developer, ui-ux-pro-max, vercel:nextjs, seo-content-auditor | full SEO audit, code-review ultra, security-auditor |
| Trading/backtesting bot | `[trading][ml][backend][data]` | quant-analyst, risk-manager, backtesting-frameworks, python-pro, database-optimizer | reinforcement-learning-engineer, security-auditor, penetration-tester |
| E-commerce / Amazon FBA brand | `[amazon][business][marketing][seo]` | nexscope Amazon-Skills, merchant_amazon_* (DataForSEO), seo-keyword-strategist | amazon-seller-mcp (SP-API, real account — requires confirmation), market-sizing-analysis |
| Sales/outreach automation | `[sales][marketing][business]` | sales:draft-outreach, common-room:compose-outreach | nimble:company-deep-dive, zoominfo:tam-sizer |
| Design system / component library | `[web][design][frontend][3d][animation]` | ui-ux-pro-max, design-system-patterns, tailwind-design-system, figma:figma-use | core-3d-animation (bundle) |

A profile is a starting point, not a rule. Adjust based on the actual repository.

## When to update the registry
- A new frequently-used skill/agent shows up → add it as one line to the right group + check anti-overlap.
- A capability becomes natively available (`INST`) → drop the external duplicate.
