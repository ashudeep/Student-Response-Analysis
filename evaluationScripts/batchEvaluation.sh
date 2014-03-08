#!/bin/bash


usage() {
    echo "batchEvaluation.sh [-m 2way|3way|5way|partEnt] -o xmlout -g goldfile systemfile+" >&2
    exit 1
}


mode="5way"


# initial : disables standard warning messages
while getopts ":m:o:g:" opt; do
  case $opt in
    m)
      mode=$OPTARG
      ;;
    o)
      xmlout=$OPTARG
      ;;
    g)
      gold=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Missing argument to -$OPTARG." >&2
      usage
      ;;
  esac
done

shift $((OPTIND-1))
systemfiles=$@


if [ -z "$gold" ]; then
    echo "gold output file not specified" >&2
    usage
fi

if [ -z "$xmlout" ]; then
    echo "xml output file not specified" >&2
    usage
fi

if [ -z "$systemfiles" ]; then
    echo "no system input files specified" >&2
    usage
fi

filein=""
for system in $systemfiles; do
    if [ ! -f $system ]; then
	echo "Input file $system does not exist"
	usage
    fi

    if [ -z $filein ]; then
	filein="'$system'"
    else
	filein="$filein, '$system'"
    fi
done

echo "Running evaluation with mode $mode" >&2

Rscript -e "source('evaluation.R');batch.evaluation($filein, xmlOut='$xmlout', goldFile='$gold', mode='$mode')"
