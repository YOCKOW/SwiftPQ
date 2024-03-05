#!/bin/zsh

# Download gram.y file from PostgreSQL (mirror) repository
# and let 'bison' parse the file to make it easy to read.

set -u

local -r assetsDir="$(cd "$(dirname $0)" && pwd -L)"
local -r grammarsDir="${assetsDir}/grammars"
local -r gramyURL="https://raw.githubusercontent.com/postgres/postgres/master/src/backend/parser/gram.y"
local -r gramyPath="${grammarsDir}/gram.y"

set -ex
mkdir -p "$grammarsDir"
curl -sSL "$gramyURL" >"$gramyPath"
cd "$grammarsDir"
bison -v gram.y
ls -ahl .
