#!/bin/sh

if grep -q 'output = args[2]' "$1"; then exit 0; fi

sed '/length(args)>0/aif (length(args)>1) { output = args[2] } else { output = "?" }' -i "$1"
sed '/jsonlite::flatten/,$s/input_file/output/g' -i "$1"
