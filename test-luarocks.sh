#!/bin/bash
################################
# Lua versions
declare -a luaversions=(5.4 5.3)

################################
# Lua rocks to check: a list of "ROCK [MODULE]*"
#   ROCK is a name of a rock
#   each MODULE is a name of a module to be require()'d in lua
declare -a rockinfos=(
  "argparse argparse"
  "lua-cjson cjson cjson.util"
)

################################
# Test
a () { shift $1 || return 1; printf '%s' "$1"; }
d () { shift $1 && shift || return 1; printf '%s ' "$@"; }

do_test () {
  local v rockinfo rock mods m
  for v in "${luaversions[@]}"; do
    for rockinfo in "${rockinfos[@]}"; do
      rock=$(a 1 $rockinfo)
      mods=$(d 1 $rockinfo)
      echo '*** Check:' $rockinfo \
      && (
        set -x \
        && luarocks-${v} install $rock \
        && luarocks-${v} list \
        && for m in $mods; do lua${v} -e 'require("'"$m"'")' && : OK ; done \
        && luarocks-${v} remove $rock \
      ) \
      && echo '*** OK:' $rockinfo \
      || echo '*** FAIL:' $rockinfo \
      || :
      echo
    done
  done
}

################################
# Do test
do_test

################################
