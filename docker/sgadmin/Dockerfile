FROM centos:7

WORKDIR /root/

RUN echo $'[kubernetes] \n\
name=Kubernetes  \n\
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64  \n\
enabled=1  \n\
gpgcheck=1  \n\
repo_gpgcheck=1  \n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'  > /etc/yum.repos.d/kubernetes.repo

RUN yum update -y && \
    yum install -y which wget ca-certificates openssl unzip bash kubectl java-1.8.0-openjdk && \
    yum clean all

ARG ELK_VERSION
ARG SG_VERSION
ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}

RUN wget https://oss.sonatype.org/content/repositories/releases/com/floragunn/search-guard-5/$SG_FULLVERSION/search-guard-5-$SG_FULLVERSION-sgadmin-standalone.zip
RUN unzip search-guard-5-$SG_FULLVERSION-sgadmin-standalone.zip -d sgadmin/
RUN rm -rf search-guard-5-$SG_FULLVERSION-sgadmin-standalone.zip

RUN wget https://repo1.maven.org/maven2/com/floragunn/search-guard-tlstool/1.6/search-guard-tlstool-1.6.zip
RUN unzip search-guard-tlstool-1.6 -d tlstool/
RUN rm -rf search-guard-tlstool-1.6.zip

#ENTRYPOINT [ "/root/sgadmin/tools/sgadmin.sh" ]
CMD tail -f /dev/null