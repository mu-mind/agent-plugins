# jj-vcs

Jujutsu (jj) version control skill: what it is, git-vs-jj command mapping, everyday
workflow, selective squash/split, and conflict resolution. See
[`skills/jj-vcs/SKILL.md`](skills/jj-vcs/SKILL.md) for the actual skill content.

## Hook: working-copy lifecycle hints (Claude Code only)

`hooks/check-jj-working-copy.sh` is a `PreToolUse` hook on Edit/Write/NotebookEdit that
surfaces an advisory hint — never blocks — at two moments agents otherwise tend to miss
because jj's working copy is always `@` and auto-snapshots on every edit (no git-style
explicit commit to catch mistakes at):

- First edit this session into a change with no description set yet.
- The current change id drifting since this session last checked it (something ran
  `jj edit`/`jj new`/`jj undo` and the working copy isn't what it was).

Fails open silently if `jj`/`jq` aren't on `PATH` or the target path isn't inside a jj
repo. **Claude Code only, not yet ported to Cursor.** Cursor's `preToolUse` is allow/deny
only (no advisory-allow), but its `postToolUse` hook *does* support this via
`additional_context` — injects a message after the tool runs without blocking it. A
Cursor port is possible, it'd just fire after the edit instead of before; not built yet.
See root `CONTRIBUTING.md`'s "Writing hooks for both tools" note for the general pattern.

## Why build this instead of using an existing skill

jj already has a lot of Claude Code skills available. Surveyed before building:

- [HotThoughts/jj-skills](https://github.com/HotThoughts/jj-skills) — jj-workflow +
  jj-create-pr + jj-update-pr. Closest match in scope/quality, but: Claude-only (no
  `.cursor-plugin`), defaults to Conventional Commits (`feat:`/`fix:`) which conflicts
  with this family's `WIP:`-prefix convention (see `branch-workflow`), and its conflict
  handling is a single bullet point with no actual walkthrough.
- [antstanley/jj-workspace-skill](https://github.com/antstanley/jj-workspace-skill) —
  Claude-only, narrowly scoped to workspace management (git-worktree equivalent), not
  general workflow.
- Several marketplace listings (mcpmarket, LobeHub, claudemarketplaces, Skillselion) for
  "jujutsu"/"jj-workflow" skills — all Claude-only as far as could be determined; none
  independently verified as covering selective squash/split or conflict resolution in
  depth.

None had Cursor support, which was a hard requirement here. Rather than adopt one and
still need to build a Cursor-side equivalent plus patch the commit-convention mismatch,
built this from scratch, using this family's own `~/.agents/jj-howto.md` as the basis for
the basics section (so it stays aligned with existing conventions) and adding the
selective-squash/split and conflict-resolution sections as genuinely new content, since
none of the surveyed options covered those well.

## Possible future enhancements

Not started, just flagged so they're not lost:

- **Revset cookbook.** Common revset patterns (`trunk()..@`, `remote_bookmarks()..@`,
  finding a change by description substring, etc.) — came up naturally while building
  `branch-workflow`'s `agents-tool`, not yet captured here.
- **Workspace management.** jj's git-worktree equivalent (`jj workspace add/list/forget`)
  is mentioned in passing in the skill but could be its own deeper section or even a
  separate skill if it grows, similar to how antstanley scoped theirs.
- **jj-hp/hk integration specifics.** This repo's own `hk.pkl` + `jj-hp` pre-push setup
  (see root `AGENTS.md` "Testing changes in development") is a real, tested example of jj
  + hook-runner integration that could be worth documenting here as a pattern, not just
  living as repo-internal dev notes.
- **Revisit the survey periodically.** The jj-skill space is crowded and moving fast;
  worth re-checking every so often whether an external option has caught up enough to
  deprecate this in favor of adopting/depending on it instead.
