#!/bin/bash
#part of https://github.com/7890/spd
# create process instruction file "pif"
# for given file with standard values
# and move to daemon input dir
#
# this file is process-specific (example)
#
#//tb/1612

#FULLPATH="`pwd`/$0"
#the directory where this script (daemon.sh) is strored
#DIR=`dirname "$FULLPATH"`

if [ $# -ne 2 ]
then
	echo "error: need arguments"
	echo "file, daemon input dir"
	exit 1
fi

file="$1"
daemon_input_dir="$2"

#######################################################
checkAvail()
{
	which "$1" >/dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]
	then
		echo "error: tool \"$1\" not found. please install"
		exit 1
	fi
}

for tool in mv date uuidgen mktemp; \
	do checkAvail "$tool"; done

if [ ! -r "$file" ]
then
	echo "error: missing read permission for file: $file"
	exit 1
fi

if [ ! -d "$daemon_input_dir" ]
then
	echo "error: not a directory: $daemon_input_dir"
	exit 1
fi

a=`date +%s%N`
b=`uuidgen`
id=${a}_${b}
pif=`mktemp`
(
	echo id=$id
	echo file=$file
	echo out_format=opus
	echo out_dir=/tmp/opus
) > ${pif}_${id}.properties

echo ${pif}_${id}.properties

mv ${pif}_${id}.properties "$daemon_input_dir"
#eof
