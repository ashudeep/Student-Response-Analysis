from __future__ import division
from xml.etree.ElementTree import ElementTree
from xml.etree.cElementTree import parse as xmlparse


def clean(word):
    return word.strip(",. ")
    
def word_matching(text, entailment):
    words = [clean(x) for x in text.lower().split()]
    hwords = [clean(x) for x in entailment.lower().split()]
    intext = 0
    for h in hwords:
        if h in words:
            intext += 1

    p = float(intext) / len(hwords)
    return p
        
def parse_xml(fileh):
    tree = ElementTree()
    tree.parse(fileh)
    parsed = {}
    for pair in list(tree.findall('pair')):
        attrib = pair.attrib
        t = pair.find('t').text
        h = pair.find('h').text
        parsed[attrib['id']] = (attrib,t,h)
    return parsed

def traverse(tree, function, threshold):
    print "ranked: no"
    for i,(a,t,h) in tree.items():
        #c = a['entailment'] == 'YES'
        print i,
        if function(t,h) > threshold:
            print 'YES'
        else:
            print 'NO'

if __name__ == '__main__':
    import sys 
    data = parse_xml(sys.argv[1])
    traverse(data, word_matching, float(sys.argv[2]))
