---
name: jj-vcs
description: >
  Jujutsu (jj) version control: what it is, how it differs from git, everyday commands,
  selective squash/split, and conflict resolution. Use when working in a repo with a
  `.jj/` directory, when asked to perform version control operations there, or when
  asked "what is jj" / "how do I do X in jj vs git".
---

# jj-vcs

## What is jj?

Jujutsu ([jj-vcs.dev](https://jj-vcs.dev/)) is a version control system with a friendlier
model than git, while remaining git-compatible (most jj repos are "colocated" with a real
`.git` directory underneath — `jj git push`/`jj git fetch` talk to normal git remotes).

Key differences from git:

- **Continuous snapshots.** The working copy is *always* a change (`@`) that auto-updates
  as you edit files — no `git add`, no staging area.
- **Changes, not commits.** You work with "changes" (stable change IDs, e.g. `kkmpptxz`)
  rather than commits (which are the underlying, transient git-facing identity). Change
  IDs persist across rebases/edits; commit IDs don't.
- **Editing is implicit.** There's no `git commit --amend` — you just edit files, and
  they're part of `@` (or whichever change you `jj edit`'d) automatically.
- **Bookmarks, not branches.** Like git branches, but they don't auto-advance — you move
  them explicitly (`jj bookmark set`).
- **First-class conflicts.** A conflicting rebase doesn't stop and block you — the
  conflict is recorded *inside* the change, and you can keep working or resolve it later.

## Git → jj command mapping

| git | jj |
| --- | --- |
| `git status` | `jj status` |
| `git add <path>` | nothing — already tracked automatically |
| `git commit -m "..."` | `jj describe -m "..."` (describes `@`), or `jj new -m "..."` to start the *next* change |
| `git commit --amend` | just edit files — `@` updates automatically |
| `git log` | `jj log` |
| `git diff` | `jj diff` |
| `git checkout <branch>` | `jj new <bookmark>` (new change on top) or `jj edit <change-id>` (edit that change directly) |
| `git branch <name>` | `jj bookmark create <name> -r @` |
| `git push` | `jj git push` |
| `git pull` / `git fetch` | `jj git fetch` |
| `git stash` | usually not needed — `jj new` to set the in-progress work aside as its own change, come back with `jj edit` |
| `git merge <branch>` | `jj new <rev1> <rev2>` (multi-parent change) |
| `git rebase -i` | usually not needed — jj auto-rebases descendants on any edit. Explicit: `jj rebase -d <dest>` |
| `git cherry-pick <rev>` | `jj duplicate <rev>` (copy) or `jj rebase -r <rev> -d <dest>` (move) |
| `git reset --hard` | `jj abandon` (current change) or `jj restore` (specific paths) |
| `git reflog` | `jj op log` (operation log — records every jj operation, not just commits) |

## Essential commands

```shell
jj status              # what's changed in @
jj show --stat         # @ summary with file stats
jj log                 # compact change graph
jj log --stat          # history with file stats
jj diff                # diff of @
jj new [-m "..."]      # start a new change on top of @ (stops editing the old one)
jj describe [-m "..."] # set/update @'s description
jj edit <change-id>    # make a specific change the one you're editing
jj prev / jj next      # move to parent / child change
jj bookmark create <name> -r @
jj bookmark set <name> -r @
jj bookmark list
jj git push [--bookmark <name>]
jj git fetch
jj undo                # undo the last jj operation
jj op log               # see all operations (recovery point for anything)
```

## Selective squash and split

Both `jj squash` and `jj split` accept explicit paths — you don't need the interactive
diff editor if you know what you want to move:

```shell
# Move just these paths from @ into its parent
jj squash <path> [<path>...]

# Move paths between two arbitrary changes
jj squash --from <rev> --into <rev> <path>...

# Split @: move the given paths out into a NEW child change, with the rest staying on @
jj split <path>... [-m "message for the split-out change"]
```

`jj split` (no paths, or with `-i`) opens an interactive diff editor for hunk-level
selection — genuinely interactive, no way around that. But `jj split <path>` with
explicit paths is fully non-interactive and works well for "these files are actually a
separate change" splits (this is exactly how the `agent-plugins` repo's own history was
cleaned up mid-session: `jj split hk.pkl -m "..."` pulled one file out into its own
change without touching an editor).

## Conflict resolution

Conflicts in jj are first-class: a change can *be* conflicted and you can still build on
top of it, describe it, or set it aside — nothing blocks until you're ready to resolve.

```shell
jj resolve --list         # start here: what's conflicted, without touching anything
jj status               # conflicted files are also listed here
jj log                  # conflicted changes are flagged
jj resolve               # interactively resolve the next conflicted file (opens a merge tool)
jj resolve --tool <tool>  # use a specific merge tool
```

If no merge tool is configured, jj writes conflict markers into the file. They only
share the outer `<<<<<<<`/`>>>>>>>` bracket syntax with git — there's no plain
`=======` divider. Each side after the first is rendered as a diff from the base
(`%%%%%%% diff from: ... \\\\\\\ to: ...` with `-`/`+` lines) except the last, which is
shown as plain content after a `+++++++ <side>` line; the block closes with
`>>>>>>> conflict K of M ends`. See the Limits section below for what a real block looks
like. Because conflicts live inside the change rather than blocking the working copy,
there's no rush — `jj new` on top, `jj edit`-ing away and back, even pushing (if policy
allows) all leave the conflict exactly as it was. Resolve whenever convenient.

### Resolution procedure

1. `jj resolve --list` — see what's actually conflicted before touching anything.
2. **Prefer rebuilding over hand-editing markers.** To favor one side with changes of
   your own: `jj edit <that side>` (or `jj new` off it), edit the file as plain text
   with *no markers at all*, then re-merge with `jj new <your-edited-rev> <other-side>`.
   jj recomputes the 3-way diff itself and only flags real remaining differences — this
   sidesteps marker editing (and its failure mode below) entirely.
3. If you need per-hunk control and step 2 doesn't fit, `jj resolve --tool :ours` /
   `:theirs` resolves a whole file toward one side — but only for 2-sided conflicts (see
   Limits).
4. If hand-editing markers directly (last resort): touch whole marker blocks only,
   never partially — see Gotcha below for why. Re-run `jj resolve --list` after each
   edit; it should shrink, never vanish all at once unless you really resolved
   everything.
5. Done once `jj resolve --list` reports nothing. There's no separate "mark resolved"
   command — once every marker block is gone from the file, the next snapshot (which
   almost any jj command triggers, including `jj status` itself, or the filesystem
   watcher if one's configured) re-parses the file, finds it matches a resolution, and
   the conflict clears on its own.

### Limits

- **2-sided only for `:ours`/`:theirs`.** A 3+-parent merge refuses outright:
  `"The conflict at "f.txt" has 3 sides. At most 2 sides are supported."` Fix: pairwise
  reduction — `jj new side1 side2 -m tmp`, resolve (now 2-sided), bookmark it,
  `jj new <resolved> side3 -m tmp2`, resolve again, repeat per remaining side. Fully
  associative; a trailing `jj rebase -s <old-descendant> -d <resolved-commit>` cleanly
  reparents descendants afterward.
- **Multi-hunk files are pre-segmented.** jj materializes disjoint conflicting regions
  as separate numbered blocks in one file, e.g. (2-sided, 2 hunks):
  ```
  <<<<<<< conflict 1 of 2
  %%%%%%% diff from: abc1234 "base"
  \\\\\\\        to: def5678 "sideA"
  -line2
  +AAA
  +++++++ ghi9012 "sideB"
  CCC
  >>>>>>> conflict 1 of 2 ends
  ```
  Resolve block 1 in isolation while leaving block 2's markers untouched —
  `jj resolve --list` still reports the file conflicted until every block is gone. Makes
  batch/regex-driven resolution of individual hunks viable.
- **No hunk-level split into separate changes.** `jj split <path>` is file-granular, not
  hunk-granular — it relocates a file's whole conflict state, it can't carve one hunk
  out into its own change. Hunk batching has to happen in-place within the file.

### Gotcha: a malformed marker edit silently "resolves" the file

jj has no sticky resolved/unresolved flag — it re-derives conflict state by re-parsing
marker text on *every* snapshot. Resolving some hunks while leaving other marker blocks
intact and well-formed still correctly reports conflicted. But break one block's
begin/end pairing (e.g. delete the closing `>>>>>>> conflict K of M ends` line) and jj's
parser just gives up recognizing it — the file is silently accepted as fully resolved
plain text, with the literal `<<<<<<<`/`%%%%%%%`/`+++++++` lines left behind as ordinary
tracked content, no warning at all. Not a jj bug — an incomplete hand-edit. This is
exactly why step 4 above says whole blocks only, never partial.

## Recovery

```shell
jj op log            # every operation, ever
jj undo              # undo the most recent operation
jj op restore <id>   # jump back to any prior operational state
```

Nothing is really lost — `jj op restore` recovers from almost any mistake, including
abandoned changes or bad rebases.

## Notes

- This skill covers jj mechanics only. For this repo family's `WIP:`-prefixed change
  description convention and when to run `agents-tool --task`, see the `branch-workflow`
  plugin instead — not duplicated here.
- Further reading: [jj-vcs.dev](https://jj-vcs.dev/) ·
  [tutorial](https://jj-vcs.dev/latest/tutorial/) ·
  [git comparison](https://jj-vcs.dev/latest/git-comparison/)
