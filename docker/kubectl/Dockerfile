FROM ubuntu:20.04

# Contains code from https://github.com/bitnami/bitnami-docker-kubectl/blob/main/1.23/debian-10/Dockerfile
# under the Apache 2 License
# Credits: Bitnami

RUN groupadd -g 1000 sg && \
    adduser --uid 1000 --gid 1000 --home /usr/share/sg sg && \
    chown -R 1000:0 /usr/share/sg

RUN apt-get -y -qq update 
#https://github.com/QuinnJensen/nlan-docker/commit/abd8d824e3d02f3ef184a9dfd96fa0839cca7ee6
RUN ln -s /usr/bin/dpkg-split /usr/sbin/
RUN ln -s /usr/bin/dpkg-deb /usr/sbin/
RUN ln -s /bin/rm /usr/sbin/
RUN ln -s /bin/tar /usr/sbin/
RUN apt-get -y -qq install netcat ca-certificates curl gzip jq procps tar wget apt-transport-https gnupg

ARG KUBECTL_VERSION


ARG TARGETPLATFORM

RUN ARCH=$(echo ${TARGETPLATFORM} | cut -f2 -d '/') && \
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/bin/kubectl && \
    kubectl version --client


RUN apt-get --purge -y -qq remove apt-transport-https gnupg ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives 

USER sg
ENTRYPOINT [ "kubectl" ]
CMD [ "--help" ]