#!/bin/sh

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

ministat=@ministat@/bin

export PATH="$PATH:$ministat"

files="$@"
if [ -z "$files" ]; then
	files=/proc/self/fd/0
fi

for file in "$files"; do
        awk '/^time /{print $2}' $file | \
        	ministat -w72
done
