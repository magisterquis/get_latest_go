#!/bin/ksh
#
# basic_tests.t
# Make sure our code is up-to-date and doesn't have debug things.
# By J. Stuart McMurray
# Created 20250504
# Last Modified 20250516

set -uo pipefail

. t/shmore.subr

OLDVER="go1.24.1"
TMPD=$(mktemp -d)/go
trap 'rm -rf $TMPD; tap_done_testing' EXIT

tap_plan 12

# Make sure an old version installs to an empty directory.
GOT=$(./get_latest_go.sh -d "$TMPD" -g "go1.24.1" -V)
tap_ok $? \
        "Exited happily after installing old Go ($OLDVER) in $TMPD" \
        "$0" $LINENO
WANT="Installed Go version go1.24.1"
tap_is \
        "$GOT" "$WANT" \
        "Output from installing old Go ($OLDVER) correct" \
        "$0" $LINENO
GOT=$("$TMPD/go/bin/go" version | cut -f 3 -d ' ')
tap_is "$GOT" "go1.24.1" "Intstalled correct old version" "$0" $LINENO

# Get the latest version.
LVER=$(curl -fLsS 'https://go.dev/VERSION?m=text' | head -n 1)
tap_ok $? "Requested latest go version" "$0" $LINENO
tap_like "$LVER" 'go\d+\.\d+\.\d+' \
        "Latest Go version looks like a version" \
        "$0" $LINENO
tap_isnt "$LVER" "$OLDVER" "Latest version isn't the old version" "$0" $LINENO

# Update to the latest Go.
GOT=$(./get_latest_go.sh -d "$TMPD" -V)
tap_ok $? "Updated to latest version ($LVER) in $TMPD" "$0" $LINENO
WANT="Installed Go version $LVER"
tap_is \
        "$GOT" "$WANT" \
        "Output from updating to latest Go ($LVER) correct" \
        "$0" $LINENO

# Shouldn't do anything a second time.  This will fail if we're running during
# a release.
GOT=$(./get_latest_go.sh -d "$TMPD" -V)
tap_ok $? \
        "Exited happily without installing latest Go ($LVER) a" \
"second time without -f" \
        "$0" $LINENO
WANT=""
tap_is \
        "$GOT" "$WANT" \
        "Output from not installing latest Go ($LVER) a second time without" \
"-f correct" \
        "$0" $LINENO

# Force-upgrading to the same latest version should also work.
GOT=$(./get_latest_go.sh -d "$TMPD" -f -V)
tap_ok $? \
        "Exited happily after forcing a re-install of latest Go ($LVER)" \
        "$0" $LINENO
WANT="Installed Go version $LVER"
tap_is \
        "$GOT" "$WANT" \
        "Output from not installing latest Go ($LVER) a second time without" \
"-f correct" \
        "$0" $LINENO

# vim: ft=sh
