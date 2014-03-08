#!/bin/bash
#rm -f answers.csv
./extractBaselineFeatures.sh -m 2way ../../semeval2013-Task7-5way/beetle/train/Core/ > beetleBaselineFeatures.arff;
./extractBaselineFeatures.sh -m 2way ../../semeval2013-Task7-5way/beetle/test-unseen-answers/Core/ > beetleTestBaseline5way-UA.arff;
./extractBaselineFeatures.sh -m 2way ../../semeval2013-Task7-5way/beetle/test-unseen-questions/Core/ > beetleTestBaseline5way-UQ.arff;
#python addFeatures.py beetleBaselineFeatures.arff
#python addFeatures.py beetleTestBaseline5way-UA.arff
#python addFeatures.py beetleTestBaseline5way-UQ.arff

javac -classpath /home/ashudeep/Downloads/weka-3-6-9/weka.jar BaselineClassifier.java 
echo "Compilation Done"
#echo "Cross validating model..."
#java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ BaselineClassifier ./beetleBaselineFeatures.arff beetleBaselineOutput.txt
echo "Saving the output Model.."
java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ BaselineClassifier -outputModel ./beetleBaselineFeatures.arff baselineTrain.model
echo "Testing..."
#./extractEvaluationTable.sh ../../semeval2013-Task7-5way/beetle/train/Core trainingGold.txt
#./extractPartialEntailmentTable.sh ../../semeval2013-Task7-5way/beetle/train/Core trainingGold-partial.txt
./extractEvaluationTable.sh ../../semeval2013-Task7-5way/beetle/test-unseen-answers/Core/ testGold-UA.txt
./extractEvaluationTable.sh ../../semeval2013-Task7-5way/beetle/test-unseen-questions/Core/ testGold-UQ.txt
#cp trainingGold.txt ../evaluationScripts
sed -i 's/partially_correct_incomplete/incorrect/g' testGold-UA.txt
sed -i 's/contradictory/incorrect/g' testGold-UA.txt
sed -i 's/irrelevant/incorrect/g' testGold-UA.txt
sed -i 's/non_domain/incorrect/g' testGold-UA.txt
sed -i 's/partially_correct_incomplete/incorrect/g' testGold-UQ.txt
sed -i 's/contradictory/incorrect/g' testGold-UQ.txt
sed -i 's/irrelevant/incorrect/g' testGold-UQ.txt
sed -i 's/non_domain/incorrect/g' testGold-UQ.txt
cp testGold-UA.txt ../evaluationScripts
cp testGold-UQ.txt ../evaluationScripts

echo "Testing on Unseen Answers..."
java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ ModelTester  ./baselineTrain.model ./beetleTestBaseline5way-UA.arff beetleTestBaseline5way-UA.txt


echo "Now Evaluating"
cp beetleTestBaseline5way-UA.txt ../evaluationScripts

cd ../evaluationScripts
./evaluation.sh -mode 2way beetleTestBaseline5way-UA.txt testGold-UA.txt
cd -


echo "Testing on Unseen Questions"
java -cp /home/ashudeep/Downloads/weka-3-6-9/weka.jar:./ ModelTester  ./baselineTrain.model ./beetleTestBaseline5way-UQ.arff beetleTestBaseline5way-UQ.txt
echo "Now Evaluating"
cp beetleTestBaseline5way-UQ.txt ../evaluationScripts
cd ../evaluationScripts
./evaluation.sh -mode 2way beetleTestBaseline5way-UQ.txt testGold-UQ.txt
