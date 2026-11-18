#!/bin/bash

# Shared helpers for the shell tests. Source it after `repo` is set.

fails=0
check() { # <expected> <actual> <what>
  [ "$1" = "$2" ] || {
    echo "FAIL: $3: got '$2', want '$1'"
    fails=$((fails + 1))
  }
}
present() { [ -e "$1" ] || [ -L "$1" ] && echo yes || echo no; }
