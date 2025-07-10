ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana${ELK_FLAVOUR}:${ELK_VERSION} as base

USER root
RUN if ! command -v pgrep >/dev/null 2>&1; then \
      echo "Installing procps-ng for pgrep..."; \
      microdnf install -y procps-ng && microdnf clean all; \
    fi
USER 1000


# Search Guard plugin
ARG SG_KIBANA_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR
ARG SG_FLAVOUR

FROM base as non-flx
ENV FULL_SG_VERSION=${ELK_VERSION}-${SG_KIBANA_VERSION}
RUN kibana-plugin install https://maven.search-guard.com/search-guard-kibana-plugin-release/com/floragunn/search-guard-kibana-plugin/${FULL_SG_VERSION}/search-guard-kibana-plugin-${FULL_SG_VERSION}.zip

FROM base as flx
ARG TARGETARCH
COPY build_arm64_node.sh /tmp/
ENV FULL_SG_VERSION=${SG_KIBANA_VERSION}-es-${ELK_VERSION}
ARG SG_URL=https://maven.search-guard.com/search-guard-flx-release/com/floragunn/search-guard-flx-kibana-plugin/${FULL_SG_VERSION}/search-guard-flx-kibana-plugin-${FULL_SG_VERSION}.zip
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      kibana-plugin install $SG_URL || { exit_code=$?; [ $exit_code -eq 255 ] && /tmp/build_arm64_node.sh $SG_URL || exit $exit_code; } ;\
      else \
      kibana-plugin install $SG_URL; \
    fi