#!/bin/bash

# Use it either reading from stdin or by specifing
# multiple files as arguments

# xeon07$ hist stdout.log
# x <stdin>
# +------------------------------------------------------------------------+
# |         x                                                              |
# |         x                                                              |
# |         x                                                              |
# |         x                                                              |
# |         x                                                              |
# |        xxx                                                             |
# |        xxx                                                             |
# |       xxxxx                                                            |
# |       xxxxxx                                                           |
# |       xxxxxxx                                                         x|
# ||________M_A___________|                                                |
# +------------------------------------------------------------------------+
#     N           Min           Max        Median           Avg        Stddev
# x  30      3.585183      3.763913      3.591559     3.5973344   0.031719975
#
# Other ministat options can be passed as well. The -S option splits the results
# in multiple plots.


usage() { echo "Usage: hist [-hSAns] [-c confidence] [-w width] files..." 1>&2; exit 1; }

function stat_files() {
	tmpfiles=()
	sedcmd=""

	for file in ${files[@]}; do
		tmp=$(mktemp)
		awk '/^time /{print $2}' "$file" > "$tmp"
		sedcmd+="s:$tmp:$file:g;"
		tmpfiles+=($tmp)
	done

	if [ $split == 1 ]; then
		for f in "${tmpfiles[@]}"; do
			ministat $ministat_opt $f | sed -e "$sedcmd"
		done
	else
		ministat $ministat_opt ${tmpfiles[@]} | sed -e "$sedcmd"
	fi

	rm ${tmpfiles[@]}
}

split=0
ministat_opt="-w72"

while getopts "hSAnsc:w:" o; do
    case "${o}" in
        S) split=1 ;;
        c) ministat_opt+=" -c $OPTARG" ;;
        w) ministat_opt+=" -w $OPTARG" ;;
        A) ministat_opt+=" -$o" ;;
        n) ministat_opt+=" -$o" ;;
        s) ministat_opt+=" -$o" ;;
        *) usage ;;
    esac
done

shift $((OPTIND-1))

ministat=@ministat@/bin
#ministat=/nix/store/sh9b484bnhkajxnblpwix7fhbkid6365-ministat-20150715-1/bin

export PATH="$PATH:$ministat"

files=("$@")
if [[ -z "${files[@]}" ]]; then
	awk '/^time /{print $2}' | ministat $ministat_opt
else
	stat_files
fi
