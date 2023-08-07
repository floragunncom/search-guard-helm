ARG SG_KIBANA_VERSION
ARG ELK_VERSION


# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana:${ELK_VERSION} as base

# Search Guard plugin
ARG SG_KIBANA_VERSION
ARG ELK_VERSION
ENV FULL_SG_VERSION=${SG_KIBANA_VERSION}-es-${ELK_VERSION}

FROM base as flx
RUN kibana-plugin install https://maven.search-guard.com/search-guard-flx-release/com/floragunn/search-guard-flx-kibana-plugin/${FULL_SG_VERSION}/search-guard-flx-kibana-plugin-${FULL_SG_VERSION}.zip

