ARG ES_VERSION

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana:${ES_VERSION} as base

USER root
RUN if ! command -v pgrep >/dev/null 2>&1; then \
      echo "Installing procps-ng for pgrep..."; \
      microdnf install -y procps-ng && microdnf clean all; \
    fi
USER 1000


# Search Guard plugin
ARG SG_VERSION
ARG ES_VERSION
ENV FULL_SG_VERSION=${SG_VERSION}-es-${ES_VERSION}

FROM base as flx
ARG TARGETARCH
COPY build_arm64_node.sh /tmp/
ENV FULL_SG_VERSION=${SG_VERSION}-es-${ES_VERSION}
ARG SG_URL=https://maven.search-guard.com/search-guard-flx-release/com/floragunn/search-guard-flx-kibana-plugin/${FULL_SG_VERSION}/search-guard-flx-kibana-plugin-${FULL_SG_VERSION}.zip
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      kibana-plugin install $SG_URL || { exit_code=$?; [ $exit_code -eq 255 ] && /tmp/build_arm64_node.sh $SG_URL || exit $exit_code; } ;\
      else \
      kibana-plugin install $SG_URL; \
    fi