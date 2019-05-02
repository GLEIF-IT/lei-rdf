ls -1 ontology/ | grep ttl | cut -d '.' -f 1 | while read ontology ; do python publish.py ontology/$ontology.ttl publishorder/$ontology.txt target/$ontology.ttl ; done
ls -1 ontology/ | grep ttl | cut -d '.' -f 1 | while read ontology ; do java -jar ~/.m2/repository/es/oeg/widoco/1.4.9/widoco-1.4.9-launcher.jar -ontFile target/$ontology.ttl -outFolder target/$ontology -rewriteAll ; done
ls -1 ontology/ | grep ttl | cut -d '.' -f 1 | while read ontology ; do mv target/$ontology.ttl target/$ontology/ontology.ttl ; done
ls -1 ontology/ | grep ttl | cut -d '.' -f 1 | while read ontology ; do sed -E -i ".bak" "/#description|#introduction|#references/d" target/$ontology/index-en.html ; done

