#!/bin/bash
# part of https://github.com/7890/spd
#
# example process script for spd
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

if [ ! -r "$pif" ]
then
	echo "process.sh: error: missing read permission for file: $pif"
	exit 1
fi

#use tail to get last added
id=`cat "$pif" | grep "^id=" | tail -1 | cut -d"=" -f2`

echo_()
{
        echo "process.sh $id: `date --iso-8601=ns`: $1"
}

echo_ "starting"

file=`cat "$pif" | grep "^file=" | tail -1 | cut -d"=" -f2-`
out_format=`cat "$pif" | grep "^out_format=" | tail -1 | cut -d"=" -f2-`
out_dir=`cat "$pif" | grep "^out_dir=" | tail -1 | cut -d"=" -f2-`

echo_ "dummy converting $file as $out_format to $out_dir"
echo_ "dummy delaying"
sleep 2

exit $?

#eof
