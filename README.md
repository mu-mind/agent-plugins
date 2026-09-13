# agent-plugins

dbarnett's personal Claude Code / Cursor plugin marketplace.

## Plugins

General-purpose:

- **[jj-vcs](plugins/jj-vcs/)** — want an agent to know Jujutsu (jj) version control:
  git-vs-jj mapping, workflow, selective squash/split, conflict resolution? Install this.
- **[test-standards](plugins/test-standards/)** — want an agent to stop overmocking and
  splitting one assertion into an expect-expect-expect chain? Install this.

The rest are personal/opinionated, tied to David's specific conventions (WIP-prefixed
change descriptions, his own shorthand vocabulary) — not a general recommendation unless
you also want to adopt those conventions:

- **[branch-workflow](plugins/branch-workflow/)** — want `agents-tool` (AGENTS.md setup +
  jj/git WIP scope-tracking) available as a plugin instead of a dotfiles script? Install this.
- **[antipatterns](plugins/antipatterns/)** — want an agent to recognize David's shorthand
  antipattern nicknames (SNAiTF, PPP, ...) without re-explaining them? Install this.

## Install

```
claude plugin marketplace add mu-mind/agent-plugins
claude plugin install <plugin-name>@mu-mind-agent-plugins
```

Cursor: same repo, reads `.cursor-plugin/marketplace.json` instead. See per-plugin READMEs/SKILL.md for details.

## Contributing

See `CONTRIBUTING.md`.
