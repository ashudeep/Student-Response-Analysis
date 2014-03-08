#!/bin/bash


usage() {
    echo "semevalTaskEvaluation.sh [-m 2way|3way|5way|partEnt] -o xmlout [ -b beetleGold ] [ -s sciEntsBankGold ] -d participantDir [ -t teamName" ] >&2
    exit 1
}


mode="5way"


# initial : disables standard warning messages
while getopts ":m:o:b:s:d:t:" opt; do
  case $opt in
    m)
      mode=$OPTARG
      ;;
    o)
      xmlout=$OPTARG
      ;;
    b)
      beetlegold=$OPTARG
      ;;
    s)
      sebgold=$OPTARG
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

if [ -z "$teamname" ]; then
    # use directory name for team name
    teamname=$(basename $inputdir)
fi

# Process beetle files

beetlefiles=""
sebfiles=""

for file in ${inputdir}/*; do
    if [ -f "$file" ]; then
	case $file in 
	    *[bB][eE][eE][tT][lL][eE]*)
		if [ -z "$beetlegold" ]; then
		    echo "The directory $inputdir contains an apparent beetle file $file, but -beetlegold file is not specified" >& 2
		    echo "Aborting"
		    usage
		fi
		
		if [ -z "$beetlefiles" ]; then
		    beetlefiles="'$file'"
		else
		    beetlefiles="$beetlefiles, '$file'"
		fi
		;;
	    
	    *[sS][eE][bB]*|*[Ss][Cc][Ii][Ee][Nn][Tt][Ss][Bb][Aa][Nn][Kk]*)
		if [ -z "$sebgold" ]; then
		    echo "The directory $inputdir contains an apparent SciEntsBank file $file, but -sebgold file is not specified" >& 2
		    echo "Aborting"
		    usage
		fi
		
		if [ -z "$sebfiles" ]; then
		    sebfiles="'$file'"
		else
		    sebfiles="$sebfiles, '$file'"
		fi
		;;	    
        esac
    fi
done


if [ ! -z "$beetlefiles" ]; then
    beetlefiles="c($beetlefiles)"    
else
    echo "WARNING: no Beetle files found in directory $inputdir" >& 2
fi

if [ ! -z "$sebfiles" ]; then
    sebfiles="c($sebfiles)"
else
    echo "WARNING: no SciEntsBank files found in directory $inputdir" >& 2
fi

echo "Running evaluation with mode $mode" >&2

Rscript -e "source('evaluation.R');semeval.challenge.evaluation(beetle.files=$beetlefiles, beetle.gold='$beetlegold', seb.files=$sebfiles, seb.gold='$sebgold', xmlOut='$xmlout', team='$teamname', mode='$mode')"
