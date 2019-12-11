FROM chrsep/alpine-java-python

RUN apk update && apk upgrade && apk add bash
RUN apk add curl && apk add zip

RUN pip3 install rdflib 

RUN cd ~ && mkdir saxon && cd saxon && \
    curl -O http://saxonica.com/download/SaxonEE9-9-1-5J.zip && \
    unzip SaxonEE9-9-1-5J.zip

ENV SAXON_HOME=/root/saxon

ADD . /app
