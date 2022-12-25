#!/bin/sh
#
writefile=$1
writestr=$2

if test -z $writefile || test -z $writestr
then
	echo bad params
	exit 1
fi
mkdir -p $(dirname $writefile)
if [ $? != 0 ]
then
	echo 'could not make file'
	exit 1
fi

echo $writestr > $writefile

if [ $? != 0 ]
then
	echo 'could not make file'
	exit 1
fi
