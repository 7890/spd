#!/bin/bash
# part of https://github.com/7890/spd
#
# Shell Process Daemon SPD
#
# spd helps to manage simple input/output queue processing
# 
# a typical process cycle:
#
# calling process:
#
# external process tells daemon what should be processed:
#    -create a key=value (.properties) file holding all processing variables
#     that the daemon must know to do processing.
#    -move process instructions file "pif" to the input directory of the daemon.
#     moving a file is an atomic operation on the filesystem.
#     -> this prevents the case of a file being processed that's not yet fully written to storage.
#    -watch the daemon's done and failed directories for results
#     or check for another signal emitted by the daemon.
#
# daemon:
#
# the daemon script runs until interrupted and does the following:
#    -initialize daemon directory.
#     create input, done and failed directories.
#     create any other required initializations.
#    -start the main loop:
#       -list the input directory with a .properties filter to match extepcted pifs.
#        the file with the oldest timestamp/creation date will be processed next.
#        the queue is first in first out "FIFO".
#       -the only mandatory key in a pif is 'id' which can be used by daemon.sh and process.sh
#       -process.sh will extract needed variables from pif.
#        this can include uri(s) to file(s), output destinations or anything else
#        that can be expressed as a string key=value pair.
#       -process input as requested
#       -when finished, move the pif, process log and (eventually) output files to either:
#        direcotry "done" or directory "failed".
#        eventuall signal success or error by other means
#       -proceed with next cycle
#
# example:
#
# a daemon that converts audio files to a given format.
#
# a calling process will create a pif per file to be processed like the following:
#
# $processing_q_dir=/tmp/q
#
# a=`date +%s%N`
# b=`uuidgen`
# id=${a}_${b}
# pif=`mktemp`
# (
#    echo id=$id
#    echo file=/tmp/abc.wav
#    echo out_format=opus
#    echo out_dir=/tmp/opus
# ) > ${pif}_${id}.properties
#
# mv $pif daemon/in
#
##daemon will start this processing job as soon as every older
##jobs are finished.
#
##waiting for result to become available (with timeout)
#
# for i in {1..10}
# do
#    echo "waiting since $i seconds for result"
#    ls -1 ${processing_q_dir}/done/*_${id}.properties
#    if [ $? -eq 0 ]
#    then
##      ...
#       exit 0
#    else
##      ...
#    fi
#    sleep 1
# done
## waited for too long
# exit 1
#
#
# generic files:
# -daemon.sh
# -deploy_daemon.sh
#
# files specific to process:
# -create_pif.sh
# -process.sh
#
#
# daemons can help to process things in parallel and make use of multiple available cpus
# instead of processing everything sequentially.
#
# for the above audio example multiple daemons could run.
# calling processes would then assign pifs to one of the available daemons (i.e. round robin).
#
#//tb/1612

#######################################################
echo_()
{
	echo "daemon.sh $instance_postfix: `date --iso-8601=ns` $1"
}

if [ $# -ne 1 ]
then
	echo "daemon.sh: error: need arguments"
	echo "instance number"
	exit 1
fi

instance_postfix="$1"

FULLPATH="`pwd`/$0"
#the directory where this script (daemon.sh) is strored
DIR=`dirname "$FULLPATH"`

echo_ "=========================================="
echo_ "running from working directory $DIR"

indir="${DIR}/in"
outdir="${DIR}/done"
faildir="${DIR}/failed"

#process_script="${DIR}/process.sh"

#looking for process script named process.sh (can be symbolic link)
process_script="${DIR}/process.sh"
if [ ! -r "$process_script" ]
then
	echo "daemon.sh: error: missing read permission for file: $process_script"
	exit 1
fi

#######################################################
checkAvail()
{
	which "$1" >/dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]
	then
		echo_ "error: tool \"$1\" not found. please install"
		exit 1
	fi
}

#######################################################
set_process_status()
{
	echo_ "dummy set_process_status($1,$2)"
}

#######################################################
daemon_init()
{
	#create directories if not existing
	mkdir -p "$indir"
	mkdir -p "$outdir"
	mkdir -p "$faildir"

	#do more ...
	echo_ "initialized"
	echo_ "processing pifs with $process_script"
	echo_ "copy pifs to $indir"
}

#######################################################
for tool in ls cp mv mkdir sleep date cat grep tail cut tee wc; \
	do checkAvail "$tool"; done

daemon_init

#main loop
#######################################################
while true
do
	cd "$indir"
	ls -1tr *.properties 2>/dev/null \
		| while read pif
	do
		echo_ "daemon loop, `ls -1 *.properties|wc -l` files in queue"
		echo_ "processing $pif `date`"

		#use tail to get last added
		id=`cat "$pif" | grep "^id=" | tail -1 | cut -d"=" -f2`
		ret=$?
		if [ $ret -ne 0 ]
		then
			echo_ "/!\\ id not found in pif, skippping"
			continue
		fi
		echo_ "id is $id"

		"$process_script" "${indir}/${pif}" 2>&1 | tee "$pif".process.log
		#PIPESTATUS only available with /bin/bash
		#return value of first command in pipe chain
		ret=${PIPESTATUS[0]}
#		echo "pipestatus is: $ret"
		if [ $ret -eq 0 ]
		then
			mv "$pif" "$outdir"
			mv "$pif".process.log "$outdir"
#			set_process_status "$id" "$pif" done
			echo_ "done id: $id"
		else
			mv "$pif" "$faildir"
			mv "$pif".process.log "$faildir"
			echo_ "failed id: $id"
#			set_process_status "$id" "$pif" failed
		fi
	done
	sleep 0.5
done
#eof
