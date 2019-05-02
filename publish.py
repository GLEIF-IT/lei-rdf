#!/opt/python3/bin/python3
import sys
from rdflib.graph import Graph
from rdflib.plugin import register
from rdflib.plugins.serializers.turtle import TurtleSerializer
from rdflib.serializer import Serializer

# Copyright (c) Adaptive, Inc 2018
# Author Pete Rivett
# Licensed under MIT License

# Reorders a specified ontology to a sequence based on a specified steering file containing a sequence of element names
# All non-specified elements remain in their original order at the end of the file

# Makes use of rdflib
# - install using pip install rdflib
# - documentation at http://xlsxwriter.readthedocs.io
# - source at https://github.com/jmcnamara/XlsxWriter

# CLI takes name of ontology file, steering file and output ontology file
# Steering file should have one entry per line starting with name of ontology e.g. L1/ or Base/
# Leading and trailing spaces are OK. Names not in the input ontology will be ignored 
if len(sys.argv) != 4:
    print("Provide name of input Turtle ontology file, steering file and output ontology file which will be overwritten")
    sys.exit()

inputfile = sys.argv[1]
configfile = sys.argv[2]
outputfile = sys.argv[3]

g = Graph()
g.parse(inputfile, format = 'ttl')

nsGleif = 'https://www.gleif.org/ontology/'
top = list(map(
  lambda name: nsGleif + name, [n.strip() for n in open(configfile)]))
def sortKey(term):
  try:
     return top.index(str(term))
  except:
     return 999

class LeiSerializer(TurtleSerializer):
  def orderSubjects(self):
    subj = super(LeiSerializer, self).orderSubjects()
    return sorted(subj, key=sortKey)
 
register('lei', Serializer, '__main__', 'LeiSerializer')

g.serialize(destination=outputfile, format='lei')

