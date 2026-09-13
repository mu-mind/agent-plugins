# AGENTS.md — agent-plugins

CRITICAL: If `AGENTS.local.md` is present in this repo, you MUST read it: @AGENTS.local.md
(It's gitignored/untracked — machine/session-specific notes. Not present yet? Fine, ignore this line.)

See README.md for what this repo is and how it's installed. See each plugin's
`skills/*/SKILL.md` for what that plugin does.

## Structure requirements

- Root needs both `.claude-plugin/marketplace.json` and `.cursor-plugin/marketplace.json`,
  listing the same plugins.
- Each plugin dir needs its own `.claude-plugin/plugin.json` and `.cursor-plugin/plugin.json`.
- Bundled scripts are referenced via `${CLAUDE_PLUGIN_ROOT}` on Claude — never hardcoded
  paths. Cursor has no equivalent root env var (verified against the official
  cursor/plugins spec repo, 2026-07-25); reference bundled scripts there by a path
  relative to the SKILL.md's own directory instead (see `cursor/plugins`' own
  `pstack/skills/show-me-your-work` for the precedent).
- Keep the root README.md to a one-line-per-plugin index; detailed usage belongs in each
  plugin's `skills/*/SKILL.md`, not duplicated at the top level.
- Each plugin gets its own `README.md` too (standard practice, matches `cursor/plugins`)
  for human-facing notes that don't belong in SKILL.md: alternatives surveyed, rationale,
  roadmap. SKILL.md is agent-facing and loaded into context on every trigger (see "Lean"
  below); README.md isn't loaded at all.

## Plugin quality standards

- **Lean.** A skill/plugin should carry exactly what's needed for the situations it
  targets, no more — bloated SKILL.md content and bundled scripts cost context on every
  session that loads them, whether or not that content is relevant right now. Prefer
  linking to a fuller doc over inlining it (see `antipatterns` SKILL.md's own "keep
  entries short, link don't restate" rule for an example).
- **Portable.** Don't assume Claude-specific mechanisms (skill-triggering behavior,
  `${CLAUDE_PLUGIN_ROOT}`, hooks, MCP config) work identically in Cursor, or vice versa.
  If a plugin does something tool-specific, say so explicitly and guard for it, rather
  than writing instructions that silently only work on one side.

See `CONTRIBUTING.md` for contributor-facing dev notes (e.g. writing hooks that work
across both Claude Code and Cursor).

## Testing changes in development

- `hk check` (and `jj-hp run` if using jj-hooks) validate lint/shellcheck/JSON/secrets
  before finalizing a change — cheap, run them often.
- Newly installed/updated/enabled/disabled plugins do **not** hot-reload into an
  already-running Claude Code session or into subagents spawned from it — they still see
  whatever skill list was loaded at session start. Testing organic skill-triggering (does
  a skill's description actually get picked up for the right prompts?) needs a genuinely
  fresh process: `claude -p "<prompt>"` in a new subprocess, not an in-session subagent.
  Confirmed the hard way: an in-session subagent test silently missed a skill entirely
  (zero tool calls) right after install; a fresh `claude -p` picked it up correctly.
- For fast local iteration without the remote-marketplace round-trip (push, wait, update,
  reinstall), register a second, distinctly-named marketplace pointing at your working
  tree (symlink a `plugins/` dir into it so relative `source` paths resolve) and toggle
  between it and the real one with `claude plugin enable`/`disable` — avoids the
  remove/re-add churn of switching a single marketplace's source back and forth.

## Security — before any push

This repo is public. Anything migrated in from private sources (dotfiles, other repos) MUST be
audited line-by-line for hardcoded paths/hostnames/usernames/emails/IPs, secrets/tokens (even
dummy/expired ones), and comments revealing internal infra. Flag findings explicitly before
deciding to strip vs. keep — never silently scrub-and-proceed.
