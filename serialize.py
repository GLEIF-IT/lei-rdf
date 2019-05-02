from rdflib.graph import Graph
from rdflib.plugin import register
from rdflib.plugins.serializers.turtle import TurtleSerializer
from rdflib.serializer import Serializer

g = Graph()
g.parse('ontology/L1.ttl', format = 'ttl')

nsGleifL1 = 'https://www.gleif.org/ontology/L1/'
top = list(map(
  lambda name: nsGleifL1 + name, [ 
    "LEI", 
    "LegalEntityIdentifier" 
  ]))
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

g.serialize(destination='pub-l1.ttl', format='lei')

