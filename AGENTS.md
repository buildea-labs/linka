# AGENTS.md - Codex-Only Operating Blueprint for linka SpeedTest PWA

> This file defines the execution model for Codex in this repository.
> Scope is only `linkaSpeedtestPwa/`.

---

## 1. Mission and Scope

You are working on the PWA **linka SpeedTest** (Vite, React, TypeScript, Cloudflare Pages).

Hard scope:
- Only edit inside `linkaSpeedtestPwa/`
- Do not mix Android implementation in the same task
- Do not create parallel logic or duplicate business rules

---

## 2. Codex-Only Mode

Single runtime model:
- Codex executes end-to-end
- "Agents" from `.claude/agents` are reference roles only, not runtime orchestration
- No dependency on multi-agent handoff to complete normal PWA work

Reference roles (non-runtime):
- Renan: PWA technical owner
- Marcelo: discovery and impact mapping mindset
- Gema: QA and release gate mindset
- Lia: UI/UX review mindset when needed

---

## 3. Required Skills by Task Type

Use `.claude/skills` as technical rule source.

### 3.1 Required for any PWA task
- `codebase-map`
- `pwa-platform-rules`
- `browser-limitations`
- `react-typescript-check`

### 3.2 Diagnostics / network changes
- `network-diagnostic-rules`
- `speedtest-flow`
- `diagnostic-engine` (when diagnostic rules/engine behavior changes)

### 3.3 UI/UX changes
- `material3-review`
- `accessibility-check`
- `ux-copy-review`

### 3.4 Release / deploy changes
- `regression-check`
- `qa-acceptance-check`
- `pwa-release-check`
- `cloudflare-pages-check`

---

## 4. Fixed Execution Flow (No Ambiguity)

For every implementation task:
1. Impact discovery (files, contracts, risk)
2. Browser limit validation (what is possible/impossible on web)
3. Contract and data validation (before UI)
4. Implementation (minimal change)
5. Tests and regression
6. Release/deploy gate checks

Priority order:
- Backend/data/contracts before UI
- Simplicity before sophistication

---

## 5. Hard Rules

- PWA-only scope by default
- No parallel/duplicate logic
- No fake feature unsupported by browser
- No deploy/commit/push without explicit user confirmation
- If behavior changes, update docs in the same task
- If a rule is not in code/docs, do not invent it; register as pending

---

## 6. Acceptance Criteria

Minimum acceptance for relevant tasks:
1. Critical flow works: `start -> running -> result -> history`
2. Diagnostic regression is coherent with documented contract/rules
3. Native-only capabilities are never exposed as active on pure web
4. Release gate completed when applicable:
   - `npm test`
   - `npm run build`
   - `npm run lint`
   - Cloudflare Pages checklist

If any check was not executed, report it explicitly.

---

## 7. Contracts and Documentation

- PWA canonical contracts live in local `docs/`
- Any behavior/flow/architecture decision change must update docs in the same task
- Android-PWA parity work is opt-in only by explicit user decision
- Default mode is PWA isolated execution

---

## 8. Command Safety

Allowed without extra confirmation:
- `git status`
- `git diff`
- `git log`
- `git fetch origin`
- `npm test`
- `npm run build`
- `npm run lint`

Require explicit confirmation:
- `git commit`
- `git push`
- `git push --force`
- `npm install` / `npm uninstall`
- `npx wrangler pages deploy`
- edits in `package.json`, `package-lock.json`, `vite.config.ts`, `tsconfig*.json`

---

## 9. Source Priority

If conflicts happen, use this order:
1. User message in session
2. `../CLAUDE.md` (workspace-level rules)
3. This `AGENTS.md` (Codex-only runtime rules)
4. `CLAUDE.md` in this PWA
5. `docs/DOCUMENTACAO_CONSOLIDADA.md`
6. Other local `docs/`

If still ambiguous, stop and ask.
