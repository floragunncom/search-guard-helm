ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/elasticsearch/elasticsearch${ELK_FLAVOUR}:${ELK_VERSION} as base

ARG ELK_VERSION
ARG INSTALL_DEFAULT_PLUGINS="false"

# Install repository-azure repository-gcs repository-hdfs analysis-icu plugins analysis-phonetic plugins
# This is optional and can be safely removed or commented out if those plugin are not needed
RUN if [ "$(echo $ELK_VERSION | cut -c1-1)" == "7" ] && [ "$INSTALL_DEFAULT_PLUGINS" == "true" ]; then for plugin in repository-s3 repository-azure repository-gcs repository-hdfs analysis-icu analysis-phonetic; do \
    bin/elasticsearch-plugin install --verbose --batch "https://artifacts.elastic.co/downloads/elasticsearch-plugins/${plugin}/${plugin}-${ELK_VERSION}.zip"; \
    done; fi
# End install optional plugins


# Search Guard plugin
ARG SG_VERSION
ARG ELK_FLAVOUR
ARG SG_FLAVOUR

FROM base as non-flx
RUN echo $ELK_VERSION | cut -c1-1 > /major
ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}
RUN elasticsearch-plugin install --batch https://maven.search-guard.com/search-guard-suite-release/com/floragunn/search-guard-suite-plugin/${SG_FULLVERSION}/search-guard-suite-plugin-${SG_FULLVERSION}.zip \
    && chmod +x plugins/search-guard-$(cat /major)/tools/*.sh

FROM base as flx
ENV SG_FULLVERSION=${SG_VERSION}-es-${ELK_VERSION}
RUN elasticsearch-plugin install --batch https://maven.search-guard.com/search-guard-flx-release/com/floragunn/search-guard-flx-elasticsearch-plugin/${SG_FULLVERSION}/search-guard-flx-elasticsearch-plugin-${SG_FULLVERSION}.zip
RUN if [ -f /usr/share/elasticsearch/plugins/search-guard-flx/tools/sgctl.sh ];then chmod +x /usr/share/elasticsearch/plugins/search-guard-flx/tools/sgctl.sh; fi
