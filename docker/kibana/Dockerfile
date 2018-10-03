#ARG ELK_VERSION

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/kibana/kibana-oss:6.4.1

# Search Guard plugin
ARG ELK_VERSION=6.4.1
ENV SG_VERSION=${ELK_VERSION}-15
RUN kibana-plugin install https://repo1.maven.org/maven2/com/floragunn/search-guard-kibana-plugin/${SG_VERSION}/search-guard-kibana-plugin-${SG_VERSION}.zip
