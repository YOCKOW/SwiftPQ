#!/bin/zsh

# Download gram.y file from PostgreSQL (mirror) repository
# and let 'bison' parse the file to make it easy to read.


local -r assetsDir="$(cd "$(dirname $0)" && pwd -L)"
local -r grammersDir="${assetsDir}/grammers"
local -r gramyURL="https://raw.githubusercontent.com/postgres/postgres/master/src/backend/parser/gram.y"
local -r gramyPath="${grammersDir}/gram.y"

set -ex
mkdir -p "$grammersDir"
curl -sSL "$gramyURL" >"$gramyPath"
cd "$grammersDir"
bison -v gram.y
ls -ahl .
