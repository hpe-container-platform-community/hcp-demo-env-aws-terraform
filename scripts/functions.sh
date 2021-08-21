#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

function print_term_width {

   # Usage:
   #
   # print_term_width '='

   local char=$1

   printf "%`tput cols`s"|tr ' ' "$char"
}

function print_header {

   # Usage:
   #
   # print_header 'Some header message'

   local title=$1

   print_term_width '='
   echo $title
   print_term_width '='
}

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=15
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}