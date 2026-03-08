#!/usr/bin/env bats

# git_repository_cmd.bats — unit tests for scripts/git_repository_cmd.sh

bats_require_minimum_version 1.5.0

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"
CMD="$SCRIPTS_DIR/git_repository_cmd.sh"

setup() {
	# Create a fake projects directory tree: Projects/github.com/org/repo
	TEST_PROJECTS=$(mktemp -d)
	TEST_REPO="$TEST_PROJECTS/github.com/org/myrepo"
	mkdir -p "$TEST_REPO"
	TEST_REPO2="$TEST_PROJECTS/github.com/org/otherrepo"
	mkdir -p "$TEST_REPO2"
}

teardown() {
	rm -rf "$TEST_PROJECTS"
}

# ---------------------------------------------------------------------------
# list subcommand
# ---------------------------------------------------------------------------

@test "list subcommand exits 0 with valid projects dir" {
	GIT_FZF_REPOSITORY_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
}

@test "list subcommand emits repo paths" {
	GIT_FZF_REPOSITORY_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "myrepo"
}

@test "list subcommand emits multiple repos" {
	GIT_FZF_REPOSITORY_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "myrepo"
	echo "$output" | grep -q "otherrepo"
}

@test "list subcommand exits 0 with empty projects dir" {
	EMPTY_DIR=$(mktemp -d)
	GIT_FZF_REPOSITORY_PATH="$EMPTY_DIR" run "$CMD" list
	[ "$status" -eq 0 ]
	rm -rf "$EMPTY_DIR"
}

@test "list subcommand output has no trailing slash" {
	GIT_FZF_REPOSITORY_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
	# No line should end with /
	! echo "$output" | grep -q '/$'
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
# unknown subcommand
# ---------------------------------------------------------------------------

@test "unknown subcommand exits 1" {
	run "$CMD" unknownsubcmd
	[ "$status" -eq 1 ]
}

@test "unknown subcommand prints error to stderr" {
	run --separate-stderr "$CMD" unknownsubcmd
	echo "$stderr" | grep -q "unknown subcommand"
}
