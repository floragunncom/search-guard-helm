FROM centos:7

RUN curl -s https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_linux-x64_bin.tar.gz | tar -C /opt -zxf -
ENV JAVA_HOME /opt/jdk-11.0.1

# Replace OpenJDK's built-in CA certificate keystore with the one from the OS
# vendor. The latter is superior in several ways.
# REF: https://github.com/elastic/elasticsearch-docker/issues/171
RUN ln -sf /etc/pki/ca-trust/extracted/java/cacerts /opt/jdk-11.0.1/lib/security/cacerts

WORKDIR /root/

RUN echo $'[kubernetes] \n\
name=Kubernetes  \n\
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64  \n\
enabled=1  \n\
gpgcheck=1  \n\
repo_gpgcheck=1  \n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'  > /etc/yum.repos.d/kubernetes.repo

RUN yum update -y && \
    yum install -y wget ca-certificates openssl unzip bash kubectl && \
    yum clean all

ARG ELK_VERSION
ARG SG_VERSION
ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}

RUN wget https://oss.sonatype.org/content/repositories/releases/com/floragunn/search-guard-6/$SG_FULLVERSION/search-guard-6-$SG_FULLVERSION-sgadmin-standalone.zip
RUN unzip search-guard-6-$SG_FULLVERSION-sgadmin-standalone.zip -d sgadmin/
RUN rm -rf search-guard-6-$SG_FULLVERSION-sgadmin-standalone.zip

RUN wget https://repo1.maven.org/maven2/com/floragunn/search-guard-tlstool/1.6/search-guard-tlstool-1.6.zip
RUN unzip search-guard-tlstool-1.6 -d tlstool/
RUN rm -rf search-guard-tlstool-1.6.zip

RUN echo '/root/sgadmin/tools/sgadmin.sh -h $DISCOVERY_SERVICE -cd /root/sgconfig -icl -key /root/sgcerts/admin_cert_key.pem -cert /root/sgcerts/admin_cert.pem -cacert /root/sgcerts/ca_cert.pem -nhnv' > /root/sgadmin_update.sh
RUN echo '/root/sgadmin/tools/sgadmin.sh -h $DISCOVERY_SERVICE -icl -key /root/sgcerts/admin_cert_key.pem -cert /root/sgcerts/admin_cert.pem -cacert /root/sgcerts/ca_cert.pem -nhnv "$@"' > /root/sgadmin_generic.sh
RUN chmod +x /root/sgadmin_update.sh /root/sgadmin_generic.sh /root/sgadmin/tools/sgadmin.sh

RUN echo 'echo "To use sgadmin run: /root/sgadmin/tools/sgadmin.sh <OPTIONS>"' >> /root/.bashrc
RUN echo 'echo "On K8s/Helm run: /root/sgadmin/tools/sgadmin.sh -h $DISCOVERY_SERVICE -cd /root/sgconfig -icl -key /root/sgcerts/admin_cert_key.pem -cert /root/sgcerts/admin_cert.pem -cacert /root/sgcerts/ca_cert.pem -nhnv"' >> /root/.bashrc
RUN echo 'echo "  or run /root/sgadmin_update.sh"' >> /root/.bashrc
RUN echo 'echo "  or run /root/sgadmin_generic.sh <OPTIONS>"' >> /root/.bashrc

#ENTRYPOINT [ "/root/sgadmin/tools/sgadmin.sh" ]
CMD tail -f /dev/null