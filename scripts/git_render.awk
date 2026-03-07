# git_render.awk — two-pass TSV renderer with per-column ANSI styling
#
# USAGE:
#   { printf "COL1\tCOL2\n"; echo "$data"; } | \
#       awk -v styles="bold,status,faint,faint" \
#           -v max_widths="0,35,0,0" \
#           -f git_render.awk
#
# PARAMETERS:
#   styles      Comma-separated style names, one per column:
#                 bold    — bright/bold text
#                 faint   — dimmed text
#                 status  — yellow for (detached) or (bare), normal otherwise
#                 normal  — no decoration
#   max_widths  Comma-separated max character widths, one per column.
#               0 means uncapped. Cells exceeding their max are truncated
#               with a trailing "..." (3 chars included in the width budget).
#
# BEHAVIOUR:
#   • Pass 1 (main rules): store every cell; track per-column max width.
#   • Pass 2 (END block):  cap widths, pad cells, wrap with ANSI codes.
#     The header row (NR==1) is emitted plain so fzf --color='header:...'
#     can style it independently.
#   • Columns are separated by two spaces. The last column is not padded.

BEGIN {
    FS     = "\t"
    BOLD   = "\033[1m"
    FAINT  = "\033[2m"
    YELLOW = "\033[0;33m"
    RESET  = "\033[0m"
    nrows  = 0
    ncols  = 0
    n_styles = split(styles,     style_arr, ",")
    n_maxw   = split(max_widths, maxw_arr,  ",")
}

{
    nrows++
    if (NF > ncols) ncols = NF
    for (i = 1; i <= NF; i++) {
        rows[nrows, i] = $i
        if (length($i) > col_width[i])
            col_width[i] = length($i)
    }
}

function truncate(s, maxw,    tail) {
    tail = "..."
    if (maxw > 0 && length(s) > maxw)
        return substr(s, 1, maxw - length(tail)) tail
    return s
}

END {
    # Compute effective column widths (col_width capped by max_widths)
    for (c = 1; c <= ncols; c++) {
        maxw = (c <= n_maxw) ? maxw_arr[c] + 0 : 0
        eff_width[c] = (maxw > 0 && col_width[c] > maxw) ? maxw : col_width[c]
    }

    for (r = 1; r <= nrows; r++) {
        line = ""
        for (c = 1; c <= ncols; c++) {
            val = rows[r, c]
            maxw = (c <= n_maxw) ? maxw_arr[c] + 0 : 0

            # Truncate data rows (never truncate the header)
            # Keep orig_val for style checks — status colours must match the
            # original value, not the potentially-truncated display value.
            orig_val = val
            if (r > 1)
                val = truncate(val, maxw)

            # Pad all but the last column to its effective width
            if (c < ncols)
                padded = sprintf("%-*s", eff_width[c], val)
            else
                padded = val

            if (r == 1) {
                # Header row — no ANSI; fzf colors it via --color='header:...'
                cell = padded
            } else {
                st = (c <= n_styles) ? style_arr[c] : "normal"
                if (st == "bold") {
                    cell = BOLD padded RESET
                } else if (st == "faint") {
                    cell = FAINT padded RESET
                } else if (st == "status") {
                    if (orig_val == "(detached)" || orig_val == "(bare)")
                        cell = YELLOW padded RESET
                    else
                        cell = padded
                } else {
                    cell = padded
                }
            }

            line = (c == 1) ? cell : line "  " cell
        }
        print line
    }
}
