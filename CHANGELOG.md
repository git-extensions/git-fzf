# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-06

### Added

- Initial release
- Interactive fuzzy finder for git worktrees (`git fzf worktree`)
- Keybindings: open, reload, remove, prune, add, log view, help toggle
- Shell integration helper `gw` for cd-to-worktree workflow
- `GIT_FZF_FLAGS` and `GIT_FZF_WORKTREE_OPTS` environment variable support
- Nix dev shell (`flake.nix`)
- Bats test suite
- GitHub Actions CI and release-please automation
