ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana${ELK_FLAVOUR}:${ELK_VERSION}

# Search Guard plugin
ARG SG_KIBANA_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR

ENV FULL_SG_VERSION=${ELK_VERSION}-${SG_KIBANA_VERSION}
RUN kibana-plugin install https://github.com/floragunncom/search-guard-kibana-plugin/releases/download/v${FULL_SG_VERSION}/searchguard-kibana-${FULL_SG_VERSION}.zip

ADD kibana-docker-sg /usr/local/bin/kibana-docker