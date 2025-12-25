# Changelog

## Unreleased

### Added
- RepoBarCore shared module for GitHub API/auth/models used by the app and CLI.
- repobarcli bundled CLI with login/logout and repo listing (activity, issues, PRs, stars), JSON output, and limit flag.

### Changed
- OAuth/login helpers moved to RepoBarCore so app and CLI share the same keychain flow.
