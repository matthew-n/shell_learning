#!/usr/bin/env -S sed --debug -E -n -f

# `env -S` - *new*-ish feature that allows multiple options on the interpruter
# sed is launched in (n)o print mode with (E)xtended RexExp

# sed is stack based procedural streaming coded manipulations
# you have the current "pattern" buffer and the "hold" buffer

################################# START SAMPLE #################################
#
#
#
################################## END SAMPLE ##################################

/match_me/ {
	# do some action group

	# ending in print
	p;
}


#### Test Command ####
# test this script (%) passing as input STDIN (`<`) the process substitution (`<(cmd)`)
# use sed to find the sample input in the script (%) and remove the comment marker (#)
# sed commands: delete from BOF to "START SAMPLE", if contians "END SAMPLE" stop, remove leading "#" and print
# !./% < <(sed -E -ne '0,/^#* START SAMPLE/d; /END SAMPLE/q; s/\#//; p;' %)

################################ START OUTPUT ################################
#
#
#
#
################################ END OUTPUT   ################################

# vim: tabstop=4 shiftwidth=4 softtabs=4 noexpandtab syntax=sed:
