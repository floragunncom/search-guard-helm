{{/*
Includes code from the following Apache 2 licensed projects:

  - https://github.com/lalamove/helm-elasticsearch

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/}}



{{/*
Expand the name of the chart.
*/}}
{{- define "searchguard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "searchguard.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name }}
{{- end -}}

{{- define "searchguard.elk-version" -}}
{{-  .Values.common.elkversion | substr 0 1 }}
{{- end }}

{{- define "searchguard.lifecycle-cleanup-certs" -}}
exec:
  command:
    - bash
    - -c
    - |
        kubectl --namespace {{ .Release.Namespace }} patch secret {{ template "searchguard.fullname" . }}-nodes-cert-secret -p="[{\"op\": \"remove\", \"path\": \"/data/$NODE_NAME.pem\"}]" -v=5 --type json || true
        kubectl --namespace {{ .Release.Namespace }} patch secret {{ template "searchguard.fullname" . }}-nodes-cert-secret -p="[{\"op\": \"remove\", \"path\": \"/data/$NODE_NAME.key\"}]" -v=5 --type json || true

{{- end -}}

{{- define "searchguard.remove-demo-certs" -}}
exec:
  command:
    - bash
    - -c
    - | 
        shopt -s dotglob
        rm -f /usr/share/elasticsearch/config/*.pem
{{- end -}}


{{- define "searchguard.patch-node-certificates" -}}
kubectl patch secret {{ template "searchguard.fullname" . }}-nodes-cert-secret -p="{\"data\":{\"$NODE_NAME.pem\": \"$(cat /sg-nodes-certs/$NODE_NAME.pem | base64 -w0)\", \"$NODE_NAME.key\": \"$(cat /sg-nodes-certs/$NODE_NAME.key | base64 -w0)\", \"root-ca.pem\": \"$(cat /sg-nodes-certs/root-ca.pem | base64 -w0)\"}}" -v=5
{{- end -}}

{{- define "searchguard.recreate-node-certificates" -}}
kubectl get secret {{ template "searchguard.fullname" . }}-secret -o jsonpath='{.data}' | grep -qE '($NODE_NAME\.pem|$NODE_NAME\.key)'
nodes_certs_status=$?
if [ $nodes_certs_status -ne 0 ]; then
  echo "Restoring missing files $NODE_NAME.pem and $NODE_NAME.pem after container restart"
  {{ include "searchguard.patch-node-certificates" . }}  
fi
{{- end -}}



{{/*
init container template

*/}}

{{- define "searchguard.generate-certificates-init-container" -}}
{{ include "searchguard.kubectl-init-container" . | indent 0 }}
- name: searchguard-generate-certificates
  image: {{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.sgctl_base_image }}:{{ .Values.common.sgctl_version }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
{{ include "searchguard.security-context.least" . | indent 2 }}   
  volumeMounts:
    - name: kubectl
      subPath: kubectl
      mountPath: /usr/local/bin/kubectl
      readOnly: true
    - name: nodes-cert
      mountPath: /sg-nodes-certs
      readOnly: false           
  env:
    - name: NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  command:
    - bash
    - -c
    - |


        #sed -i 's/appender.rolling.layout.type = ESJsonLayout/appender.rolling.layout.type = PatternLayout/g' /usr/share/elasticsearch/config/log4j2.properties
        #sed -i '/appender.rolling.layout.type_name = server/d' /usr/share/elasticsearch/config/log4j2.properties
        #echo "" >> /usr/share/elasticsearch/config/log4j2.properties
        #echo 'appender.rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] [%node_name]%marker %.-10000m%n' >> /usr/share/elasticsearch/config/log4j2.properties
        
        if [ "$(id -u)" == "0" ]; then echo Should be run as root user; exit -1; fi 
        id -u
        set -e

        until kubectl get secrets {{ template "searchguard.fullname" . }}-admin-cert-secret; do
            echo 'Wait for Admin certificate secrets to be generated or uploaded';
            sleep 10 ;
        done

        echo "OK, {{ template "searchguard.fullname" . }}-admin-cert-secret exists now"

        until kubectl get secrets {{ template "searchguard.fullname" . }}-passwd-secret; do
          echo 'Wait for {{ template "searchguard.fullname" . }}-passwd-secret';
          sleep 10 ; 
        done

        echo "OK, {{ template "searchguard.fullname" . }}-passwd-secret exists now"



        KIBANA_ELB="$(kubectl get svc {{ template "searchguard.fullname" . }} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
        ES_ELB="$(kubectl get svc {{ template "searchguard.fullname" . }}-clients -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

        if [ -z "$KIBANA_ELB" ]; then
              KIBANA_ELB=""
        else
              KIBANA_ELB="- $KIBANA_ELB"
        fi

        if [ -z "$ES_ELB" ]; then
              ES_ELB=""
        else
              ES_ELB="- $ES_ELB"
        fi

        cat >"{{ template "searchguard.fullname" . }}-$NODE_NAME-node-cert.yml" <<EOL
        ca:
          root:
              file: root-ca.pem
              {{ if .Values.common.ca_password }}
              pkPassword: {{ .Values.common.ca_password }}
              {{ end }}
        
        defaults:
          validityDays: {{ .Values.common.tls.validity_days }}
          keysize: {{ .Values.common.tls.keysize }}
          pkPassword: none
          httpsEnabled: true
          reuseTransportCertificatesForHttp: true
        
        nodes:
          - name: $NODE_NAME
            dn: {{ .Values.common.tls.node_dn }}
            dns:
              - $NODE_NAME
              - {{ template "searchguard.fullname" . }}-discovery.{{ .Release.Namespace }}.svc
              - {{ template "searchguard.fullname" . }}-clients.{{ .Release.Namespace }}.svc
              $KIBANA_ELB
              $ES_ELB
            ip: $POD_IP
        EOL

        cat {{ template "searchguard.fullname" . }}-$NODE_NAME-node-cert.yml

        kubectl get secrets {{ template "searchguard.fullname" . }}-root-ca-secret -o jsonpath="{.data.crt\.pem}" | base64 -d > /tmp/root-ca.pem
        kubectl get secrets {{ template "searchguard.fullname" . }}-root-ca-secret -o jsonpath="{.data.key\.pem}" | base64 -d > /tmp/root-ca.key

        /usr/share/sg/tlstool/tools/sgtlstool.sh -crt -v -c "{{ template "searchguard.fullname" . }}-$NODE_NAME-node-cert.yml" -t /tmp/

        for sgfile in root-ca.pem  $NODE_NAME.key $NODE_NAME.pem 
        do
           cp -rf /tmp/$sgfile /sg-nodes-certs/
        done    
            
        {{ include "searchguard.patch-node-certificates" . }}        


  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
{{- end -}}

{{- define "searchguard.init-containers" -}}
{{ if .Values.common.init_sysctl }}
- name: init-sysctl
  image: {{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/busybox
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  command: ["sysctl", "-w", "vm.max_map_count=262144"]
  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
  securityContext:
    privileged: true
{{ end }}
{{ include "searchguard.generate-certificates-init-container" . }}
{{ if .Values.common.custom_elasticsearch_keystore.enabled }}
{{ include "searchguard.custom-elasticsearch-keystore-init-container" . }}
{{ end }}

{{- end -}}

{{- define "searchguard.authorization.apiVersion" -}}
{{- if semverCompare "<1.17.0-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{- define "searchguard.networking.apiVersion" -}}
{{- if semverCompare "<1.19.0-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{- define "searchguard.cronjob.apiVersion" -}}
{{- if semverCompare "<1.21.0-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "batch/v1beta1" -}}
{{- else -}}
{{- print "batch/v1" -}}
{{- end -}}
{{- end -}}

{{- define ".Values.kibana.storageClass" -}}
{{- if (.Values.kibana.storageClass) and not (eq .Values.kibana.storageClass "") -}}
{{- printf ".Values.kibana.storageClass" -}}
{{- else -}}
{{- printf "default" -}}
{{- end -}}
{{- end -}}

{{- define ".Values.data.storageClass" -}}
{{- if (.Values.data.storageClass) and not (eq .Values.data.storageClass "") -}}
{{- printf ".Values.data.storageClass" -}}
{{- else -}}
{{- printf "default" -}}
{{- end -}}
{{- end -}}

{{- define ".Values.client.storageClass" -}}
{{- if (.Values.client.storageClass) and not (eq .Values.client.storageClass "") -}}
{{- printf ".Values.client.storageClass" -}}
{{- else -}}
{{- printf "default" -}}
{{- end -}}
{{- end -}}

{{- define ".Values.master.storageClass" -}}
{{- if (.Values.master.storageClass) and not (eq .Values.master.storageClass "") -}}
{{- printf ".Values.master.storageClass" -}}
{{- else -}}
{{- printf "default" -}}
{{- end -}}
{{- end -}}

{{- define ".Values.common.docker_registry.imagePullSecret" -}}
{{- if .Values.common.docker_registry.imagePullSecret -}}
{{- printf ".Values.common.docker_registry.imagePullSecret" -}}
{{- else -}}
{{- printf "docker-auth" -}}
{{- end -}}
{{- end -}}

{{- define "searchguard.kubectl-image" -}}
image: {{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.kubectl_base_image }}:{{ trimPrefix "v" (split "-" .Capabilities.KubeVersion.Version)._0 }}
{{- end -}}

{{- define "searchguard.kubectl-init-container" -}}
- name: init-kubectl
{{ include "searchguard.kubectl-image" . | indent 2 }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
{{ include "searchguard.security-context.least" . | indent 2 }}
  volumeMounts:
  - name: kubectl
    mountPath: /data
  command: 
  - bash
  - -c
  - | 
      set -e

      id -u
      if [ "$(id -u)" == "0" ]; then echo Should be run as root user; exit -1; fi
      cp -v /usr/bin/kubectl /data/kubectl

{{- end -}}

{{- define "searchguard.security-context.least" -}}
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  runAsNonRoot: true
  readOnlyRootFilesystem: false
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
{{- end -}}


{{- define "searchguard.custom-elasticsearch-keystore-init-container" -}}
- name: searchguard-custom-elasticsearch-keystore
{{ if .Values.common.xpack_basic }}
  image: "{{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.elasticsearch_base_image }}:{{ .Values.common.elkversion }}-{{ .Values.common.sgversion }}"
{{ else }}
  image: "{{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.elasticsearch_base_image }}:{{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }}"
{{ end }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
{{ include "searchguard.security-context.least" . | indent 2 }}
  volumeMounts:
    - name: elasticsearch-keystore
      mountPath: /custom-elasticsearch-keystore
  env:
    - name: NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    {{- range .Values.common.custom_elasticsearch_keystore.extraEnvs }}
    {{- if .value }}
    - name: {{ .name }}
      value: {{ .value }}
    {{- else if .valueFrom }}
    - name: {{ .name }}
      valueFrom:
        secretKeyRef:
          name: {{ .valueFrom.secretKeyRef.name }}
          key: {{ .valueFrom.secretKeyRef.key }}
    {{- end }}
    {{- end }}
  command:
    - bash
    - -c
    - |
        ELASTICSEARCH_KEYSTORE=/usr/share/elasticsearch/bin/elasticsearch-keystore
        $ELASTICSEARCH_KEYSTORE create
        {{-  .Values.common.custom_elasticsearch_keystore.script | nindent 8 }}
        cp /usr/share/elasticsearch/config/elasticsearch.keystore /custom-elasticsearch-keystore

  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
{{- end -}}

{{- define "searchguard.custom-elasticsearch-keystore-volumeMounts" -}}
- name: elasticsearch-keystore
  mountPath: /usr/share/elasticsearch/config/elasticsearch.keystore
  subPath: elasticsearch.keystore
{{- end -}}





