# Contributing

Maintainer/contributor-facing notes — not user docs, not agent instructions (see
`AGENTS.md` for those).

## Writing hooks for both tools

Claude Code and Cursor both have hook systems, but event names and output schemas don't
map 1:1 — check both sides before assuming a behavior ports over:

- Claude's `PreToolUse` supports advisory allow-with-message (`permissionDecision: allow`
  + `systemMessage`, never blocking). Cursor's `preToolUse` output is allow/deny only;
  `agent_message`/`user_message` there only surface on deny.
- Cursor's actual advisory-without-blocking equivalent lives on `postToolUse`, via its
  `additional_context` output field (injected into the conversation after the tool runs).
  So a Claude `PreToolUse` advisory hook ports to a Cursor `postToolUse` hook, not
  `preToolUse` — same intent, different event, fires after rather than before.
- Don't guess this from memory or plausible-sounding schema assumptions — verify against
  current docs (cursor.com/docs/hooks, docs.claude.com hooks reference) each time;
  they've been wrong before. Note the date checked, since both sides evolve.
- Worked example: `plugins/jj-vcs/hooks/check-jj-working-copy.sh` (Claude-only today,
  Cursor port identified but not built — see its header comment and
  `plugins/jj-vcs/README.md`).
