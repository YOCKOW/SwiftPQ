#!/bin/zsh

# Download gram.y file from PostgreSQL (mirror) repository
# and let 'bison' parse the file to make it easy to read.

set -eu

local -r assetsDir="$(cd "$(dirname $0)" && pwd -L)"
local -r grammarsDir="${assetsDir}/grammars"
local -r postgresBranch="REL_16_2"
local -r gramyURL="https://raw.githubusercontent.com/postgres/postgres/${postgresBranch}/src/backend/parser/gram.y"
local -r gramyPath="${grammarsDir}/gram.${postgresBranch}.y"
local -r gramOutputPath="${grammarsDir}/gram.${postgresBranch}.output"
local -r gramOutputExtractedPath="${grammarsDir}/gram.${postgresBranch}.output.extracted.txt"

set -x
mkdir -p "$grammarsDir"
curl -sSL "$gramyURL" >"$gramyPath"
cd "$grammarsDir"
bison -v "gram.${postgresBranch}.y"
{ set +x; } 2>/dev/null

if [[ -f "$gramOutputPath" ]]; then
  sed -n '/Grammar/,/Terminals, with rules where they appear/p' "$gramOutputPath" | \
    grep -E '^[[:space:]]*[0-9]+' | \
    sed -E 's/^[[:space:]]*[0-9]+//g' >"$gramOutputExtractedPath"
fi

set -x
ls -ahl .
