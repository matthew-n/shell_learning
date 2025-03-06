#!/usr/bin/env bash

# sub-scopes inherit ERR traps (-E), exit on errors (-e), no unset variables (-u),
# exit on: failures, un-declared variables, in pipe-chains, errors in pass through programs
set -o errexit -o nounset -o pipefail -o errtrace

# hide outputs from backgrouding processes
set +m

# limit newness
shopt -s compat"${BASH_COMPAT=32}" || true # if the shell is newer reduce its feature set or ignore

# floor on how old
[ "${BASH_VERSINFO[0]:-0}" -ge 4 ] || { echo "ERROR: This script requires Bash 4.0 or newer" >&2; exit 1; }

# current shell test https://unix.stackexchange.com/a/3439
#Determine our shell without using $SHELL, which may lie
shell="sh"
if test -f /proc/mounts; then
   case $(/bin/ls -l /proc/$$/exe) in
        *bash) shell=bash ;;
        *dash) shell=dash ;;
        *ash)  shell=ash ;;
        *ksh)  shell=ksh ;;
        *zsh)  shell=zsh ;;
    esac
fi

# https://stackoverflow.com/a/76011352
unused_fd() (
    FD=${1:-3}
    MAX=$(ulimit -n)
    while [ $FD -lt $MAX ]
    do
        if ! ( : <&$FD ) 2>&-
        then
            printf %d $FD

            [ "$(eval "echo $FD<&-")" ] && return 8
            return 0
        fi
        FD=$(( FD + 1 ))
    done
    return 24
)

work () {
	sleep $1 || false
}

# passing arrays to functions "Expanding an Array" seems to be the option that is compatible with 3.2 and clear
# https://linuxsimply.com/bash-scripting-tutorial/functions/script-argument/pass-array-to-function/
send_command () {
	echo "to do" || false
	# set the first arg to readonly variable and shift if off the args array
	local -r cmd=$1; shift;
	# expand the args array quoting each element and sperating with space
	local -a arr=( $@ );

	# example body code: looping over local array
	for x in "${arr[@]}"; do
		# do not quote these variables
		# shellcheck disable=SC2086
		echo $cmd >& ${x};
	done
}

declare fd
declare -a fds
declare -a dest_list=("a" "b" "c")

#Show the (p)rompt text and (t)imeout after 5 seconds take the n chars (s)ilently
read -r -p "Wait 5 seconds or press any key to continue immediately" -t 5 -n 1 -s

# function in the background https://bash.cyberciti.biz/guid/Putting_functions_in_background
for _db in "${dest_list[@]}"; do
	## bash __required__ ##
	# multiplexing https://unix.stackexchange.com/a/132111

	## bash 4.x syntax for getting file descriptor ##
	# exec {fd}> >(open_connection "$_db")

	## backward compatible ##
	fd=$(unsed_fd)||exit
	# https://stackoverflow.com/question/8295908/how-to-use-a-variable-to-indicate-a-file-descriptor-in-bash
	# output redirected https://stackoverflow.com/a59848305
	eval "exec ${fd}> >( oppend \"$_db\" >/dev/null )"

	# add file descriptor to multiplex list
	fds+=( "$fd" )
done;


send_command "test command" "${fds[@]}"

# pause execution until all sub-processes return
wait

# [Notes]
# unattended background executions: https://stackoverflow.com/a/52033580
# job messages and job control: https://stackoverflow.com/a/38278291
# useful examples of redirecting: https://stackoverflow.com/a/51061046
# manage error messages: https://stackoverflow.com/a/75249283
# i/o redirection: https://tldp.org/LDP/abs/html/io-redirect.html
# https://stackoverflow.com/questions/29142/getting-ssh-to-execute-a-command-in-the-background-on-target-machine

## HEREDOC must be indented with tabs. Set correct formating for vim ##
# vim: set tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab syntax=bash:
