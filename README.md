# git-fzf

A fuzzy finder for Git. Jump between worktrees, open directories, and manage
stale branches — without leaving the terminal.

Stop typing `git worktree list` and copying paths. `git fzf` gives you an
interactive browser with a header, colored columns, and keyboard shortcuts
for every common worktree action.

## Prerequisites

- [fzf](https://github.com/junegunn/fzf) — `brew install fzf`
- [gum](https://github.com/charmbracelet/gum) — `brew install gum`
- [git](https://git-scm.com) — `brew install git`
- [Bash](https://www.gnu.org/software/bash/) 4.4+ — `brew install bash` (macOS ships 3.x)

## Installation

```bash
git clone https://github.com/git-extensions/git-fzf.git ~/.git-fzf
chmod +x ~/.git-fzf/git-fzf ~/.git-fzf/scripts/*.sh
export PATH="$HOME/.git-fzf:$PATH"   # add to ~/.bashrc or ~/.zshrc
```

Git discovers any `git-*` binary on `PATH`, so once installed:

```bash
git fzf worktree
```

## Usage

```bash
git fzf [fzf-flags] <command>
git fzf --version
git fzf --help
```

Pass any fzf flags before the command — they are forwarded directly:

```bash
git fzf --tmux worktree             # open in a tmux popup
git fzf --tmux "80%,80%" worktree   # custom popup size
git fzf --height 50% worktree       # fixed height
```

## Worktrees

Browse all worktrees interactively. Selecting one and pressing **Enter**
prints the path to stdout — pipe it wherever you need it.

```bash
git fzf worktree
```

### Keybindings

| Key      | Action                                                        |
| -------- | ------------------------------------------------------------- |
| `ctrl-o` | Open worktree directory in file manager (`open` / `xdg-open`) |
| `ctrl-r` | Reload worktree list                                          |
| `alt-x`  | Remove selected worktree (`git worktree remove`)              |
| `alt-p`  | Prune stale worktrees (`git worktree prune`) + reload         |
| `alt-h`  | Toggle keyboard shortcut preview                              |
| `ESC`    | Exit                                                          |

## Recipes

**Jump into a worktree from anywhere**

Add `gw` to your shell config to `cd` directly into the selected worktree:

```bash
# ~/.bashrc or ~/.zshrc
gw() {
  local path
  path=$(git fzf worktree)
  [ -n "$path" ] && cd "$path"
}
```

**Open in a tmux popup, jump on select**

```bash
gw() {
  local path
  path=$(git fzf --tmux "80%,60%" worktree)
  [ -n "$path" ] && cd "$path"
}
```

**Remove a worktree without leaving the terminal**

Press `alt-x` on any row to run `git worktree remove` in place, then the
list reloads automatically. No path copying, no second terminal.

## Configuration

Override fzf options per command via environment variables:

| Variable                | Scope          | Description                            |
| ----------------------- | -------------- | -------------------------------------- |
| `GIT_FZF_FLAGS`         | All commands   | Set automatically from CLI fzf flags   |
| `GIT_FZF_WORKTREE_OPTS` | Worktree only  | Override any fzf option for worktrees  |

Precedence: **Defaults** < **`GIT_FZF_FLAGS`** < **`GIT_FZF_WORKTREE_OPTS`**

```bash
export GIT_FZF_WORKTREE_OPTS="--height 90%"
export GIT_FZF_WORKTREE_OPTS="--tmux 80%,80%"
```

## Development

A Nix dev shell provides all required tools (bash, git, fzf, gum, gawk, bats, shellcheck):

```bash
nix develop
```

Run tests:

```bash
bats tests/
```

Run shellcheck:

```bash
shellcheck -x --source-path=SCRIPTDIR git-fzf scripts/*.sh
```

Enable debug trace:

```bash
DEBUG=1 git fzf worktree
```

## See Also

- [gh-fzf](https://github.com/gh-extensions/gh-fzf) — Fuzzy finder for the GitHub CLI
- [gh-ai](https://github.com/gh-extensions/gh-ai) — AI-powered copilot for the GitHub CLI

## License

[MIT](LICENSE)

<!-- markdownlint-disable-file MD013 -->
