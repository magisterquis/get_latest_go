# Makefile
# Test get_latest_go
# By J. Stuart McMurray
# Created 20250504
# Last Modified 20250516

SHMORESUBR     = t/shmore.subr
SHMOREURL      = https://raw.githubusercontent.com/magisterquis/shmore/refs/heads/master/shmore.subr

.PHONY: test help update

test: ## Run ALL the tests (default)
	prove -It --directives

update: ## Fetch the latest Shmore
	curl\
		--fail\
		--show-error\
		--silent\
		--output ${SHMORESUBR}.new\
		${SHMOREURL}
	diff -q ${SHMORESUBR} ${SHMORESUBR}.new >/dev/null &&\
		rm ${SHMORESUBR}.new ||\
		mv ${SHMORESUBR}.new ${SHMORESUBR}

help: .NOTMAIN ## This help
	@perl -ne '/^(\S+?):+.*?##\s*(.*)/&&print"$$1\t-\t$$2\n"' \
		${MAKEFILE_LIST} | column -ts "$$(printf "\t")"
