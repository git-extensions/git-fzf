# git-fzf

A fuzzy finder for Git. Jump between worktrees, open directories, and manage
stale branches — without leaving the terminal.

Stop typing `git worktree list` and copying paths. `git fzf` gives you an
interactive browser with a header, colored columns, and keyboard shortcuts
for every common worktree action.

## Prerequisites

- [Git](https://git-scm.com/) — `brew install git`
- [Bash](https://www.gnu.org/software/bash/) 4.4+ — `brew install bash` (macOS ships 3.x)
- [fzf](https://github.com/junegunn/fzf) — `brew install fzf`
- [Gum](https://github.com/charmbracelet/gum) — `brew install gum`

## Installation

### Nix (recommended)

Run directly without installing:

```bash
nix run github:git-extensions/git-fzf -- worktree
```

Or install into your profile:

```bash
nix profile install github:git-extensions/git-fzf
```

### Zsh Plugin

The plugin adds `git-fzf` to your `$PATH` so git discovers it as a custom command (`git fzf`).

> **Note:** Bash 4.4+ is still required. On macOS: `brew install bash`.

```zsh
zinit light git-extensions/git-fzf
```

### Manual

Symlink the `git-fzf` script onto your `$PATH` so git discovers it as a
custom command:

```bash
ln -s /path/to/git-extensions/git-fzf/git-fzf /usr/local/bin/git-fzf
```

Then use it as `git fzf <command>`.

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
prints the path to stdout.

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

## Configuration

Override fzf options per command via environment variables:

| Variable                | Scope          | Description                            |
| ----------------------- | -------------- | -------------------------------------- |
| `GIT_FZF_FLAGS`         | All commands   | Set automatically from CLI fzf flags   |
| `GIT_FZF_WORKTREE_OPTS` | Worktree only  | Override any fzf option for worktrees  |

Precedence: **Defaults** < **`GIT_FZF_FLAGS`** < **`GIT_FZF_WORKTREE_OPTS`**

The format is the same as `FZF_DEFAULT_OPTS`: space-separated fzf options, with shell quoting for values that contain spaces or special characters.

```bash
# Simple flags
export GIT_FZF_WORKTREE_OPTS="--height=90%"
export GIT_FZF_WORKTREE_OPTS="--tmux=80%,80%"

# Key bindings — quote the bind value
export GIT_FZF_WORKTREE_OPTS="--bind 'alt-O:execute(code {})'"

# Multiple options
export GIT_FZF_WORKTREE_OPTS="--height=90% --bind 'alt-O:execute(code {})'"
```

## Development

A Nix dev shell provides all required tools (bash, git, fzf, gum, bats, shellcheck):

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

- [git-ai](https://github.com/git-extensions/git-ai) — AI-powered commit messages for git

## License

[MIT](LICENSE)

<!-- markdownlint-disable-file MD013 -->
