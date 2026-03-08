#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_git_repo_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=./git_core.sh
source "$_git_repo_cmd_source_dir/git_core.sh"

# git_repo_cmd.sh - Git Repository commands for git-fzf
#
# Invoked as a subprocess by git_repo.sh. Provides repository
# data emission and fzf action dispatch (list, preview-help).

# _git_repo_projects_dir()
#
# Resolve the configured projects root directory.
#
# DESCRIPTION:
#   Returns the projects directory using the following precedence:
#     1. GIT_FZF_REPO_PATH environment variable
#     2. git config --global git-fzf.repoPath
#     3. ~/Projects (default)
#   Tilde in the value is expanded to $HOME.
#
# RETURNS:
#   Absolute path to the projects directory (no trailing slash).
#
_git_repo_projects_dir() {
	local dir="${GIT_FZF_REPO_PATH:-}"
	if [[ -z "$dir" ]]; then
		dir=$(git config --global fzf.repoDir 2>/dev/null || true)
	fi
	dir="${dir:-$HOME/Projects}"
	printf '%s' "${dir/#\~/$HOME}"
}

# _git_repo_cmd_list()
#
# List local git repositories under the configured projects directory.
#
# DESCRIPTION:
#   Uses fd to scan 3 levels deep under the resolved projects directory.
#   Emits one absolute path per line. No header, no colors — pure data.
#
# RETURNS:
#   One absolute path per line. Empty output if no repos found.
#
_git_repo_cmd_list() {
	local dir
	dir=$(_git_repo_projects_dir)
	fd -t d --max-depth 3 --min-depth 3 . "$dir" 2>/dev/null | sed 's|/$||'
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
		_git_repo_cmd_list
		;;
	projects-dir)
		_git_repo_projects_dir
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
