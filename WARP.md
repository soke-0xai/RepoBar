# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

RepoBar is a macOS menu bar app (SwiftUI + AppKit `NSMenu`) that surfaces GitHub repository status, activity, releases, and local Git state. The codebase is organized into:

- `Sources/RepoBarCore/`: Core domain module (GitHub API client, models, auth, local projects, settings, logging/utilities). This module is UI-agnostic and shared between the app and CLI.
- `Sources/RepoBar/`: App target (menu bar UI, app lifecycle, state container, window/controllers, settings UI, local repo menu integration).
- `Tests/RepoBarTests/`: Swift Testing suites covering core and app logic.
- `Scripts/`: Bash wrappers around SwiftPM and tooling (`swiftformat`, `swiftlint`, coverage, app packaging, CLI codesigning).
- `GraphQL/` and `docs/`: GitHub schema/operations and documentation (including CLI reference and release notes).

The build system is SwiftPM, but you should usually drive builds/tests via `pnpm` scripts at the repository root.

## Common commands

Run all commands from the repo root (`~/Projects/RepoBar`). Use the provided `pnpm` scripts instead of calling `swift build` / `swift test` directly unless there is a strong reason not to.

### Initial setup

- Install script dependencies (Node + pnpm):
  - `pnpm install`

### Formatting and linting

- Format Swift sources (via `swiftformat`):
  - `pnpm format`
  - Requires `swiftformat` to be installed (installable via Homebrew if missing).
- Lint Swift sources (via `swiftlint` and `.swiftlint.yml`):
  - `pnpm lint`
  - Requires `swiftlint` to be installed.
- Full pre-push check (format + lint + tests):
  - `pnpm check`

### Building and running the app

- Build the app (debug SwiftPM build):
  - `pnpm build`
- Build, package, codesign (if configured), and launch the debug app bundle:
  - First run or after code changes: `pnpm start`
  - Subsequent runs / quick relaunch after edits: `pnpm restart`
- Stop the running app from this checkout:
  - `pnpm stop`

Guardrail: Always launch via `pnpm start` / `pnpm restart` from `~/Projects/RepoBar`. If the visible menu bar app does not match the code in this checkout, confirm which binary is running:

- `pgrep -af "RepoBar.app/Contents/MacOS/RepoBar"`

### Tests and coverage

Tests use SwiftPM’s Swift Testing support.

- Run the full test suite (uses a shared SwiftPM cache under `~/Library/Caches/RepoBar/swiftpm`):
  - `pnpm test`
- Run tests with focused filters (SwiftPM `--filter`):
  - `pnpm test -- --filter <Pattern>`
  - Example pattern: `RepoBarTests/SomeTypeTests.test_behavior`.
- Run formatting, linting, and tests in one shot (recommended before PRs):
  - `pnpm check`
- Run tests with coverage analysis (isolated build directory under `.build/coverage`):
  - `pnpm check:coverage`
  - The coverage script respects environment variables like `COVERAGE_MIN`, `COVERAGE_INCLUDE_REGEX`, and `COVERAGE_EXCLUDE_REGEX` for thresholds and scoping. By default it focuses on `Sources/RepoBarCore` and excludes `Sources/RepoBarCore/API`.

### CLI and tooling

- Build, codesign (using `Scripts/codesign_cli.sh`), and run the bundled CLI (`repobarcli`):
  - `pnpm repobar`
- Build and run the CLI via the `repobar` script target:
  - `pnpm repobarcli`
- GraphQL code generation (only after GitHub schema access is configured):
  - `pnpm codegen`
  - Generated types should live under the `API/Generated` directory; do not hand-edit generated files.
- Developer docs helper:
  - `pnpm docs:list` (lists docs described by `Scripts/docs-list.mjs`).

### Typical local dev loop

1. Edit Swift sources under `Sources/RepoBar` and/or `Sources/RepoBarCore`.
2. Run `pnpm restart` to rebuild the app, package the debug bundle, and relaunch RepoBar from this checkout.
3. When changing core logic or adding features, run `pnpm test` (or `pnpm check`) and, when relevant, `pnpm check:coverage`.

## High-level architecture

### Modules and responsibilities

**RepoBarCore (`Sources/RepoBarCore/`)**

This module contains the core domain logic and is shared between the GUI app and CLI:

- **API/**
  - `GitHubClient`: Public actor that owns GitHub integration. It wraps `GitHubRestAPI`, `GraphQLClient`, `GitHubRequestRunner`, and `RepoDetailCoordinator` to expose high-level operations: fetching default/activity repositories, recent PRs/issues/releases/commits/discussions/tags/branches, contribution heatmaps, and search. It also provides rate-limit diagnostics and cache clearing.
  - `RepoDetailStore` + `RepoDetailCacheStore` and `RepoDetailCachePolicy`: Maintain per-repo, per-host caches for open pulls, CI, activity, traffic, heatmap, and release data with TTL-based freshness.
  - Supporting types (`GitHubModels`, `GitHubDecoding`, `GitHubErrors`, `GitHubPagination`, `GitHubRecentDecoders`, `GitHubReleasePicker`, `RateLimitSnapshot`, etc.) model GitHub API responses and pagination.
- **Auth/**
  - OAuth helpers (`OAuthLoginFlow`, `OAuthTokenRefresher`, `PKCE`, `TokenStore`, `LoopbackServer`) handle browser-based OAuth with PKCE, token refresh, and secure token persistence.
- **LocalProjects/**
  - `LocalProjectsService`, `LocalGitService`, `GitExecutable`, and `LocalRepoStatus` implement discovery of local Git repos under a configured root path, derive ahead/behind/dirty state, and provide sync targets for auto-fetch/pull.
- **Models/**
  - Repository model and extensions (`Repository`, `Repository+Activity`, `Repository+Factory`, `RepositoryStats`, `RepoContents`, `RepoRecentItems`, `ActivityEventType`, `ActivityMetadata`, `Installation`, `UserIdentity`) represent GitHub-side entities and computed activity/traffic summaries.
- **Settings/**
  - `UserSettings` is the main persisted settings struct (appearance, heatmap, repo list, local projects, menu customization, refresh interval, logging/diagnostics, GitHub host/Enterprise host, loopback port).
  - `MenuCustomization` and related types capture the configurable ordering, visibility, and grouping of blocks in the main menu.
- **Support/**
  - Cross-cutting utilities like `AuthDefaults` (default GitHub app parameters), `BackoffTracker`, `DiagnosticsLogger`, `ETagCache`, `RepoBarLogging`, `RepositoryFilter`, `RepositoryOnlyWith`, `RepositorySort`, `RepositoryPipeline`, `SettingsStore`, `RelativeFormatter`, `ReleaseFormatter`, `MarkdownBlockParser`, `ChangelogParser`, and path/formatting helpers.

**RepoBar app (`Sources/RepoBar/`)**

This target hosts the app’s UI, app lifecycle, and menu system built on top of `RepoBarCore`:

- **App/**
  - `AppState` (`@MainActor`, `@Observable`): Central state container that wires together core services (`GitHubClient`, `OAuthCoordinator`, `RefreshScheduler`, `SettingsStore`, `LocalRepoManager`) and a `Session` value. It:
    - Loads `UserSettings` via `SettingsStore` at startup, configures logging via `RepoBarLogging`, and initializes `DiagnosticsLogger`.
    - Configures token refresh: sets a token provider on `GitHubClient` that delegates to `OAuthCoordinator`, and runs a periodic background task to refresh tokens.
    - Owns `RefreshScheduler` for periodic background refreshes tied to the user’s `refreshInterval` setting and exposes helpers like `requestRefresh`, `refreshIfNeededForMenu`, and cache-clearing helpers.
    - Holds various `Task` handles for refresh, prefetching, local project scanning, and menu refresh debouncing.
  - `Session` (`@Observable`): Lightweight, mostly-value state describing the current UI state:
    - Authentication state (`AccountState`), stored-token presence, list of `Repository` models and `menuSnapshot` fallback, `menuDisplayIndex`, and whether repos are loaded.
    - Settings (`UserSettings`) and currently selected settings tab.
    - Rate-limit and last-error messages, global activity and commit feeds, contribution heatmap data and errors, and menu filter state (repo selection, recent-issue/PR filters).
    - Local projects state (`LocalRepoIndex`, discovery counts, access/scan status).
- **StatusBar/**
  - `StatusBarMenuManager`: `NSMenuDelegate` responsible for wiring an `NSStatusItem` to the app state.
    - Holds a `StatusBarMenuBuilder`, `MenuItemViewFactory`, `RecentMenuService`, and coordinator objects for recent lists (`RecentListMenuCoordinator`), local Git (`LocalGitMenuCoordinator`), per-repo changelog menus (`ChangelogMenuCoordinator`), and global activity (`ActivityMenuCoordinator`).
    - Handles menu lifecycle (`menuWillOpen`, `menuDidClose`), delegates submenu opening to the relevant coordinators, drives on-demand prefetching (e.g., changelog data, recent lists), and ensures menu view heights are recomputed when the menu window resizes.
    - Bridges menu actions back into higher-level behaviors (`refreshNow`, opening settings/about, Sparkle update checks, label-filter toggles, branch/worktree menus, path-opening via `RepoWebURLBuilder`, clone/checkout UI, and alert presentation).
    - Caches menu-structure signatures and widths to avoid unnecessary re-layouts.
  - `StatusBarMenuBuilder`: Constructs the main `NSMenu` and repo submenus from `Session` + `UserSettings`.
    - Computes a `MainMenuPlan` (repos and a `MenuBuildSignature`) using `RepositoryPipeline.apply` to filter/sort repositories based on scope (all/pinned/hidden), `RepositoryOnlyWith` filters, pinned/hidden sets, and the configured sort key.
    - Builds individual logical blocks (`MainMenuItemID` groups) such as the logged-out prompt, contribution header, rate-limit/error banners, filter rows, repo list cards, and footer (preferences/about/quit) according to `MenuCustomization` order and hidden flags.
    - Materializes blocks into `NSMenuItem` instances using SwiftUI views (`MenuLoggedOutView`, `ContributionHeaderView`, `MenuRepoFiltersView`, repo card views, banners, empty states), with layout governed by `MenuStyle` padding and a fixed minimum menu width.
    - Maintains caches for repo menu items and submenus and exposes helpers for remeasuring heights (`refreshMenuViewHeights`) and clearing highlights.
- **Support/**
  - `LocalRepoManager` (actor): Bridges app state (`Session.localRepoIndex`) to `RepoBarCore.LocalProjectsService`.
    - Manages security-scoped bookmarks for the local project root, caches discovery of repo roots and per-repo status snapshots with TTLs, and tracks last fetch times to decide when to auto-fetch.
    - Produces a `LocalRepoIndex` result used by the menu coordinators to render branch/worktree/sync state and notifies `LocalSyncNotifier` when syncs are attempted.
  - `RefreshScheduler`: Lightweight timer wrapper for periodic refresh; configured by `AppState` from `UserSettings.refreshInterval`.
  - Other helpers for menu appearance, repo URL construction, settings window opening, Sparkle integration, etc.
- **Views/** and **Settings/**
  - SwiftUI views for menu content (repo cards, activity rows, filters, heatmap, banners) and preferences windows (general, account, appearance, display/menu customization, advanced, debug).
  - These views generally bind directly to `Session` or simple view models built over `RepositoryDisplayModel` and other core types.

**CLI**

The `repobar` CLI target (built via `pnpm repobar`) is a SwiftPM product that depends on `RepoBarCore`. It reuses the same GitHub client, models, and settings primitives as the GUI to provide consistent JSON/plain-text views of repository data.

## Architectural guidance for agents

- Prefer extending **RepoBarCore** for new domain logic or GitHub/local-project behaviors, and keep **RepoBar** focused on UI composition, state wiring, and user interaction.
- When changing how repositories are selected, filtered, or ordered in the menu, look at `RepositoryPipeline`, `RepositoryFilter`, `RepositoryOnlyWith`, `RepositorySort`, and the `StatusBarMenuBuilder.orderedViewModels` pipeline.
- When modifying menu content or structure, update both the relevant **StatusBar** coordinators and any associated settings/customization code (e.g., Display/Appearance settings and `MenuCustomization`) so that the preferences UI stays in sync with actual menu behavior.
- Use `AppState` and `Session` as the primary integration points from UI into core services (`GitHubClient`, `LocalRepoManager`, `SettingsStore`). Avoid ad-hoc singletons in new code.
- Do not hand-edit generated GraphQL types under any `API/Generated` directory; instead, edit the source `.graphql`/schema inputs under `GraphQL/` and rerun `pnpm codegen`.
- When adding or modifying shared scripts, mirror changes in any companion `agent-scripts` infrastructure if referenced, and assume that multiple agents may be operating in this repo concurrently.
