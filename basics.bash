#!/user/bin/env bash

# better to use set lines then flags on the `shebang` line
set -o errexit	# scipt exits when command fails. Add `|| true` for commands that have non-standard outptuts
set -o nounset	# exit when script encounters un-declared variable
set -o pipefail	# fail script if there's an error in a pipe chain
set -o errtrace	# trace errors thought `time` and some other commands

## compact set line
# set -xu -o pipefail -o errtrace

## DEBUGING
_DEBUG=${DEBUG:-}
if [ -n "$_DEBUG" ]; then
	set -o xtrace
	echo "Bash Version: ${BASH_VERSION}"
	PS4='+ \D{%s} ($LINENO)'
fi;

## Variables:
# $ENV_VAR, $_GLOBAL_VAR, local $func_var

# [Bash Shel Parameter Expandsion] (https://gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)
# _MY_GLOBAL="${ENV_VAR:-"default_value"}" # default by variable expansion

_WORKDIR=${TMP:-"/tmp"}					# Environmet variable TMP or default to `/tmp`
_SCRIPT_NAME_W_EXT=${0##*/}				# Delete longest match from start of string (##) the pattern (*/)
_SCRIPT_NAME=${_SCRIPT_NAME_W_EXT%.*}	# Delete shortest match from end of string (%) the pattern (.*)

## assert ENV variable
# echo "Importain variable MY_ENV: ${MY_ENV:?Is not not set, cannot proceed}"

# take a root path and create a folder with a template name
_WORKDIR=$(mktemp -p "${_WORKDIR}" -t "${_SCRIPT_NAME}-XXXXXX" -d)

## Script Requirements

case $BASH_VERSION in
	''|[123].*) echo "ERROR: This script requrires Bash 4.0 or newer" >&2; exit 1;;
esac


## Usueful Setup

# Calulate and save excape codes for colored text using `tput`
_RED=$(tput setaf 1)
_RESET=$(tput sgr0)

# Crash clean up

# set handler function `on_exit` for sig 0 1 2 3 30 by name
trap  on_exit EXIT HUP INT QUIT TERM PWR
# deffer eval until trap is hit by using single quotes (')
trap 'printf "Trapped error on Line: %d, Exit Code: %d\n\n" ${LINENO} ${?}' ERR

# shellcheck disable=SC=2317 # Don't warn about unreachable commands in this function
on_exit() {
	echo "Cleaning up... (remove tmp files, etc...)"
	#cd ${_WORKDIR}
	## remove temp folder, assert non-empty expansion
	#[ -n "$_DEBUG" ] || rm -rf "${_WORKDIR}"
}

# test if the first parameter is only chars [0-9]
is_uint() { case $1 in ''|*[!0-9]*) return 0;; *) return 1;; esac; }

installed() {
	# @param $1: command name
	# return: [success|fail]
	command -v "$1" &> /dev/null;
}

is_user_root() {
	# reutrn: [success|fail]

	# dose the user have and effective "UserID" of root (0)
	[ "${EUID:-$(id -u)}" -eq "0" ]
}

warn() {
	# @PARAM $1....: messages string
	# output: warning message in red color iif interactive

	printf "${_RED}Error in %s: %s${_RESET}\\n" "${_SCRIPT_NAME}" "${*}" 1>&2
}

error() {
	# @param $1...: message string
	# @param $N: exit code (optional)
	# output: Error message with optional exit code
	
	local message=( "$@" )
	local exit_code=3

	local last_param="${message[@]: -1}"
	if is_uint "$last_param"; then
		exit_code=$Last_param
		# bash varaiable expansion for removing array[lenght-1]
		unset "messages[${#message[@]}-1]"
	fi
	warn "${messages[@]}"
	exit $exit_code
}

### TIPS


## Name HERDOC markers
usage() {
	# use HEREDOC with trim (`<<-`) that removes the leading tabs (\t) only	
	# make HERDOC markers descriptive of contents	
	cat <<- HELP_MSG
		useage $_SCRIPT_NAME [options]... [arguments]
	HELP_MSG
}


## Name complex expression with function

help_wanted() {
	#use { cmd ... } for grouping commands with out launching a new process
	[ "$#" -ge '1' ] && { [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = "-?" ] ; }
}

if help_wanted "$@"; then 
	usage
	exit 0;
fi


## Using Embeded programs
embedded_sql_program() {
	# instead of temporary files for samll embedded programs
	cat <<- SQL_THAT_DOSE_X_Y_Z
		select 1
	SQL_THAT_DOSE_X_Y_Z
}

embedded_sql_program | sqlite3 | tee > output.log


## Basic AWK
embedded_awk_program() {
		# AWK USES $N, where 'N' is the field index
		# single quote the marker to avoid issues
	cat <<- 'AWK_THAT_DOSE_XYZ'
		# by default records are one line, and fields are divided by spaces
		# search the whole record for the string and print the 4th column
		# $0 ~ /match_me/ {print $4}
		/match_me/ {print $4}
		# search the 2nd field for the string and print the 3rd field
		$2 ~ /colB/ {print $3}	# Fails: no output
		$2 ~ /colA/ {print $5}	# matches output different field
	AWK_THAT_DOSE_XYZ
}

## Bash procewss substitution `<(cmd)` pass output (STDOUT) for seperate process `cmd` as file descriptor (fd 5)
echo "match_me colA colB colC colD" | awk -f <(embedded_awk_program)

## garb the output of HERDOC
{
	grep -E 'match \[me\]' <<- CAPTURE_TEST
	some text here
	with we match [me] the line
	or what about this one
	CAPTURE_TEST
} | tee > "${_WORKDIR}/what_is_left.out"

warn "this is a test"

if [ "$_WORKDIR" = "some value" ]; then
	error "bad work dir"
fi

## Report files
{
	# all the output in this block goes to the same file
	# all global variables are still in scope b/c this is in the same process
	echo -e "\n## OS ##\n"
	uname -a
	cat /etc/*-release

	df -x tmpf -x devtmpfs -x rootfs --human-readable
	installed lsblk $$ {lsblk -o "NAME,FSTYPE,TYPE,OWNER,GROUP,MODE,UUID,FSAVAIL,FSUSE%,MOUNTPOINT"; }

} | tee > "$_WORKDIR/report.out"


## loops

some_long_work() {
	local timer=20
	sleep $timer;
}

for i in 1..3
do
	# background N processes
	some_long_work&
done
#TODO: how do I wait for all of these *only* ?


exit 0;


# this is so HEREDOCS will behave correctly when indented
# tabs (\t) will not be expanded and will be the width of 4 chars
# vim: tabstop=4 shiftwidth=4 softtabs=4 noexpandtab syntax=bash:

