#!/usr/bin/env bats

# git_core.bats — unit tests for scripts/git_core.sh

bats_require_minimum_version 1.5.0

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

setup() {
	# Create a temp git repo for is_repo / root tests
	TEST_REPO=$(mktemp -d)
	BARE_REPO=""
	git -C "$TEST_REPO" init -q
	git -C "$TEST_REPO" config user.email "test@test.com"
	git -C "$TEST_REPO" config user.name "Test"
	git -C "$TEST_REPO" commit --allow-empty -m "init"
	TEST_OUTSIDE=$(mktemp -d)
}

teardown() {
	rm -rf "$TEST_REPO" "$TEST_OUTSIDE"
	if [[ -n "${BARE_REPO:-}" ]]; then rm -rf "$BARE_REPO"; fi
}

# ---------------------------------------------------------------------------
# _git_is_repo
# ---------------------------------------------------------------------------

@test "_git_is_repo returns 0 inside a git repo" {
	cd "$TEST_REPO"
	source "$SCRIPTS_DIR/git_core.sh"
	run _git_is_repo
	[ "$status" -eq 0 ]
}

@test "_git_is_repo returns 0 inside a bare repo" {
	BARE_REPO=$(mktemp -d)
	rmdir "$BARE_REPO"
	git clone --bare "$TEST_REPO" "$BARE_REPO"
	cd "$BARE_REPO"
	source "$SCRIPTS_DIR/git_core.sh"
	run _git_is_repo
	[ "$status" -eq 0 ]
}

@test "_git_is_repo returns 1 outside a git repo" {
	cd "$TEST_OUTSIDE"
	source "$SCRIPTS_DIR/git_core.sh"
	run _git_is_repo
	[ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# _git_root
# ---------------------------------------------------------------------------

@test "_git_root returns repo root" {
	cd "$TEST_REPO"
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_root)
	# Expand ~ back to $HOME for comparison; resolve symlinks (macOS /var -> /private/var)
	expanded="${result/#\~/$HOME}"
	[ "$(realpath "$expanded")" = "$(realpath "$TEST_REPO")" ]
}

@test "_git_root returns empty string outside a git repo" {
	cd "$TEST_OUTSIDE"
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_root)
	[ -z "$result" ]
}

@test "_git_root returns non-empty string inside a bare repo" {
	BARE_REPO=$(mktemp -d)
	rmdir "$BARE_REPO"
	git clone --bare "$TEST_REPO" "$BARE_REPO"
	cd "$BARE_REPO"
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_root)
	[ -n "$result" ]
}

# ---------------------------------------------------------------------------
# _git_expand_path
# ---------------------------------------------------------------------------

@test "_git_expand_path expands leading ~ to HOME" {
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_expand_path "~/foo/bar")
	[ "$result" = "$HOME/foo/bar" ]
}

@test "_git_expand_path leaves absolute paths unchanged" {
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_expand_path "/tmp/foo")
	[ "$result" = "/tmp/foo" ]
}

@test "_git_expand_path does not expand ~ in the middle of a path" {
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_expand_path "/foo/~/bar")
	[ "$result" = "/foo/~/bar" ]
}

# ---------------------------------------------------------------------------
# git_core.sh open dispatch
# ---------------------------------------------------------------------------

@test "git_core.sh open without path exits 1" {
	run "$SCRIPTS_DIR/git_core.sh" open
	[ "$status" -eq 1 ]
}

@test "git_core.sh open without path prints error to stderr" {
	run --separate-stderr "$SCRIPTS_DIR/git_core.sh" open
	echo "$stderr" | grep -q "requires a path"
}

# ---------------------------------------------------------------------------
# _git_fzf_options
# ---------------------------------------------------------------------------

@test "_git_fzf_options sets _fzf_options array with defaults" {
	source "$SCRIPTS_DIR/git_core.sh"
	GIT_FZF_FLAGS=""
	_git_fzf_options
	# Should contain at least --ansi
	[[ " ${_fzf_options[*]} " == *"--ansi"* ]]
}

@test "_git_fzf_options appends GIT_FZF_FLAGS" {
	source "$SCRIPTS_DIR/git_core.sh"
	export GIT_FZF_FLAGS="--height 50%"
	_git_fzf_options
	[[ " ${_fzf_options[*]} " == *"--height"* ]]
}

@test "_git_fzf_options appends per-command GIT_FZF_WORKTREE_OPTS" {
	source "$SCRIPTS_DIR/git_core.sh"
	export GIT_FZF_FLAGS=""
	export GIT_FZF_WORKTREE_OPTS="--border rounded"
	_git_fzf_options "WORKTREE"
	[[ " ${_fzf_options[*]} " == *"--border"* ]]
}

@test "_git_fzf_options per-command opts override global flags ordering" {
	source "$SCRIPTS_DIR/git_core.sh"
	export GIT_FZF_FLAGS="--height 20%"
	export GIT_FZF_WORKTREE_OPTS="--height 80%"
	_git_fzf_options "WORKTREE"
	# Both appear; per-command last (higher precedence for fzf last-wins)
	local joined="${_fzf_options[*]}"
	[[ "$joined" == *"20%"*"80%"* ]]
}
