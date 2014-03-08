#!/bin/python
import sys, os
from lemma_pos_matching import lemma_matching as lemma_pos
from lemma_matcing import lemma_matching
from word_matching import word_matching,parse_xml
import nltk
header=1

def clean(word):
    return word.strip(",. ")

def bleu(text, entailment):
    def ngrams(stringlist, n):
        i = 0
        while i + n <= len(stringlist):
            yield tuple(stringlist[i:i+n])
            i += 1
    words = [clean(x) for x in text.lower().split()]
    hwords = [clean(x) for x in entailment.lower().split()]
    bleus = 0
    for N in range(1,1+len(hwords)):
        wn = list(ngrams(words,N))
        hn = list(ngrams(hwords,N))
        cm = filter(lambda x: x in wn, hn)
        bleus += len(cm) / len(hn)
    bleus /= len(hwords)
    return bleus
    
try:
	os.remove(sys.argv[1].split(".")[0]+"_new.arff")
except OSError:
	pass
fo=open(sys.argv[1].split(".")[0]+"_new.arff","w");
with open(sys.argv[1]) as f:
    for line in f:
    	line=line[:-1]
        if (line == "@DATA"):
		header=0;
		
		fo.write(line+"\n");
		continue;
	if (header==1):
		try:
			if(line.split(" ")[0]=="@ATTRIBUTE" and line.split(" ")[1]=="accuracy"):
				fo.write("@ATTRIBUTE word_matching NUMERIC\n");
				fo.write("@ATTRIBUTE neg_word_match NUMERIC\n")
				fo.write("@ATTRIBUTE num_match NUMERIC\n")
				fo.write("@ATTRIBUTE synonym_match NUMERIC\n")
				fo.write("@ATTRIBUTE antonym_match NUMERIC\n")
				fo.write("@ATTRIBUTE wup_similarity NUMERIC\n")
		except IndexError:
			pass
		fo.write(line+"\n");
		continue;
	else:
		features=line.split(",");
		#fo.write(line);	
		id1=features[0];
		overlapMax=features[1];
		fMax=features[2];
		leskMax=features[3];
		cosineMax=features[4];
		qOverlap=features[5];
		qf=features[6];
		qlesk=features[7];
		qcosine=features[8];
		accuracy=features[9];
		ans_text=""
		expected_ans_text=""
		with open("answers.csv") as ansf:
			for l in ansf:
				l=l[:-1]
				id_ans=l.split("\t")[0]
				if(id_ans==id1):
					question_text=l.split("\t")[1]
					ans_text=l.split("\t")[2]
					expected_ans_text=l.split("\t")[3]
					'''question_text=question_text[1:-1]
					ans_text=ans_text[1:-1]
					expected_ans_text=expected_ans_text[1:-1]
					'''
					break;
		neg_words=["not","no","isn't","wasn't","don't","aren't","didn't","never","can't"];
		ans_text_tokens=nltk.word_tokenize(ans_text);
		expected_ans_text_tokens=nltk.word_tokenize(expected_ans_text);
		ans_text_pos=nltk.pos_tag(ans_text_tokens);
		expected_ans_text_pos=nltk.pos_tag(expected_ans_text_tokens);

		#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		feature_neg_match=0;
		for neg_word in neg_words:
			if neg_word in ans_text_tokens and neg_word in expected_ans_text_tokens:
					feature_neg_match+=1;
			elif neg_word in ans_text_tokens and neg_word not in expected_ans_text_tokens:
					feature_neg_match-=1;
			elif neg_word not in ans_text_tokens and neg_word in expected_ans_text_tokens:
					feature_neg_match-=1;
		#print l
		#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		feature_num_match=0;
		ans_text_pos_nums=[words for (words,pos) in ans_text_pos if pos=='CD'];
		expected_ans_text_pos_nums=[words for (words,pos) in expected_ans_text_pos if pos=='CD'];
		for w_a in ans_text_pos_nums:
				cd_present=0;
				for w_e in expected_ans_text_pos_nums:
						cd_present=1;
						if w_e==w_a:
							feature_num_match+=1;
							cd_present=0;
							break;
				if cd_present==1:
					feature_num_match-=1;
		#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		#Antonyn and Synonym features
		antonym_match=0;
		synonym_match=0;
		from nltk.stem.wordnet import WordNetLemmatizer
		from nltk.corpus import wordnet as wn
		lmtzr = WordNetLemmatizer();
		wup_cumulative=0;
		pos_list=['VB','VBG','VBD','VBN','VBP','VBZ','RB','RBR','RBS','JJ','JJR','JJS'];
		for (word,pos) in ans_text_pos:
			max_wup=0;
			word_l=lmtzr.lemmatize(word);
			for(word_e,pos_e) in expected_ans_text_pos:
				word_e_l=lmtzr.lemmatize(word_e);
				try:
					max_wup=max(max_wup,wn.synsets(word_e_l)[0].wup_similarity(wn.synsets(word_l)[0]));
				except IndexError:
					pass
			wup_cumulative+=max_wup;
			if pos in pos_list:
				word_synsets=wn.synsets(word_l);
				synonyms=list(set([lemma2.key.split('%')[0] for lemma2 in [t.lemmas[0] for t in word_synsets]]));
				antonyms=list(set([lemma2.key.split('%')[0] for lemma2 in [t.lemmas[0].antonyms()[0] for t in word_synsets if t.lemmas[0].antonyms()]]));
				for (word_e,pos_e) in expected_ans_text_pos:
					word_e_l=lmtzr.lemmatize(word_e);
					if word_e_l in synonyms:
						#check whether not is there or not
						if expected_ans_text_tokens.index(word_e)!=0 and ans_text_tokens.index(word)!=0:
							if (expected_ans_text_tokens[expected_ans_text_tokens.index(word_e)-1] in neg_words and ans_text_tokens[ans_text_tokens.index(word)-1] in neg_words) or (expected_ans_text_tokens[expected_ans_text_tokens.index(word_e)-1] not in neg_words and ans_text_tokens[ans_text_tokens.index(word)-1] not in neg_words):
								synonym_match+=1;
							else: 
								synonym_match-=1;

					elif word_e in antonyms:
						#check whether not is there or not 
						if expected_ans_text_tokens.index(word_e)!=0 and ans_text_tokens.index(word)!=0:
							if (expected_ans_text_tokens[expected_ans_text_tokens.index(word_e)-1] in neg_words and ans_text_tokens[ans_text_tokens.index(word)-1] in neg_words) or (expected_ans_text_tokens[expected_ans_text_tokens.index(word_e)-1] not in neg_words and ans_text_tokens[ans_text_tokens.index(word)-1] not in neg_words):
								antonym_match-=1;
							else: 
								antonym_match+=1;
		synonym_match=synonym_match/len(ans_text_tokens);
		antonym_match=antonym_match/len(ans_text_tokens);
		wup_cumulative=wup_cumulative/len(ans_text_tokens);
		#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
		

		fo.write(id1+","+overlapMax+","+fMax+","+leskMax+","+cosineMax+","+qOverlap+","+qf+","+qlesk+","+qcosine+","+str(word_matching(ans_text,expected_ans_text))+","+str(feature_neg_match)+","+str(feature_num_match)+","+str(synonym_match)+","+str(antonym_match)+","+str(wup_cumulative)+","+accuracy+"\n");			
		#print question_text+","+expected_ans_text+","+ans_text
