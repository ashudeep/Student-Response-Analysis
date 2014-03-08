import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.util.Random;

import weka.classifiers.Classifier;
import weka.classifiers.Evaluation;

import weka.classifiers.meta.FilteredClassifier;
import weka.filters.unsupervised.attribute.Remove;

import weka.core.Attribute;
import weka.core.Instances;
import weka.core.Utils;
import weka.core.converters.ConverterUtils.DataSource;

/**
 * A helper class to read in an arff file
 * run an evaluation
 * And print out results in LaTeX table format
 * @author mdzikovs
 *
 */

public class BaselineClassifier {
	private Instances m_data;
	/** If non-null, a file to write evaluation results to **/
	private Evaluation m_eval = null;
	/**
	 * Random seed to use, fixed for now
	 */
	private int m_seed = 1;
	/**
	 * Number of folds to use, fixed for now
	 */
	private int m_folds = 10;
	private static final String CLASSIFIER = "weka.classifiers.trees.J48";//lazy.IBk";
	
	private final Classifier m_baseClassifier;
	
	private final ClassifierSerializer m_instanceWriter;
       
	public static class ClassifierSerializer {
		private final int m_numClasses;
		private final int m_classIndex;
		private final Attribute m_classAttribute;
		/** 
		 * If true, assume that the test data has actual values stored (like in cross-validation) and write them out
		 */
		private boolean m_writeActual = false;

		public ClassifierSerializer(Instances data) {
			this(data, false);
		}		
		
		/** Initialize based on training data **/
		public ClassifierSerializer(Instances data, boolean writeActual) {
			m_classAttribute = data.classAttribute();
			m_classIndex = data.classIndex();
			m_numClasses = data.numDistinctValues(m_classIndex);			
			m_writeActual = writeActual;
		}		
		
		void setWriteActual(boolean writeActual) {
			m_writeActual = writeActual;
		}
		
		void writeFoldResult(BufferedWriter out, Classifier c, Instances test) {
			writeFoldResult(out, c, test, 0);
		}
		
		void writeFoldResult(BufferedWriter out, Classifier c, Instances test, int foldN) {
			if (out == null) {
				return;
			}
			try {
				if (foldN <= 1) {				
					// first fold or no folds (foldN = 0) -- also write header
					// 	if necessary, write out a header for the result file
					if (m_writeActual) {
						out.write("ID\tFold\tActual\tPredicted\n");
					} else {
						out.write("ID\tFold\tPredicted\n");				    	
					}		
				}	

				for (int i = 0; i < test.numInstances(); i++) {
				    double pred = c.classifyInstance(test.instance(i));
				    out.write(test.instance(i).stringValue(0) + "\t");
				    out.write(foldN + "\t");	
				    if (m_writeActual) {
				    	out.write(getClassLabel((int)test.instance(i).classValue()) + "\t");
				    }
				    out.write(getClassLabel((int)pred) + "\n");
				}					
			} catch (Exception e) {
				System.err.println("Exception " + e + " caught while trying to print fold " + foldN);
				e.printStackTrace();
			}
		}
							
		public int getClassIndex() {
			return m_classIndex;
		}		
		
		/**	 Given a class index, get a label 
		 * **/	
		private String getClassLabel(int index) {
			if (index < m_numClasses) {
				return m_classAttribute.value(index);
			} else {
				return null;
			}

		}
				
		
		/**
		 * Writes the given classifier to a file together with a training header
		 * These can be read together later to initialize a ModelTester
		 * @throws IOException 
		 * @throws FileNotFoundException 
		 */
		static void writeModel(String fileName, Classifier classifier, Instances data) throws FileNotFoundException, IOException {
			ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(fileName));
			oos.writeObject(classifier);			
			Instances trainHeader = new Instances(data, 0);
			trainHeader.setClassIndex(data.classIndex());
			oos.writeObject(trainHeader);
			oos.flush();
			oos.close();	
		}
		
	}
		
	private BaselineClassifier(Instances data) throws Exception {
		m_data = data;
		// in our data class is last, always
		m_data.setClassIndex(m_data.numAttributes() - 1);	

	    // classifier
	    String[] tmpOptions = {};//weka.core.Utils.splitOptions("-K 35 -W 0 -I -A \"weka.core.neighboursearch.LinearNNSearch -A \\\"weka.core.EuclideanDistance -R first-last\\\"\"");
	    m_baseClassifier = (Classifier) Utils.forName(Classifier.class, CLASSIFIER, tmpOptions);		
	    
	    m_instanceWriter = new ClassifierSerializer(m_data);
	}

	private void performCrossValidation(String outfile) throws Exception {

		BufferedWriter out = new BufferedWriter(new FileWriter(outfile));		
		
	    // randomize data
	    Random rand = new Random(m_seed);
	    Instances randData = new Instances(m_data);
	    randData.randomize(rand);
	    randData.stratify(m_folds);
	    
	    m_instanceWriter.setWriteActual(true);

	    
	    // perform cross-validation
	    m_eval = new Evaluation(randData);
	    for (int n = 0; n < m_folds; n++) {
	    		
	    	Instances train = randData.trainCV(m_folds, n);
	    	// the above code is used by the StratifiedRemoveFolds filter, the
	    	// code below by the Explorer/Experimenter:
	    	// Instances train = randData.trainCV(m_folds, n, rand);
	    	Instances test = randData.testCV(m_folds, n);

	    	// build and evaluate classifier
	    	Classifier fc = buildClassifier(train);

	    	m_eval.evaluateModel(fc, test);
	    	m_instanceWriter.writeFoldResult(out, fc, test, n+1);	    	
	    }	
	    
		out.close();		

	}

	Classifier buildClassifier(Instances train) throws Exception {		
		// remove the first attribute, which is instance ID
		Remove rm = new Remove();
		rm.setAttributeIndices("1");  // remove 1st attribute
		// classifier
		// meta-classifier
		FilteredClassifier fc = new FilteredClassifier();
		fc.setFilter(rm);
		fc.setClassifier(Classifier.makeCopy(m_baseClassifier));
		// train and make predictions
		fc.buildClassifier(train);
		return fc;	
	}
	
	public void saveClassifier(String fileName) throws Exception {
		Classifier fc = buildClassifier(m_data);
		ClassifierSerializer.writeModel(fileName, fc, m_data);
	}
		
			
	
	private static void usage() {
		System.err.println("Usage: BaselineClassifier [-outputModel] arffile outfile");
		System.exit(1);
	}
	
	/**
	 * @param args
	 * @throws Exception 
	 */
	public static void main(String[] args) throws Exception {
		if ((args.length < 2) ||  (args.length > 3)) {
		    System.err.println("Incorrect number of arguments");
		    usage();
		}		
		
		String arffile = null;
		String outfile = null;
		boolean outputModel = false;
		
		if (args.length == 2) {
			arffile = args[0];
			outfile = args[1];
		} else {
			if (args[0].equals("-outputModel")) {
				outputModel = true;
				arffile = args[1];
				outfile = args[2];				
			} else {
				System.err.println("Incorrect switch used: " + args[0]);
				usage();
			}
		}
		
		Instances data = DataSource.read(arffile);
		
		
		if (outputModel) {
			// just train on the data and output the model
			BaselineClassifier bc = new BaselineClassifier(data);
			bc.saveClassifier(outfile);
		} else {
			// perform cross-validation
			BaselineClassifier bc = new BaselineClassifier(data);
			bc.performCrossValidation(outfile);
		}
	}
		
}
		

