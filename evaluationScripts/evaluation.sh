#!/bin/bash


usage() {
    echo "evaluation.sh [-mode 2way|3way|5way|partEnt] [-xmlout outfile] system gold" >&2
    exit 1
}


mode="5way"

if [ $1 = "-mode" ]; then
    mode=$2
    shift
    shift
fi

system=$1
gold=$2


if [ -z "$system" ]; then
    echo "system output file not specified" >&2
    usage
fi

if [ -z "$gold" ]; then
    echo "gold output file not specified" >&2
    usage
fi


echo "Running evaluation with mode $mode" >&2

Rscript -e "source('evaluation.R');run.evaluation('$system', '$gold','$mode')"
