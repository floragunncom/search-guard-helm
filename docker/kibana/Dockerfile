ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana${ELK_FLAVOUR}:${ELK_VERSION}

# Search Guard plugin
ARG SG_KIBANA_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR
ARG OPTIMIZE=""

ENV FULL_SG_VERSION=${ELK_VERSION}-${SG_KIBANA_VERSION}
RUN kibana-plugin install https://repo1.maven.org/maven2/com/floragunn/search-guard-kibana-plugin/${FULL_SG_VERSION}/search-guard-kibana-plugin-${FULL_SG_VERSION}.zip ${OPTIMIZE}
