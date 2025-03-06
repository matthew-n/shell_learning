#!/usr/bin/env bash

# sub-scopes inherit ERR traps (-E), exit on errors (-e), no unset variables (-u),
# exit on: failures, un-declared variables, in pipe-chains, errors in pass through programs
set -o errexit -o nounset -o pipefail -o errtrace

# hide outputs from backgrouding processes
set +m

declare -a _RSYNC_OPTS
declare -a _HOSTS
declare -a _PRODS

_HOSTS=("dev.server.comp.com")
_PRODS=("prod.server.comp.com")

# set up options: sync using ssh identity, preserve file attributes, with detail
_RSYNC_OPTS+=( -e "ssh -i $ID_RSA" --verbose --archive)

# append all other command line args to rsync WITHOUT shel expansion
_RSYNC_OPTS+=( "$@" )

if true; then 
	$_HOSTS+= ( "${_PRODS[@]}" )

for host in "${_HOSTS[@]}"; do
	echo "## Sync host: ${host} ##"
	rsync "${_RSYNC_OPT[@]}" source_folder/* "$host":dest_folder
done;

## HEREDOC must be indented with tabs. Set correct formating for vim ##
# vim: set tabstop=4 softtabstop=4 shiftwidth=4 notabexpand:
