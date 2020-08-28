ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/elasticsearch/elasticsearch${ELK_FLAVOUR}:${ELK_VERSION}

# Search Guard plugin
ARG SG_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR

RUN echo $ELK_VERSION | cut -c1-1 > /major
ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}
RUN elasticsearch-plugin install --batch https://maven.search-guard.com/search-guard-suite-release/com/floragunn/search-guard-suite-plugin/${SG_FULLVERSION}/search-guard-suite-plugin-${SG_FULLVERSION}.zip \
    && chmod +x plugins/search-guard-$(cat /major)/tools/*.sh

#RUN plugins/search-guard-$(cat /major)/tools/install_demo_configuration.sh -yic