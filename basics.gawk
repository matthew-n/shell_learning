#! /usr/bin/env -S gawk -f
#
# -v AKW_VAR="some value"

function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s}
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s}
function trim(s) { return ltrim(rtrim(s)); }

function parse_ts(s, ts) {
	input: "Fri Mar  3 12:59:59 2099"
	output: unix timestamp

	pattern = "([A-Z][a-z]{2}) ([A-Z][a-z]{2}) +([0-9]{1,2}) ([0-9]{2}):([0-9]{2}):([0-9]{2}) ([0-9]{4})"
	
	match(s, pattern, ts)
	
	mo = months[ts[2]]
	day = sprintf("02d", ts[3])
	yr = ts[7]

	return mktime(yr " " mo " " day " " ts[4] " " ts[5] " " ts[6])
}

# always run before reading the inputs
BEGIN {

	# for outputting ISO dates "YYYY-mm-dd HH:MM:ss"
	ts_format = "%F %T"

	# crate a map of { 01 => "Jan", .., 12 => "Dec" }
	m=split("Jan|Feb|Mar|Apr|May|Jun|Aug|Sep|Oct|Nov|Dec",d, "|")
	for(o=1;o<=m;o++) months[d[o]]=sprintf("%02d", o)

	keyIndx = split("colA|colB|colC|colD|colE", tmp, "|")
	for (i in tmp) KEYS[tmp[i]] = i

}

/recTypeA/ {
	# `KEYS["column_name"]` returns a field index
	# `$exp` evaluates exp as a field index refference
	print $KEYS["colB"] # output the index that matches "colB posision"

	$KEYS["colC"] ="replacement value"
}

!/recType/ {
	# print $0;
	print;
}

/MarkStart/,/MarkStop/ {
	print "we are in a range between the marks"
}

# the opening brace ( `{` ) for the action must be on the same line as the test
SOME_FLAG == "ON" && $0 ~ /recTypeA/  {
	# use ( `>` ) to truncate and open a file
	print "use a flag to control extra actions" > "/tmp/somefile.log"
	# this will reuse the prior file and *append*
	print "another line" > "/tmp/somefile.log"
}

# always runs at the end of execution
END {
	# ensures that the file is closed
	close("/tmp/somefile.log")
}

# vim: tabstop=4 shiftwidth=4 softtabs=4 noexpandtab syntax=awk:
