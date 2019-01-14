ARG ELK_VERSION
ARG ELK_FLAVOUR

# https://github.com/elastic/kibana-docker
FROM docker.elastic.co/elasticsearch/elasticsearch${ELK_FLAVOUR}:${ELK_VERSION}

# Search Guard plugin
ARG SG_VERSION
ARG ELK_VERSION
ARG ELK_FLAVOUR
#ARG TC_NATIVE_VERSION="1.0.2n-static-2.0.7.Final-fedora-linux-x86_64"

ENV SG_FULLVERSION=${ELK_VERSION}-${SG_VERSION}
RUN elasticsearch-plugin install --batch com.floragunn:search-guard-5:${SG_FULLVERSION} \
    && chmod +x plugins/search-guard-5/tools/*.sh

RUN plugins/search-guard-5/tools/install_demo_configuration.sh -y

WORKDIR plugins/search-guard-5

ENV LDAP_VERSION 5.0-14
ENV LDAP_R releases

ENV KERBEROS_VERSION 5.0-4
ENV KERBEROS_R releases

ENV DLSFLS_VERSION 5.3-10
ENV DLSFLS_R releases

ENV AUDITLOG_VERSION 5.3-7
ENV AUDITLOG_R releases

ENV JWT_VERSION 5.0-7
ENV JWT_R releases

ENV RESTAPI_VERSION 5.3-6
ENV RESTAPI_R releases

ENV MT_VERSION 5.4-5
ENV MT_R releases

# LDAP
RUN wget "https://oss.sonatype.org/service/local/repositories/$LDAP_R/content/com/floragunn/dlic-search-guard-authbackend-ldap/$LDAP_VERSION/dlic-search-guard-authbackend-ldap-$LDAP_VERSION-jar-with-dependencies.jar" --content-disposition  > /dev/null 2>&1

# KERBEROS
RUN wget "https://oss.sonatype.org/service/local/repositories/$KERBEROS_R/content/com/floragunn/dlic-search-guard-auth-http-kerberos/$KERBEROS_VERSION/dlic-search-guard-auth-http-kerberos-$KERBEROS_VERSION-jar-with-dependencies.jar" --content-disposition  > /dev/null 2>&1

# DLS FLS
RUN wget "https://oss.sonatype.org/service/local/repositories/$DLSFLS_R/content/com/floragunn/dlic-search-guard-module-dlsfls/$DLSFLS_VERSION/dlic-search-guard-module-dlsfls-$DLSFLS_VERSION-jar-with-dependencies.jar" --content-disposition  > /dev/null 2>&1

# AUDITLOGGING
RUN wget "https://oss.sonatype.org/service/local/repositories/$AUDITLOG_R/content/com/floragunn/dlic-search-guard-module-auditlog/$AUDITLOG_VERSION/dlic-search-guard-module-auditlog-$AUDITLOG_VERSION-jar-with-dependencies.jar" --content-disposition  > /dev/null 2>&1

# JWT
RUN wget "https://oss.sonatype.org/service/local/repositories/$JWT_R/content/com/floragunn/dlic-search-guard-auth-http-jwt/$JWT_VERSION/dlic-search-guard-auth-http-jwt-$JWT_VERSION-jar-with-dependencies.jar" --content-disposition  > /dev/null 2>&1

# REST API
RUN wget "https://oss.sonatype.org/service/local/repositories/$RESTAPI_R/content/com/floragunn/dlic-search-guard-rest-api/$RESTAPI_VERSION/dlic-search-guard-rest-api-$RESTAPI_VERSION-jar-with-dependencies.jar" --content-disposition  > /dev/null 2>&1

# MULTI TENANCY
RUN wget "https://oss.sonatype.org/service/local/repositories/$MT_R/content/com/floragunn/dlic-search-guard-module-kibana-multitenancy/$MT_VERSION/dlic-search-guard-module-kibana-multitenancy-$MT_VERSION-jar-with-dependencies.jar" --content-disposition  > /dev/null 2>&1

WORKDIR /usr/share/elasticsearch


#tcnative/openssl
#RUN wget -P /usr/share/elasticsearch/plugins/search-guard-5 "https://bintray.com/floragunncom/netty-tcnative/download_file?file_path=netty-tcnative-openssl-${TC_NATIVE_VERSION}.jar"
