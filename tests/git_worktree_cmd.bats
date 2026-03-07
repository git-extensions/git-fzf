#!/usr/bin/env bats

# git_worktree_cmd.bats — unit tests for scripts/git_worktree_cmd.sh

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"
CMD="$SCRIPTS_DIR/git_worktree_cmd.sh"

setup() {
	# Create a temp git repo with a commit so worktrees work
	TEST_REPO=$(mktemp -d)
	git -C "$TEST_REPO" init -q
	git -C "$TEST_REPO" config user.email "test@test.com"
	git -C "$TEST_REPO" config user.name "Test"
	git -C "$TEST_REPO" commit --allow-empty -m "Initial commit"

	# Create an extra worktree
	git -C "$TEST_REPO" worktree add "$TEST_REPO-wt" -b wt-branch
}

teardown() {
	rm -rf "$TEST_REPO" "$TEST_REPO-wt"
}

# ---------------------------------------------------------------------------
# _git_worktree_list_cmd (via direct execution)
# ---------------------------------------------------------------------------

@test "git_worktree_cmd.sh outputs a header line" {
	cd "$TEST_REPO"
	run "$CMD"
	[ "$status" -eq 0 ]
	# First line should be the header
	echo "${lines[0]}" | grep -qi "PATH"
}

@test "git_worktree_cmd.sh lists main worktree path" {
	cd "$TEST_REPO"
	run "$CMD"
	[ "$status" -eq 0 ]
	# Match either absolute or ~/... form (emit_row substitutes $HOME with ~)
	echo "$output" | grep -q "${TEST_REPO/#$HOME/\~}"
}

@test "git_worktree_cmd.sh lists secondary worktree" {
	cd "$TEST_REPO"
	run "$CMD"
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "$TEST_REPO-wt"
}

@test "git_worktree_cmd.sh shows branch name" {
	cd "$TEST_REPO"
	run "$CMD"
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "wt-branch"
}

# ---------------------------------------------------------------------------
# preview-help subcommand
# ---------------------------------------------------------------------------

@test "preview-help subcommand exits 0" {
	run "$CMD" preview-help
	[ "$status" -eq 0 ]
}

@test "preview-help output contains ctrl-r" {
	run "$CMD" preview-help
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "ctrl-r"
}

# ---------------------------------------------------------------------------
# prune subcommand
# ---------------------------------------------------------------------------

@test "prune subcommand exits 0" {
	cd "$TEST_REPO"
	run "$CMD" prune
	[ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# remove subcommand
# ---------------------------------------------------------------------------

@test "remove subcommand removes a worktree" {
	cd "$TEST_REPO"
	run "$CMD" remove "$TEST_REPO-wt"
	[ "$status" -eq 0 ]
	# Directory should be gone
	[ ! -d "$TEST_REPO-wt" ]
}

# ---------------------------------------------------------------------------
# list subcommand (raw TSV)
# ---------------------------------------------------------------------------

@test "list subcommand emits tab-separated rows" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	# Each row should contain at least one tab
	echo "${lines[0]}" | grep -q $'\t'
}

@test "list subcommand includes main worktree path" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "${TEST_REPO/#$HOME/\~}"
}

@test "list subcommand includes branch name" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "wt-branch"
}
