#!/bin/bash

#python addFeatures.py beetleBaselineFeatures.arff
#echo "Done with beetleBaselineFeatures"
#python addFeatures.py beetleTestBaseline5way-UA.arff
#echo "Done with beetleTestBaseline5way-UA"
#python addFeatures.py beetleTestBaseline5way-UQ.arff
#echo "Done with beetleTestBaseline5way-UQ"


javac -classpath /home/ashudeep/Downloads/weka-3-6-9/weka.jar BaselineClassifier.java 
echo "Compilation Done"
#echo "Cross validating model..."
#java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ BaselineClassifier ./beetleBaselineFeatures.arff beetleBaselineOutput.txt
echo "Saving the output Model.."
java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ BaselineClassifier -outputModel ./beetleBaselineFeatures_new.arff baselineTrain.model
echo "Testing..."
#./extractEvaluationTable.sh ../../semeval2013-Task7-5way/beetle/train/Core trainingGold.txt
#./extractPartialEntailmentTable.sh ../../semeval2013-Task7-5way/beetle/train/Core trainingGold-partial.txt
./extractEvaluationTable.sh ../../semeval2013-Task7-5way/beetle/test-unseen-answers/Core/ testGold-UA.txt
./extractEvaluationTable.sh ../../semeval2013-Task7-5way/beetle/test-unseen-questions/Core/ testGold-UQ.txt
#cp trainingGold.txt ../evaluationScripts
cp testGold-UA.txt ../evaluationScripts
cp testGold-UQ.txt ../evaluationScripts

echo "Testing on Unseen Answers..."
java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ ModelTester  ./baselineTrain.model ./beetleTestBaseline5way-UA_new.arff beetleTestBaseline5way-UA.txt


echo "Now Evaluating"
cp beetleTestBaseline5way-UA.txt ../evaluationScripts

cd ../evaluationScripts
./evaluation.sh beetleTestBaseline5way-UA.txt testGold-UA.txt
cd -


echo "Testing on Unseen Questions"
java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ ModelTester  ./baselineTrain.model ./beetleTestBaseline5way-UQ_new.arff beetleTestBaseline5way-UQ.txt
echo "Now Evaluating"
cp beetleTestBaseline5way-UQ.txt ../evaluationScripts
cd ../evaluationScripts
./evaluation.sh beetleTestBaseline5way-UQ.txt testGold-UQ.txt
