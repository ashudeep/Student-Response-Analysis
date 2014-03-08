All evaluation scripts are implemented in R. They assume a file input
format where the first line is the header with column names, and the
other lines are data. The first column must contain utterance IDs. The
last column must contain the system output classes. The first line
must be a header. All columns must be tab-separated, and contain an
equal number of fields, the same as the header.  Note that the files
are sorted by the utterance ID internally, so the order of entries in
the input files is ignored.

Look into ../semevalFormatProcessing to see example scripts that
output correct format, using xslt (for gold data) or java/Weka (for
building a classifier). The instructions in the README file there show
how to create the the files used in the examples below.


The script takes 2 parameters: the system output (first) and the gold
output. The evaluation results are printed on standard out.

There are 3 equivalent ways to run evaluation scripts:


* Using shell script we provided for convenience

./evaluation.sh [-mode 5way|3way|2way|partEnt] <system> <gold>

e.g.,
./evaluation.sh -mode 5way ../semevalFormatProcessing/beetleBaselineOutput.txt ../semevalFormatProcessing/trainingGold.txt

If mode is not specified, it defaults to 5-way task. 


* (inside R)
source("evaluation.R")
run.evaluation("<system>", "<gold>", mode="5way|3way|2way")

e.g.,
run.evaluation("../semevalFormatProcessing/beetleBaselineOutput.txt","../semevalFormatProcessing/beetleTrainingGold.txt", mode="5way")



* Using the Rscript utility

Rscript -e 'source("evaluation.R");run.evaluation("<system>","<gold>", mode="5way|3way|2way")'

e.g.,
Rscript -e 'source("evaluation.R");run.evaluation("../semevalFormatProcessing/beetleBaselineOutput.txt","../semevalFormatProcessing/trainingGold.txt",mode="5way")'


############################################################
Batch evaluation on multiple files, with output to xml


batchEvaluation.sh [-m 2way|3way|5way|partEnt] -o xmlout -g goldfile systemfile+

e.g.,

./batchEvaluation.sh -m 5way -o test.xml -g ../semevalFormatProcessing/beetleTrainingGold.txt ../semevalFormatProcessing/beetleBaselineOutput.txt ../semevalFormatProcessing/beetleTrainingGold.txt

##############################################################

A special script implementing SEMEVAL Task 7 evaluation procedure

semevalTaskEvaluation.sh [-m 2way|3way|5way|partEnt] -o xmlout [ -b beetleGold ] [ -s sciEntsBankGold ] -d participantDir [ -t teamName ]

e.g.,

./semevalTaskEvaluation.sh -m 5way -o 5waytext.xml -b ../../task7SampleFormats/baselines/beetle5wayMajority.txt -s ../../task7SampleFormats/baselines/seb5wayMajority.txt -d /disk/scratch/data/SemEval2013_releases/task7evaluation/baselines/5way/


And for pilot evaluation:

semevalPilotTaskEvaluation.sh -o xmlout -g goldStandard -d participantDir [ -t teamName ]

e.g.,

./semevalPilotTaskEvaluation.sh -o test.xml -g /disk/scratch/data/SemEval2013_releases/task7evaluation/gold/seb-pilotentailment-test-gold.txt -d /disk/scratch/data/SemEval2013_releases/task7evaluation/baselines/pilotentailment/

