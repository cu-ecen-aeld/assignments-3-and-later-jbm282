#!/bin/sh
#
filesdir=$1
searchstr=$2

if test -z $filesdir || test -z $searchstr
then
	echo bad parameters
	exit 1
fi
if test ! -d $filesdir
then
	echo bad directory
	exit 1
fi

x=-1
for i in $(find $filesdir)
do
	x=$((x + 1))
done
y=$(grep -R $searchstr $filesdir | wc -l)
printf 'The number of files are %d and the number of matching lines are %d\n' $x $y

