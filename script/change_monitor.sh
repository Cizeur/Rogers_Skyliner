#!/bin/bash
output=`diff -N $1 $2`
if ! [[ $output == "" ]] ; then
	echo "File: $1 was changed"
	diff -N $1 $2
fi
