import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.ObjectInputStream;

import weka.classifiers.Classifier;
import weka.core.Instances;
import weka.core.converters.ConverterUtils.DataSource;


public class ModelTester {
	Classifier m_classifier;
	BaselineClassifier.ClassifierSerializer m_instanceWriter;
	
	public ModelTester(String modelName) throws Exception {
		// Read in the model together with data header
		 // serialize model
		 ObjectInputStream ois = new ObjectInputStream(new FileInputStream(modelName));
		 m_classifier = (Classifier) ois.readObject();		 
		 m_classifier = (Classifier) weka.core.SerializationHelper.read(modelName);
		 Instances trainHeader =  (Instances) ois.readObject();
		 m_instanceWriter = new BaselineClassifier.ClassifierSerializer(trainHeader);
	}
	
	public void testModel(Instances testData, String outfile) throws IOException {
		if (testData.classIndex() < 0) {
			testData.setClassIndex(m_instanceWriter.getClassIndex());
		}
		BufferedWriter out = new BufferedWriter(new FileWriter(outfile));		
		m_instanceWriter.writeFoldResult(out, m_classifier, testData);
		out.close();
	}
 
	
	
	private static void usage() {
		System.err.println("Usage: ModelTester modelfile arffile outfile");
		System.exit(1);
	}
	
	/**
	 * @param args
	 * @throws Exception 
	 */
	public static void main(String[] args) throws Exception {
		if (args.length != 3) {
		    System.err.println("Incorrect number of arguments");
		    usage();
		}		
		
		String modelFile = args[0];
		String arffile = args[1];
		String outfile = args[2];
		
		ModelTester mt = new ModelTester(modelFile);
		Instances testData = DataSource.read(arffile);

		mt.testModel(testData, outfile);
		
	}		

}

	
	
	
	

