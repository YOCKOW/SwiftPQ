#!/bin/zsh

# Download gram.y file from PostgreSQL (mirror) repository
# and let 'bison' parse the file to make it easy to read.

set -eu

local -r assetsDir="$(cd "$(dirname $0)" && pwd -L)"
local -r grammarsDir="${assetsDir}/grammars"
local -r postgresBranch="REL_16_2"
local -r gramyURL="https://raw.githubusercontent.com/postgres/postgres/${postgresBranch}/src/backend/parser/gram.y"
local -r gramyPath="${grammarsDir}/gram.${postgresBranch}.y"

set -x
mkdir -p "$grammarsDir"
curl -sSL "$gramyURL" >"$gramyPath"
cd "$grammarsDir"
bison -v "gram.${postgresBranch}.y"
ls -ahl .
