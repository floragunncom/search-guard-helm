ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/elasticsearch/elasticsearch${ELK_FLAVOUR}:${ELK_VERSION}

# Search Guard plugin
ARG SG_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR
#ARG TC_NATIVE_VERSION="1.0.2n-static-2.0.7.Final-fedora-linux-x86_64"

ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}
RUN elasticsearch-plugin install --batch com.floragunn:search-guard-6:${SG_FULLVERSION} \
    && chmod +x plugins/search-guard-6/tools/*.sh

RUN plugins/search-guard-6/tools/install_demo_configuration.sh -yic

#tcnative/openssl
#RUN wget -P /usr/share/elasticsearch/plugins/search-guard-6 "https://bintray.com/floragunncom/netty-tcnative/download_file?file_path=netty-tcnative-openssl-${TC_NATIVE_VERSION}.jar"
