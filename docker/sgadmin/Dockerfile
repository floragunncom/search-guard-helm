FROM centos:7

ARG TLS_TOOL_VERSION=1.8
ARG JAVA_VERSION=12

WORKDIR /root/

RUN echo $'[kubernetes] \n\
name=Kubernetes  \n\
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64  \n\
enabled=1  \n\
gpgcheck=1  \n\
repo_gpgcheck=1  \n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'  > /etc/yum.repos.d/kubernetes.repo

RUN echo $'[AdoptOpenJDK] \n\      
name=AdoptOpenJDK \n\
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/7/x86_64 \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public' > /etc/yum.repos.d/adoptopenjdk.repo

RUN yum update -y && \
    yum install -y wget ca-certificates openssl unzip bash kubectl adoptopenjdk-${JAVA_VERSION}-hotspot && \
    yum clean all

ARG ELK_VERSION
ARG SG_VERSION
ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}
RUN echo $ELK_VERSION | cut -c1-1 > /major


RUN wget https://maven.search-guard.com/search-guard-suite-release/com/floragunn/search-guard-suite-plugin/${SG_FULLVERSION}/search-guard-suite-plugin-${SG_FULLVERSION}-sgadmin-standalone.zip
RUN unzip search-guard-suite-plugin-${SG_FULLVERSION}-sgadmin-standalone.zip -d sgadmin/
RUN rm -rf search-guard-suite-plugin-${SG_FULLVERSION}-sgadmin-standalone.zip

RUN wget https://maven.search-guard.com/search-guard-tlstool/${TLS_TOOL_VERSION}/search-guard-tlstool-${TLS_TOOL_VERSION}.zip

RUN unzip search-guard-tlstool-${TLS_TOOL_VERSION}.zip -d tlstool/
RUN rm -rf search-guard-tlstool-${TLS_TOOL_VERSION}.zip

#ENTRYPOINT [ "/root/sgadmin/tools/sgadmin.sh" ]
CMD tail -f /dev/null