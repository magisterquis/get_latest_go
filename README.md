Get Latest Go
=============
Gets the latest Go compiler/stdlib/etc and sticks it in `$HOME/go/go`.  The
general idea is to have a cronjob which checks for Go updates every so often
to avoid having to fiddle with system packages.

Also updates [vim-go](https://github.com/fatih/vim-go) if it looks like it's
being used.

Quickstart
----------
1. Clone this repo
   ```sh
   git clone git@github.com:MagisterQuis/get_latest_go.git && cd ./get_latest_go
   ```
2. Have a look at [`get_latest_go.sh`](./get_latest_go.sh)
   ```sh
   less ./get_latest_go.sh
   ```
3. Install/Update Go
   ```sh
   $ ./get_latest_go.sh
   ```

Usage
-----
```
Usage: get_latest_go.sh [options]

Installs Go without needing root.

Options:
  -a architecture
        Go architecture (GOARCH) to install (default amd64)
  -d directory
        Installation directory (default /home/you/go)
  -f    Force installation even if another Go install is found
  -g version
        Go version to install or to which to upgrade (default go1.24.3)
  -h    This help
  -o operating system
        Go operating system (GOOS) to install (default openbsd)
  -V    Do not try to update vim-go
  -v    Verbose output
```

The defaults change depending on the platform on which the script is run.
