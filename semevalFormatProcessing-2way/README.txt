This directory contains code examples for dealing with source semeval
format, that can be used as a starting point for data processing. It
provides the tools to build the baseline classifier from (Dzikovska at
al., NAACL 2012) and output the results in the format accepted by the
evaluation scripts. The process involves 3 steps:

1. Extracting baseline features from SEMEVAL data and making an arff
file. This examples uses a bash shell script + perl, relying on
Text::Similarity, Lingua::Stem and XML::SAX packages. The perl script
is called extractBaselineFeatures.pl and operates on a single file in
the semeval data; the shell script iterates over all data files.

The script requires Text::Similarity v 0.09 or higher to function properly.

The input is the directory containing core data (e.g., BeetleCore or
SciEntsBankCore). The output is printed on standard out; it is arff
file format that can be read by Weka

./extractBaselineFeatures.sh [-m 5way|3way|2way] PathToDataDirectory > output.arff

e.g.,
./extractBaselineFeatures.sh -m 5way /disk/scratch/data/semeval/final_beetle/train/BeetleCore > beetleBaselineFeatures.arff

The mode value, specified with -m, defaults to "5way". It has to match the data, or otherwise the arff file produced will have incorrect value range for the class.

2. Building and running the classifier. This is done in Java using
weka (note that it is tested to work with Weka 3.6, but does not work
with the unstable 3.7 version). Your classpath, or parameters passed
to javac/java, must contain weka.jar


 * Compiling baseline classifier code
javac -classpath /usr/share/java/weka.jar BaselineClassifier.java

 * Running baseline classifier code

-- cross-validation on training data
java -cp /usr/share/java/weka.jar:./ BaselineClassifier ./beetleBaselineFeatures.arff beetleBaselineOutput.txt

-- build and save a baseline model based on training data

java -cp /usr/share/java/weka.jar:./ BaselineClassifier -outputModel ./beetleBaselineFeatures.arff baselineTrain.model

-- Use the saved model to predict test data

java -cp /usr/share/java/weka.jar:./ ModelTester  ./baselineTrain.model ./beetleTestBaseline.arff beetleTestBaseline5way.txt


3. The R evaluation scripts take as input your system data and the
gold standard data in tabular format. We provide a script to extract
the proper tabular format from the xml data for gold data. It is
implemented using a combination of xslt operating on individual files
and a bash script that iterates over the directory. The stylesheet
used is extractEvaluationTable.xsl. Our bash script uses xsltproc
(from the libxslt library) as the xslt processor.

./extractEvaluationTable.sh PathToDataDirectory output.txt

e.g.,
./extractEvaluationTable.sh /disk/scratch/data/semeval/final_beetle/train/BeetleCore/ trainingGold.txt

Similarly to step 1, the path to data directory should point to the
directory where the core files are stored.



4. We also provide scripts to extract the tabular format for
evaluation from partial entailment data. It is implemented in the same
way as the main data extraction script, with a combination of
extractPartialEntailmentTable.xsl and extractPartialEntailmentTable.sh
The batch script relies on the xsltproc as above.

./extractPartialEntailmentTable.sh PathToDataDirectory output.txt

./extractPartialEntailmentTable.sh /disk/scratch/data/SemEval2013_releases/SemEval-2013_Task7_Pilot_Training/data/  partialEntailmentGold.txt



=======================================
Complete set of "training gold" files
=======================================
