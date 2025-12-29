---
summary: "Local project folder sync: map local repos to GitHub cards, show branch/sync, and optional ff-only pulls."
read_when:
  - Updating local repo discovery/sync behavior
  - Changing settings UX for local project folder or terminal picker
  - Troubleshooting branch/sync display
---

# Local Repo Sync

## Goals
- Map local Git repositories to GitHub repos shown in RepoBar.
- Show current branch + sync status on repo cards and menu cards.
- Optional auto-sync: fast-forward pull clean repos only.
- Provide quick actions: open in Finder and open in preferred terminal.

## Settings
Location: Settings → Advanced → Local Projects.

- **Project folder**: Root directory to scan for repos. If not set, local status is hidden everywhere.
- **Auto-sync clean repos**: When enabled, RepoBar attempts `git pull --ff-only` for clean repos that are behind.
- **Preferred Terminal**: Terminal app used by “Open in Terminal” actions. Defaults to Ghostty if installed, otherwise Terminal.app.
- **Summary line**: Shows “Found X local repos · Y match GitHub data.” (or “No repositories found yet”).

## Discovery Rules
- Scan the selected project folder **two levels deep** (root + 2 subdirectory levels).
- Any directory containing a `.git` folder is treated as a repo.
- Hidden folders are skipped.

## Mapping Rules
- If remote `origin` URL resolves to `owner/name`, use exact full-name mapping.
- Fallback: if only one local repo name matches a GitHub repo name, map by name.
- If ambiguous (multiple same-name repos), do not map by name.

## Git Status
Collected per repo:
- Current branch: `git rev-parse --abbrev-ref HEAD` ("detached" for detached HEAD).
- Dirty/clean: `git status --porcelain`.
- Ahead/behind: `git rev-list --left-right --count @{u}...HEAD`.

Sync state labels:
- Up to date (ahead=0, behind=0)
- Behind (behind>0, ahead=0)
- Ahead (ahead>0, behind=0)
- Diverged (ahead>0, behind>0)
- Dirty (working tree not clean)
- No upstream (no tracking branch)

## Auto-Sync Behavior
- Only attempts sync when:
  - repo is clean
  - has upstream
  - behind > 0 and ahead == 0
  - branch is not detached
- Uses `git pull --ff-only`.
- **Notification**: Only on successful sync (no failure notifications).

## UI
- Repo cards show branch + sync icon when local repo is mapped.
- Menu card shows same line.
- Details menu includes:
  - Branch: <name>
  - Sync: <state>
- Actions:
  - Open in Finder
  - Open in Terminal (preferred terminal)

## Notes
- Local discovery runs during refresh and does not require GitHub auth.
- If the project folder is invalid or empty, local status is hidden.
- Notifications require standard macOS user permission; requested on first successful sync.
