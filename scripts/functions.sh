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
