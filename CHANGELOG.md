# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0](https://github.com/git-extensions/git-fzf/compare/v0.2.0...v0.3.0) (2026-03-08)


### Features

* add tmux integration for worktree navigation ([0f6783e](https://github.com/git-extensions/git-fzf/commit/0f6783edfa6dcd71dc4c2bdf27a4fc915fc0384f))


### Bug Fixes

* align tests and dispatch with post-refactor code ([286be2c](https://github.com/git-extensions/git-fzf/commit/286be2c7b48219ede0cc035d43370007e483462b))
* use execute-silent and +abort for tmux bindings in git_worktree.sh ([5882a85](https://github.com/git-extensions/git-fzf/commit/5882a85031f192e45071d5bdee11e6394f6a350f))
* **worktree:** abort fzf after tmux command execution ([9d8f09c](https://github.com/git-extensions/git-fzf/commit/9d8f09ca1540bad93175d4402f12c74e8fbb83e1))

## [0.2.0](https://github.com/git-extensions/git-fzf/compare/v0.1.0...v0.2.0) (2026-03-07)


### Features

* add nix package output and unify installation with git-ai ([874817e](https://github.com/git-extensions/git-fzf/commit/874817e5f8979e4c9100b1397d43966ea16d6d4c))
* add tmux integration for worktree navigation ([ce629ca](https://github.com/git-extensions/git-fzf/commit/ce629caf8e2bb3488ce69f818c822d2c72d3c01f))
* adopt awk-based color renderer, clean up keybindings and docs ([200add1](https://github.com/git-extensions/git-fzf/commit/200add1786a98e940a450d0f1661700b60ae0310))
* enter uses become to cd, matching fzf ALT-C behaviour ([012e35a](https://github.com/git-extensions/git-fzf/commit/012e35a0fd73fd8fb5721b762300462f0eb8be3c))
* **worktree:** add visual feedback to fzf bindings ([5f8cd3b](https://github.com/git-extensions/git-fzf/commit/5f8cd3b086b94d01036c6aa0b46467e92ad0944c))


### Bug Fixes

* address deep review findings ([e73c151](https://github.com/git-extensions/git-fzf/commit/e73c151b659c2c2901a8e94f7265696186cf6fd4))
* address deep review findings (round 3) ([9047713](https://github.com/git-extensions/git-fzf/commit/9047713e231823eaac2258750ea2aa3f50e5c538))
* address deep review findings (round 4) ([1a8cf7c](https://github.com/git-extensions/git-fzf/commit/1a8cf7ccd7bf5d30ee1afeb97d49b64c479c4cc0))
* address tech debt from deep code review ([31d5f74](https://github.com/git-extensions/git-fzf/commit/31d5f748ded59aab3c2000e430edef63be7d45bc))
* bare repo support, test leak, and doc accuracy ([eeafad1](https://github.com/git-extensions/git-fzf/commit/eeafad1049c97974f60ddcd80b0d8ae55b2f98c9))
* dead msg var, doc ordering, misleading docstring, stderr test precision ([1f01afe](https://github.com/git-extensions/git-fzf/commit/1f01afe2e11d9b83d63130645533dc599375fa44))
* defer dep check, bare repo footer, prune errors, truncate edge case ([af87082](https://github.com/git-extensions/git-fzf/commit/af87082613021af5665310f497b2bf521f05246e))
* expand ~/path in _git_open before passing to file manager ([744e9d7](https://github.com/git-extensions/git-fzf/commit/744e9d7cac5bcb9d5563bba67c2dac1075c37e49))
* expand ~/path in remove subcommand before passing to git ([0576542](https://github.com/git-extensions/git-fzf/commit/0576542be12006c4d73b215f1b81a5ff65903d89))
* forward worktree --help to git worktree list --help ([1cb9653](https://github.com/git-extensions/git-fzf/commit/1cb965388b61a68a4ddb473276f5036f52339bf0))
* guard open dispatch, restore footer bindings, and clean up local vars ([b45e72e](https://github.com/git-extensions/git-fzf/commit/b45e72e139144476c032e533e8ffbb63ed623b77))
* HOME boundary guard, stale docstring, and stale test assertions ([5408d42](https://github.com/git-extensions/git-fzf/commit/5408d426f638db9a1c2a55a97f833c0bb9e1f251))
* output absolute paths from git fzf worktree; add bare worktree test ([d80b4ee](https://github.com/git-extensions/git-fzf/commit/d80b4eebb08ed9740a8c471ba874d56668a93b95))
* paths with spaces, awk column widths, empty sha guard, test coverage ([ebafa28](https://github.com/git-extensions/git-fzf/commit/ebafa284c20b064eb3e75ca6a539305c1f6b11f8))
* remove gawk dependency, POSIX awk is sufficient ([0a1d9f5](https://github.com/git-extensions/git-fzf/commit/0a1d9f5f07e389c47bb49378d38fa72c1d8c4231))
* review findings — naming, error paths, docs, test cleanup ([35c3f80](https://github.com/git-extensions/git-fzf/commit/35c3f80615ae8f266562e62f3f5b4650787edd03))
* review findings — preview help ESC text, dead dispatch branch, docs, tests ([e078c4a](https://github.com/git-extensions/git-fzf/commit/e078c4a4ea8e88bf3e4f6298d6f18c50bfbf6840))
* sanitize tabs in commit subjects, skip dep check for no-args case ([91d4653](https://github.com/git-extensions/git-fzf/commit/91d4653093b866e8717ad99145fec887a0b31712))
* status colour check uses pre-truncation value in git_render.awk ([be44a68](https://github.com/git-extensions/git-fzf/commit/be44a68bb57c875361d8487e04d7731307316aab))
* **tests:** use list subcommand to avoid HOME substitution in CI ([02a2230](https://github.com/git-extensions/git-fzf/commit/02a2230a5f6c5ca4a400b7c8b183a89abb2077db))


### Reverts

* remove enter/become cd feature ([5e4e7b9](https://github.com/git-extensions/git-fzf/commit/5e4e7b9b12c0893cca9787735ebed79577d54823))

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
