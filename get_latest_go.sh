#!/bin/sh
# get_latest_go.sh
# Gets the latest Go compiler/stdlib/etc and sticks it in $HOME/go/go
# By J. Stuart McMurray
# Created 20240811
# Last Modified 20250516

set -euo pipefail

# techo (tty echo) passes its arguments to echo if stdout is associated with a
# terminal, so cronjobs can be quieter.
#
# Arguments:
# $@ - Echo's argv
techo() { if [ -t 1 ]; then /bin/echo "$@"; fi; }

# vecho (verbose echo) passes its arguments to echo if $VERBOSE is false.  The
# -v flag makes it true.
#
# Arguments:
# $@ - Echo's argv
vecho() { if $VERBOSE; then /bin/echo $@; fi; }

# eecho (error echo) prints all but its first argument to stderr and then exits
# with the status code given by its first argument.
#
# Arguments:
# $1    - Exit status code
# $2... - Echo's argv, will go to stderr.
eecho() { RET=$1; shift; /bin/echo $@ >&2; exit "$RET"; }

# goenv tries to get $1 from the envronment, or failing that tries with
# go env $1.  If both fail, nothing is sent to stdout.
#
# Arguments:
# $1 - Go env environment variable to get
goenv() {
        # Try from the environment first
        eval GOV="\${$1:-''}"
        if [ -n "$GOV" ]; then
                /bin/echo "$GOV"
        elif [ -x "${INSTALLED_GO:-}" ]; then
                "$INSTALLED_GO" env "$1"
        fi
}

# get downloads $1 and writes it to stdout.
#
# Arguments:
# $1 - URL to get
get() {
        set -euo pipefail
        if [ "$(uname -s)" = "OpenBSD" ]; then
                ftp -M -V -o- "$1"
        elif type curl >/dev/null; then
                curl \
                        --fail-with-body \
                        --location \
                        --show-error \
                        --silent \
                        "$1"
        elif type wget >/dev/null; then
                wget -qO- "$1"
        else
                eecho 2 "Need curl or Wget"
        fi
}

# install makes sure $INSTALL_DIR exists, unpacks go to a temporary directory
# in it, then moves everything into place.  The old version is deleted, if it
# exists.
install() {
        set -euo pipefail
        GOURL="https://dl.google.com/go/$TARGET_VERSION.$OS-$ARCH.tar.gz"
        mkdir -p "$INSTALL_DIR"
        TDIR=$(mktemp -d "$INSTALL_DIR/tmp_${TARGET_VERSION}_$(date +%s)_$$_XXXXXXXX")
        trap 'rm -rf "$TDIR"' EXIT

        # Download and extract.
        if $VERBOSE; then
                techo -n "Downloading and extracting $GOURL to $TDIR..."
        else
                techo -n "Downloading and extracting $GOURL..."
        fi
        get "$GOURL" | tar -C "$TDIR" -xzf -
        techo "done"
        
        # Move it all into place.
        if [ -e "$INSTALL_GOROOT" ]; then
                rm -rf "$INSTALL_GOROOT"
                vecho "Removed existing $INSTALL_GOROOT"
        fi
        mv "$TDIR/go" "$INSTALL_GOROOT"
        vecho "Moved $TDIR/go to $INSTALL_GOROOT"
}

# current_version prints the current Go version to stdout if Go's installed in
# $INSTALLED_GO.
current_version() {
        if [ -x "$INSTALLED_GO" ]; then
                "$INSTALLED_GO" version | cut -f 3 -d ' '
        fi
}

# usage prints a nice usage statement.
usage() {
        /bin/cat <<_eof
Usage: $(basename "$0") [options]

Installs Go without needing root.

Options:
  -a architecture
        Go architecture (GOARCH) to install (default $DEFAULT_ARCH)
  -d directory
        Installation directory (default $DEFAULT_INSTALL_DIR)
  -f    Force installation even if another Go install is found
  -g version
        Go version to install or to which to upgrade (default $TARGET_VERSION)
  -h    This help
  -o operating system
        Go operating system (GOOS) to install (default $DEFAULT_OS)
  -V    Do not try to update vim-go
  -v    Verbose output
_eof
}

DEFAULT_ARCH=$(goenv GOARCH)
DEFAULT_INSTALL_DIR="$HOME/go"
DEFAULT_OS=$(goenv GOOS)
DEFAULT_VERSION=$(get 'https://go.dev/VERSION?m=text' | head -n 1)
FORCE=false
INSTALL_DIR=$DEFAULT_INSTALL_DIR
TARGET_VERSION=$DEFAULT_VERSION
UPDATE_VIMGO=true
VERBOSE=false

# Work out the default GOOS/GOARCH to get by default, if not already in the
# environment and we couldn't ask Go.
if [ -z "$DEFAULT_ARCH" ]; then
        UNAME_ARCH=$(uname -m)
        case "$UNAME_ARCH" in
                "amd64")  DEFAULT_ARCH="amd64"                        ;;
                "x86_64") DEFAULT_ARCH="amd64"                        ;;
                "arm64")  DEFAULT_ARCH="arm64"                        ;;
                *)        eecho 3 "Unknown architecture: $UNAME_ARCH" ;;
        esac
fi
if [ -z "$DEFAULT_OS" ]; then
        UNAME_OS=$(uname -s)
        case "$UNAME_OS" in
                "OpenBSD") DEFAULT_OS="openbsd"            ;;
                "Darwin")  DEFAULT_OS="darwin"             ;;
                "Linux")   DEFAULT_OS="linux"              ;;
                *)         eecho 4 "Unknown OS: $UNAME_OS" ;;
        esac
fi
ARCH=$DEFAULT_ARCH
OS=$DEFAULT_OS

# Flag-parsing.
while getopts a:d:fg:ho:Vv name; do
        case $name in
                a) ARCH=$OPTARG           ;;
                d) INSTALL_DIR=$OPTARG    ;;
                f) FORCE=true             ;;
                g) TARGET_VERSION=$OPTARG ;;
                o) OS=$OPTARG             ;;
                V) UPDATE_VIMGO=false     ;;
                v) VERBOSE=true           ;;
                h) usage; exit 0          ;;
                ?) usage; exit 10         ;;
        esac
done
shift $(($OPTIND - 1))
INSTALL_GOROOT=$INSTALL_DIR/go
INSTALLED_GO=$INSTALL_GOROOT/bin/go
if [ -z "$TARGET_VERSION" ]; then
        eecho 5 "Could not determine new Go version"
fi
vecho "Target Go version: $TARGET_VERSION"

# If we already have the latest version, don't bother.
PRE_INSTALL_VERSION=$(current_version)
if ! $FORCE && [ "$PRE_INSTALL_VERSION" = "$TARGET_VERSION" ]; then
        techo "Go version $PRE_INSTALL_VERSION already installed"
        exit 0
elif $FORCE && [ "$PRE_INSTALL_VERSION" = "$TARGET_VERSION" ]; then
        techo "Go version $PRE_INSTALL_VERSION already installed, forcing re-install"
elif $FORCE; then
        techo "Forcing install of Go version $TARGET_VERSION"
elif [ -n "$PRE_INSTALL_VERSION" ]; then
        vecho "Current Go version: $PRE_INSTALL_VERSION"
else
        vecho "Go not found, will install"
fi

# Do the install itself
install

# Did it work?
POST_INSTALL_VERSION=$(current_version)
if [ -z "$POST_INSTALL_VERSION" ]; then
        eecho 11 "Did not get Go version after install"
elif [ "$POST_INSTALL_VERSION" != "$TARGET_VERSION" ]; then
        eecho 12 "Intended to install $TARGET_VERSION but got $POST_INSTALL_VERSION"
else
        /bin/echo "Installed Go version $(current_version)"
fi

# If we've got vim-go, update things.
if $UPDATE_VIMGO && type vim >/dev/null 2>&1 && [ -f "$HOME/.vimrc" ] &&
        egrep -q "^Plugin 'fatih/vim-go'" "$HOME/.vimrc"; then
        techo -n "Updating vim-go..."
        vim --not-a-term +PluginUpdate +GoUpdateBinaries +qall >/dev/null
        techo "done"
fi

# If we don't have Go in our path, remind the user to add it.
if type hash >/dev/null 2>&1; then
      hash -r
fi
if [ "$(which go)" != "$INSTALLED_GO" ]; then
        EXPORT="echo 'export PATH=\$PATH:$(
                goenv GOPATH
        )/bin:$(
                goenv GOROOT
        )/bin' >> ~"
        techo "
Path to Go missing from \$PATH: $INSTALLED_GO

Fix with one of the following...

$EXPORT/.profile
$EXPORT/.bash_profile
$EXPORT/.zprofile"
fi
