ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana${ELK_FLAVOUR}:${ELK_VERSION} as base

# Search Guard plugin
ARG SG_KIBANA_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR
ARG SG_FLAVOUR

FROM base as non-flx
ENV FULL_SG_VERSION=${ELK_VERSION}-${SG_KIBANA_VERSION}
RUN kibana-plugin install https://maven.search-guard.com/search-guard-kibana-plugin-release/com/floragunn/search-guard-kibana-plugin/${FULL_SG_VERSION}/search-guard-kibana-plugin-${FULL_SG_VERSION}.zip

FROM base as flx
ENV FULL_SG_VERSION=${SG_KIBANA_VERSION}-es-${ELK_VERSION}
RUN kibana-plugin install https://maven.search-guard.com/search-guard-flx-release/com/floragunn/search-guard-flx-kibana-plugin/${FULL_SG_VERSION}/search-guard-flx-kibana-plugin-${FULL_SG_VERSION}.zip

