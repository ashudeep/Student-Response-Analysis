#!/bin/bash


usage() {
    echo "semevalPilotTaskEvaluation.sh -o xmlout -g goldStandard -d participantDir [ -t teamName" ] >&2
    exit 1
}


mode="5way"


# initial : disables standard warning messages
while getopts ":o:g:d:t:" opt; do
  case $opt in
    o)
      xmlout=$OPTARG
      ;;
    g)
      gold=$OPTARG
      ;;
    d)
      inputdir=$OPTARG
      ;;
    t)
      teamname=$OPTARG
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
restargs=$@


if [ -z "$xmlout" ]; then
    echo "xml output file not specified" >&2
    usage
fi

if [ -z "$inputdir" ]; then
    echo "no input directory specified" >&2
    usage
fi

if [ ! -d "$inputdir" ]; then
    echo "inputdir $inputdir not a directory" >&2
    usage
fi

if [ -z "$gold" ]; then
    echo "gold standard file not specified" >&2
    usage
fi

if [ -z "$teamname" ]; then
    # use directory name for team name
    teamname=$(basename $inputdir)
fi

# Process beetle files

pilotfiles=""

for file in ${inputdir}/*.txt; do
    if [ -f "$file" ]; then
	case $file in 
	    *description.txt)
		# skip description files
		;;
	    *[pP][iI][lL][oO][tT][eE][nN][tT][aA][iI][lL][mM][eE][nN][tT]*)
		if [ -z "$pilotfiles" ]; then
		    pilotfiles="'$file'"
		else
		    pilotfiles="$pilotfiles, '$file'"
		fi
		;;
	esac
    fi
done


if [ ! -z "$pilotfiles" ]; then
    pilotfiles="c($pilotfiles)"    
else
    echo "WARNING: no pilot entailment files found in directory $inputdir" >& 2
fi

echo "Running pilot task evaluation" >&2

Rscript -e "source('evaluation.R');semeval.pilot.evaluation(pilot.files=$pilotfiles, pilot.gold='$gold', xmlOut='$xmlout', team='$teamname')"
