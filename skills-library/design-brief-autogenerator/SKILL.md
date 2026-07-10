---
name: design-brief-autogenerator
description: Generate a compact UI/UX, web design, 3D web design, landing page, dashboard, app screen, product viewer, configurator, or 3D asset brief before implementation. Use when Claude Code should ask only high-value design questions, infer safe assumptions, and avoid blocking on nonessential details.
---

# Design Brief Autogenerator

Use this skill to create the shortest useful design brief before UI or 3D implementation.

## Workflow

1. Run the brief generator:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\scripts\srednoff-os-design-brief.ps1" -ProjectPath "<project-path>" -Brief "<task>" -Json
```

2. Ask only the returned questions that materially change product/design decisions.
3. If questions are not blocking, continue with explicit assumptions.
4. Pair the result with source ranking before selecting external UI kits, component registries, design connectors, 3D libraries, or assets.
5. Validate final UI/3D work with screenshots, responsive checks, accessibility, performance, and asset budget where relevant.

## Checklist

- Target user and job-to-be-done are clear enough.
- Visual direction or safe default is declared.
- Source policy is clear: local components, approved registries, connectors, or ranked external sources.
- 3D experience type, asset availability, mobile fallback, and performance target are clear enough when 3D is involved.
- Assumptions are visible and easy for the user to correct.

## Guardrails

- Do not block progress with broad design questionnaires.
- Do not invent brand constraints when the project already has a design system.
- Do not choose external sources before checking source ranking, license, and project fit.
