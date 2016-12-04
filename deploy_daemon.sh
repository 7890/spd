#!/bin/bash
# part of https://github.com/7890/spd
# deploy a daemon instance
#//tb/1612

#FULLPATH="`pwd`/$0"
#the directory where this script (daemon.sh) is strored
#DIR=`dirname "$FULLPATH"`

if [ $# -ne 4 ]
then
	echo "error: need arguments:"
	echo "daemon,deploy_dir,instance,process"
	exit 1
fi

daemon="$1"
daemon_deploy_dir="$2"
daemon_instance="$3"
process="$4"

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

for tool in ln mkdir grep; \
	do checkAvail "$tool"; done

if [ ! -r "$daemon" ]
then
	echo "error: missing read permission for file: $daemon"
	exit 1
fi

if [ ! -r "$process" ]
then
	echo "error: missing read permission for file: $process"
	exit 1
fi

echo "deploying daemon $daemon to directory $daemon_deploy_dir"

mkdir -p "$daemon_deploy_dir"
if [ $? -ne 0 ]
then
	echo "error: could not create directory $daemon_deploy_dir"
	exit 1
fi

echo "$daemon"|grep "^/"
if [ $? -eq 0 ]
then
	#absolute path
	ln -s "$daemon" "$daemon_deploy_dir"/daemon.sh
else
	#relative path
	ln -s "${PWD}/${daemon}" "$daemon_deploy_dir"/daemon.sh
fi

echo "$process"|grep "^/"
if [ $? -eq 0 ]
then
	#absolute path
	ln -s "$process" "$daemon_deploy_dir"/process.sh
else
	#relative path
	ln -s "${PWD}/${process}" "$daemon_deploy_dir"/process.sh
fi

cd "$daemon_deploy_dir" && ./daemon.sh "$daemon_instance"

#eof
