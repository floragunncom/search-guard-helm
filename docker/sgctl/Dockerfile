ARG JAVA_VERSION
FROM eclipse-temurin:${JAVA_VERSION}-jammy

ARG TLS_TOOL_VERSION=1.9.2

RUN groupadd -g 1000 sg && \
    adduser --uid 1000 --gid 1000 --home /usr/share/sg sg && \
    chown -R 1000:0 /usr/share/sg

RUN apt-get -y -qq update
#https://github.com/QuinnJensen/nlan-docker/commit/abd8d824e3d02f3ef184a9dfd96fa0839cca7ee6
RUN ln -s /usr/bin/dpkg-split /usr/sbin/
RUN ln -s /usr/bin/dpkg-deb /usr/sbin/
RUN ln -s /bin/rm /usr/sbin/
RUN ln -s /bin/tar /usr/sbin/
RUN apt-get -y -qq install netcat curl wget ca-certificates unzip openssl bash jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ARG SGCTL_VERSION

WORKDIR /usr/share/sg

RUN mkdir sgctl
RUN wget -nv https://maven.search-guard.com/search-guard-flx-release/com/floragunn/sgctl/${SGCTL_VERSION}/sgctl-${SGCTL_VERSION}.sh -O sgctl/sgctl.sh
RUN chmod +x sgctl/sgctl.sh

RUN wget -nv https://maven.search-guard.com//search-guard-tlstool/com/floragunn/search-guard-tlstool/${TLS_TOOL_VERSION}/search-guard-tlstool-${TLS_TOOL_VERSION}.zip

RUN unzip search-guard-tlstool-${TLS_TOOL_VERSION}.zip -d tlstool/
RUN rm -rf search-guard-tlstool-${TLS_TOOL_VERSION}.zip

USER sg

CMD tail -f /dev/null