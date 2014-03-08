from __future__ import division
from xml.etree.ElementTree import ElementTree
from xml.etree.cElementTree import parse as xmlparse


#preprocessed_data = parse_preprocessed_xml('rte2_dev_data/RTE2_dev.preprocessed.xml')
#data = parse_xml('rte2_dev_data/RTE2_dev.xml')

def clean(word):
    return word.strip(",. ")
    
def lemma_matching(text, hypothesis):
    lemmastext = [(n.lemma,n.postag) for s in text for n in s.nodes if n.isWord]
    lemmashyp = [(n.lemma,n.postag) for s in hypothesis for n in s.nodes if n.isWord]
    hypintext = filter(lambda x: x in lemmastext, lemmashyp)
    p = float(len(hypintext)) / len(lemmashyp)
    return p

class Pair(object):
    def __init__(self, etree):
        self.id = etree.attrib['id'].strip()
        self.tast = etree.attrib['task'].strip()
        self.text = [Sentence(s) for s in etree.iterfind('text/sentence')]
        self.hypothesis = [Sentence(s) for s in etree.iterfind('hypothesis/sentence')]
        self.entailment = etree.attrib['entailment']

class Sentence(object): # list of nodes
    def __init__(self, etree):
        self.serial = etree.attrib['serial'].strip()
        self.nodes = [Node(n) for n in etree.iterfind('node')]

class Node(object):
    def __init__(self, etree):
        self.id = etree.attrib['id']
        if self.id[0] == 'E': # artificial node
            self.isWord = False
        else:
            self.isWord = True
            self.word = etree.findtext('word').strip()
            self.lemma = etree.findtext('lemma').strip()
            self.postag = etree.findtext('pos-tag').strip()
            self.relation = etree.findtext('relation')
            if self.relation: self.relations = self.relation.strip()

def parse_preprocessed_xml(fileh):
    pair = None
    etree = xmlparse(fileh)
    pairs = []
    for pair in etree.iterfind('pair'):
        pairs.append(Pair(pair))
    return pairs



def traverse_preprocessed(pairs, function,threshold):
    correct = 0
    print "ranked: no"    
    for pair in pairs:
        print pair.id,
        if function(pair.text, pair.hypothesis) > threshold:
            print 'YES'
        else:
            print 'NO'


if __name__ == '__main__':
    import sys
    data =parse_preprocessed_xml(sys.argv[1])
    traverse_preprocessed(data, lemma_matching, float(sys.argv[2]))
