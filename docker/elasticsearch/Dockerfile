# https://github.com/elastic/elasticsearch-docker
FROM docker.elastic.co/elasticsearch/elasticsearch-oss:6.4.1

# Search Guard plugin
# https://docs.search-guard.com/latest/search-guard-versions
ARG ELK_VERSION=6.4.1
ARG SG_VERSION=23.1
ARG TC_NATIVE_VERSION="1.0.2n-static-2.0.7.Final-fedora-linux-x86_64"
ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}
RUN elasticsearch-plugin install --batch com.floragunn:search-guard-6:${SG_FULLVERSION} \
    && chmod +x plugins/search-guard-6/tools/*.sh

RUN plugins/search-guard-6/tools/install_demo_configuration.sh -yic

#tcnative/openssl
RUN wget -P /usr/share/elasticsearch/plugins/search-guard-6 "https://bintray.com/floragunncom/netty-tcnative/download_file?file_path=netty-tcnative-openssl-${TC_NATIVE_VERSION}.jar"
