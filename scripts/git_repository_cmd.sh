#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_git_repo_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=./git_core.sh
source "$_git_repo_cmd_source_dir/git_core.sh"

# git_repository_cmd.sh - Git Repository commands for git-fzf
#
# Invoked as a subprocess by git_repository.sh. Provides repository
# data emission and fzf action dispatch (list, preview-help).

# _git_config_repo_path()
#
# Resolve the configured projects root directory.
#
# DESCRIPTION:
#   Returns the projects directory using the following precedence:
#     1. GIT_FZF_REPO_PATH environment variable
#     2. git config --global fzf.repoPath
#     3. ~/Projects (default)
#   Tilde in the value is expanded to $HOME.
#
# RETURNS:
#   Absolute path to the projects directory (no trailing slash).
#
_git_config_repo_path() {
	local dir="${GIT_FZF_REPO_PATH:-}"
	if [[ -z "$dir" ]]; then
		dir=$(git config --global fzf.repoPath 2>/dev/null || true)
	fi
	dir="${dir:-$HOME/Projects}"
	printf '%s' "${dir/#\~/$HOME}"
}

# _git_repo_cmd_list()
#
# Parse the projects directory and emit tab-separated rows.
#
# DESCRIPTION:
#   Uses fd to scan 3 levels deep under the resolved projects directory.
#   Emits one tab-separated line per repository:
#       PATH\tREPOSITORY
#   PATH is the absolute path. REPOSITORY is the path relative to the
#   projects directory (e.g., github.com/org/myrepo).
#   No colors, no header — pure data.
#
# RETURNS:
#   Tab-separated rows (no header), one per repository. Empty output if
#   no repositories found.
#
_git_repo_cmd_list() {
	local dir
	dir=$(_git_config_repo_path)

	local prefix="${dir%/}/"

	fd -t d --max-depth 3 --min-depth 3 . "$dir" 2>/dev/null | sed 's|/$||' | while IFS= read -r path; do
		printf '%s\t%s\n' "$path" "${path#"$prefix"}"
	done
}

# _git_repo_list_cmd()
#
# List git repositories with colored, formatted output.
#
# DESCRIPTION:
#   Calls _git_repo_cmd_list to get raw TSV data, then renders it as an
#   ANSI-colored table with a header suitable for fzf consumption.
#
# RETURNS:
#   Colored table with header + one row per repository.
#   Empty output (exit 0) when no repositories found.
#
_git_repo_list_cmd() {
	local raw
	raw=$(_git_repo_cmd_list)

	[[ -z "$raw" ]] && return 0

	printf '%s\n' "$raw" |
		awk -v headers="PATH,REPOSITORY" \
			-v styles="normal,bold" \
			-v max_widths="50,0" \
			-f "$_git_repo_cmd_source_dir/git_render.awk"
}

# _git_repo_preview_help()
#
# Display keyboard shortcuts for repo list
#
_git_repo_preview_help() {
	gum format <<'EOF'
| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open directory in file manager |
| **`ctrl-r`** | Reload list |
| **`alt-h`** | Toggle help |
| **`alt-t`** | New tmux window *(tmux only)* |
| **`alt-enter`** | New tmux session *(tmux only)* |
| **`ESC`** | Exit (no output) |
EOF
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
main() {
	local cmd="${1:-}"

	case "$cmd" in
	list)
		_git_repo_list_cmd
		;;
	preview-help)
		_git_repo_preview_help
		;;
	*)
		gum log --level error "unknown subcommand '$cmd'"
		exit 1
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
