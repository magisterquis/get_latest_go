#!/bin/ksh
#
# basic_tests.t
# Make sure our code is up-to-date and doesn't have debug things.
# By J. Stuart McMurray
# Created 20250504
# Last Modified 20250504

set -uo pipefail

. t/shmore.subr

tap_plan 3

# Make sure we didn't leave any stray DEBUGs or TAP_TODOs lying about.
GOT=$(egrep -InR '(#|\*)[[:space:]]*()DEBUG' | sort -u)
tap_is "$GOT" "" "No files with DEBUG comments" "$0" $LINENO
GOT=$(egrep -InR 'TAP_TODO[=]' t/*.t | sort -u)
tap_is "$GOT" "" "No TAP_TODO's" "$0" $LINENO
GOT=$(egrep -InR 'TODO():' *.sh t/*.t | sort -u)
tap_is "$GOT" "" "No TODO's" "$0" $LINENO

# vim: ft=sh
