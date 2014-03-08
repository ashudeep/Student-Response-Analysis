#!/bin/bash

# A script that takes a directory with answer assessment in xml and
# outputs a table for evaluation.


usage() {
    echo "extractEvaluationTable.sh dir resultfile" >&2
    exit 1
}

dir=$1
resfile=$2

if [ -z "$dir" ]; then
    echo "dir not specified" >&2
    usage
fi

if [ -z "$resfile" ]; then
    echo "resfile not specified" >&2
    usage
fi

if [ ! -d "$dir" ]; then
    echo "$dir is not a directory" >&2
    usage
fi

name=$(basename $dir)

tmpfile=/tmp/result.$RANDOM

echo -e "id\tqid\ttestSet\tmodule\tcount\taccuracy" > $tmpfile

for file in `ls -1 ${dir}/*.xml`; do
    xsltproc "./extractEvaluationTable.xsl" $file  >> $tmpfile

    if [ $? -ne 0 ]; then
	echo "" >& 2
	echo "Failure executing  xsltproc ./extractEvaluationTable.xsl $file  >> $tmpfile. Aborting." >& 2
	exit 2
    fi

done

cp $tmpfile $resfile

rm $tmpfile
