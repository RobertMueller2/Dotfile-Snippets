#!/bin/sh
SCRIPT=$(readlink -f $0)

# the scripts place is also where the other ones are that need to be searched for annotations
SRC_DIR=$(dirname "${SCRIPT}")
MAN_OUT="$HOME/.local/share/man/man1"
MARKDOWN_OUT="$HOME/Cheatsheets"

mkdir -p "$MARKDOWN_OUT" "$MAN_OUT"

# Find only scripts with the @extract-docs marker
# bit of a wild mix of stuff, but kinda does what it should
find "$SRC_DIR" -maxdepth 1 \( -type f -o -type l \) -name '*.sh' \
  -exec grep -l '^# @extract-docs' {} \; | while read -r script; do
  echo "Processing $script"

  base=$(basename "$script")
  md_out="$MARKDOWN_OUT/${base}.md"

  echo "# \`${base}\`" > "$md_out"
  echo >> "$md_out"
  echo "## Synopsis" >> "$md_out"
  echo >> "$md_out"
  echo "${base} commands:">> "$md_out"
  echo >> "$md_out"
  grep -E '^\s*_cmd_' "$script" \
      | sed -E 's/^\s*_cmd_([a-zA-Z0-9_-]+)\).*/\1/' \
      | sort \
      | awk '{ print "- `" $0 "`" }' \
      >> "$md_out"

  echo >> "$md_out"
  echo "## Description" >> "$md_out"

  _pattern="^[[:space:]]*\(_cmd\|###\|##\)"

  cat $script | grep "$_pattern" | \
      sed -e 's,^\s*###\s*,,g' \
      -e 's,^\s*##\s*\(.\+\)\s*,```\n\1\n```,g' \
      -e 's,^\s*_cmd_\(\w\+\)),\n\n### \1\n,g' >> "$md_out"


  # manpage generation via pandoc
  if command -v pandoc >/dev/null 2>&1; then
    pandoc -s "$md_out" -t man -o "$MAN_OUT/${base}.1"
  fi

done
