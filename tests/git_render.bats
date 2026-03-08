#!/usr/bin/env bats

# git_render.bats — unit tests for scripts/git_render.awk

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"
AWK_SCRIPT="$SCRIPTS_DIR/git_render.awk"

# ---------------------------------------------------------------------------
# Header row
# ---------------------------------------------------------------------------

@test "header row has no ANSI escape codes" {
	result=$(printf 'COL1\tCOL2\nval1\tval2\n' \
		| awk -v styles="bold,bold" -v max_widths="0,0" -v home="" -f "$AWK_SCRIPT")
	header=$(printf '%s\n' "$result" | head -1)
	[[ "$header" != *$'\033'* ]]
}

@test "header row is not truncated by max_widths" {
	result=$(printf 'AVERYLONGCOLUMN\nvalue\n' \
		| awk -v styles="normal" -v max_widths="5" -v home="" -f "$AWK_SCRIPT")
	header=$(printf '%s\n' "$result" | head -1)
	[[ "$header" == *"AVERYLONGCOLUMN"* ]]
}

# ---------------------------------------------------------------------------
# ANSI styles
# ---------------------------------------------------------------------------

@test "bold style wraps data cells with ANSI bold" {
	result=$(printf 'COL\nvalue\n' \
		| awk -v styles="bold" -v max_widths="0" -v home="" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[[ "$data" == *$'\033[1m'* ]]
}

@test "faint style wraps data cells with ANSI faint" {
	result=$(printf 'COL\nvalue\n' \
		| awk -v styles="faint" -v max_widths="0" -v home="" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[[ "$data" == *$'\033[2m'* ]]
}

@test "normal style has no ANSI codes" {
	result=$(printf 'COL\nvalue\n' \
		| awk -v styles="normal" -v max_widths="0" -v home="" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[[ "$data" != *$'\033'* ]]
}

# ---------------------------------------------------------------------------
# status style
# ---------------------------------------------------------------------------

@test "status style colors (detached) yellow" {
	result=$(printf 'PATH\tBRANCH\n/repo\t(detached)\n' \
		| awk -v styles="normal,status" -v max_widths="0,0" -v home="" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[[ "$data" == *$'\033[0;33m'* ]]
}

@test "status style colors (bare) yellow" {
	result=$(printf 'PATH\tBRANCH\n/repo\t(bare)\n' \
		| awk -v styles="normal,status" -v max_widths="0,0" -v home="" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[[ "$data" == *$'\033[0;33m'* ]]
}

@test "status style does not color normal branch names yellow" {
	result=$(printf 'PATH\tBRANCH\n/repo\tmain\n' \
		| awk -v styles="normal,status" -v max_widths="0,0" -v home="" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[[ "$data" != *$'\033[0;33m'* ]]
}

# ---------------------------------------------------------------------------
# HOME substitution
# ---------------------------------------------------------------------------

@test "absolute path not under HOME is kept as-is" {
	result=$(printf 'PATH\tBRANCH\n/other/path/repo\tmain\n' \
		| awk -v styles="normal,normal" -v max_widths="0,0" -v home="/home/alice" -f "$AWK_SCRIPT")
	printf '%s\n' "$result" | grep -q "/other/path/repo"
}

@test "HOME-matching path in column 1 is tilde-compressed" {
	result=$(printf 'PATH\tBRANCH\n/home/alice/repo\tmain\n' \
		| awk -v styles="normal,normal" -v max_widths="0,0" -v home="/home/alice" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[[ "$data" == *"~/repo"* ]]
}

@test "HOME sibling directory is NOT substituted with ~/" {
	result=$(printf 'PATH\tBRANCH\n/home/alice2/repo\tmain\n' \
		| awk -v styles="normal,normal" -v max_widths="0,0" -v home="/home/alice" -f "$AWK_SCRIPT")
	printf '%s\n' "$result" | grep -q "/home/alice2/repo"
}

@test "HOME substitution only applies to column 1" {
	result=$(printf 'PATH\tNOTES\n/home/alice/repo\t/home/alice/notes\n' \
		| awk -v styles="normal,normal" -v max_widths="0,0" -v home="/home/alice" -f "$AWK_SCRIPT")
	# Column 2 should not be substituted
	printf '%s\n' "$result" | grep -q "/home/alice/notes"
}

# ---------------------------------------------------------------------------
# Truncation
# ---------------------------------------------------------------------------

@test "cell exceeding max_widths is truncated with ..." {
	result=$(printf 'PATH\nabcdefghijklmnopqrstuvwxyz\n' \
		| awk -v styles="normal" -v max_widths="10" -v home="" -f "$AWK_SCRIPT")
	# max=10: substr(s,1,7) + "..." = "abcdefg..."
	printf '%s\n' "$result" | grep -q "abcdefg\.\.\."
}

@test "cell truncated when max_widths less than tail length does not exceed max_widths" {
	result=$(printf 'PATH\nabcde\n' \
		| awk -v styles="normal" -v max_widths="2" -v home="" -f "$AWK_SCRIPT")
	data=$(printf '%s\n' "$result" | tail -1)
	[ "${#data}" -le 2 ]
}

@test "cell at exact max_widths is not truncated" {
	result=$(printf 'PATH\nabcdefghij\n' \
		| awk -v styles="normal" -v max_widths="10" -v home="" -f "$AWK_SCRIPT")
	printf '%s\n' "$result" | grep -q "abcdefghij"
	printf '%s\n' "$result" | grep -qv "\.\.\."
}
