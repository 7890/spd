#!/bin/bash
# part of https://github.com/7890/spd
#
# example process script for spd
#
# this file is process-specific
#
# expecting process format instructions "pif" file with the following keys:
#
# id=1480801485314327778_f57d246c-79d8-42b5-bdfc-b92afed837b1
# file=/tmp/abc.wav
# out_format=opus
# out_dir=/tmp/opus
#
#
#//tb/1612

#######################################################
#FULLPATH="`pwd`/$0"
#the directory where this script (daemon.sh) is strored
#DIR=`dirname "$FULLPATH"`

if [ $# -ne 1 ]
then
	echo "process.sh: error: need param: process instruction file"
	exit 1
fi

pif="$1"

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

for tool in date cat cut grep tail sleep; \
	do checkAvail "$tool"; done

if [ ! -r "$pif" ]
then
	echo "process.sh: error: missing read permission for file: $pif"
	exit 1
fi

key_()
{
	#use tail to get last added (multiple same keys)
	echo `cat "$pif" | grep "^$1=" | tail -1 | cut -d"=" -f2-`
}

id=`key_ id`
echo_()
{
	echo "process.sh $id: `date --iso-8601=ns`: $1"
}

echo_ "starting"

file=`key_ file`
out_format=`key_ out_format`
out_dir=`key_ out_dir`

echo_ "dummy converting $file as $out_format to $out_dir"
echo_ "dummy delaying"
sleep 2

exit $?

#eof
