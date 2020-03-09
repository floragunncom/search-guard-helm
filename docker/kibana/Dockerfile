ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana${ELK_FLAVOUR}:${ELK_VERSION}

# Search Guard plugin
ARG SG_KIBANA_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR
ARG OPTIMIZE=""
ARG ALLOW_ROOT=""

ENV FULL_SG_VERSION=${ELK_VERSION}-${SG_KIBANA_VERSION}
#RUN echo $ELK_VERSION | cut -c1-1 > /major
RUN kibana-plugin install https://releases.floragunn.com/search-guard-kibana-plugin-7/${FULL_SG_VERSION}/search-guard-kibana-plugin-7-${FULL_SG_VERSION}.zip ${OPTIMIZE} ${ALLOW_ROOT}
