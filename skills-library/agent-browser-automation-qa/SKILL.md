---
name: agent-browser-automation-qa
description: Use this skill when selecting or validating browser automation for agents, including Playwright MCP, browser-use style controllers, browser DevTools, screenshot baselines, visual QA, accessibility checks, web app smoke tests, and tool-driven web workflows.
---

# Agent Browser Automation QA

Choose the smallest browser automation harness that proves the user-facing behavior without hiding failures behind screenshots or model guesses.

## Harness Decision

1. Use existing project tests first: Playwright, Cypress, Storybook, unit tests, or app-specific smoke scripts.
2. Use Playwright MCP or browser DevTools when an agent needs to inspect live pages, DOM, console logs, network requests, or screenshots interactively.
3. Use browser-use style controllers only when the task is web navigation across uncontrolled sites and deterministic selectors are unavailable.
4. Use screenshot baselines for visual regressions, but pair them with DOM/state assertions for behavior.
5. Use manual reasoning only for static pages that do not require runtime interaction.

## Validation Loop

1. Start the app or open the target URL in an isolated profile when possible.
2. Confirm the page is nonblank and the intended route loaded.
3. Check console errors, failed network requests, auth redirects, and hydration warnings.
4. Exercise the primary workflow with stable selectors or accessible names.
5. Capture screenshot evidence only after behavior assertions pass.
6. Re-run the check after fixes and record exact commands, URLs, viewport, and remaining risk.

## Reliability Checklist

- Prefer semantic locators and accessible names over brittle CSS paths.
- Test desktop and mobile when layout or interaction can differ.
- Keep browser credentials, cookies, and tokens out of logs and screenshots.
- Avoid writing automation that purchases, sends emails, changes billing, deploys, trades, or mutates production data without explicit confirmation.
- Treat AI browser observations as hints until confirmed by DOM, network, trace, or app state.
- Stop and report when captcha, paywall, account lock, robots policy, or legal restriction blocks automation.

## Output

```md
Browser QA:
- Harness:
- URL / command:
- Assertions:
- Screenshot / trace:
- Issues found:
- Residual risk:
```
