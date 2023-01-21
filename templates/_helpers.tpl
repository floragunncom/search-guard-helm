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


{{/*
init container template

*/}}

{{- define "searchguard.generate-certificates-init-container" -}}
{{ include "searchguard.kubectl-init-container" . | indent 0 }}
- name: searchguard-generate-certificates
  image: {{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.sgctl_base_image }}:{{ .Values.common.sgctl_version }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  volumeMounts:
    - name: kubectl
      subPath: kubectl
      mountPath: /usr/local/bin/kubectl
      readOnly: true
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
        set -e

        #cp /usr/bin/kubectl /kubectl/kubectl
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
        
        defaults:
          validityDays: 365
          pkPassword: none
          httpsEnabled: true
          reuseTransportCertificatesForHttp: true
          verifyHostnames: true
          resolveHostnames: true
          nodesDn:
            - CN=*-esnode,OU=Ops,O=Example Com\, Inc.,DC=example,DC=com
        
        nodes:
          - name: $NODE_NAME
            dn: CN=$NODE_NAME-esnode,OU=Ops,O=Example Com\, Inc.,DC=example,DC=com
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

        kubectl patch secret {{ template "searchguard.fullname" . }}-nodes-cert-secret -p="{\"data\":{\"$NODE_NAME.pem\": \"$(cat /tmp/$NODE_NAME.pem | base64 -w0)\", \"$NODE_NAME.key\": \"$(cat /tmp/$NODE_NAME.key | base64 -w0)\", \"root-ca.pem\": \"$(cat /tmp/root-ca.pem | base64 -w0)\"}}" -v=5
        #cat /tmp/*snippet.yml

  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
{{- end -}}

{{- define "searchguard.master-wait-container" -}}
- name: searchguard-master-wait-container
  image: {{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.sgctl_base_image }}:{{ .Values.common.sgctl_version }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  volumeMounts:
    - name: kubectl
      mountPath: /kubectl
  command:
    - bash
    - -c
    - |
        set -e
        echo "Checking Client and Data nodes startup"

        echo "Checking that Client ES nodes with old version are going to be replaced"
{{ if .Values.common.xpack_basic }}
        while kubectl get pods --selector=role=client -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:true' | grep -v "{{ .Values.common.elkversion }}-{{ .Values.common.sgversion }}"; do
            echo "Waiting for all ES client nodes to upgrade to version {{ .Values.common.elkversion }}-{{ .Values.common.sgversion }} version";
            sleep 10;
        done
{{ else }}
        while kubectl get pods --selector=role=client -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:true' | grep -v "{{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }}"; do
            echo "Waiting for all ES client nodes to upgrade to {{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }} version";
            sleep 10;
        done
{{ end }}
        echo "Checking that all Client nodes with new version have been already started"

        while kubectl get pods --selector=role=client -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:false'; do
            echo "Waiting for all ES client nodes to start with new version";
            sleep 10;
        done
        echo "Checking that Data ES nodes with old version are going to be replaced"
{{ if .Values.common.xpack_basic }}
        while kubectl get pods --selector=role=data -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:true' |  grep -v "{{ .Values.common.elkversion }}-{{ .Values.common.sgversion }}"; do
            echo "Waiting for all ES client nodes to upgrade to version {{ .Values.common.elkversion }}-{{ .Values.common.sgversion }} version";
            sleep 10;
        done
{{ else }}
        while kubectl get pods --selector=role=data -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:true' |  grep -v "{{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }}"; do
            echo "Waiting for all ES client nodes to upgrade to version {{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }} version";
            sleep 10;
        done
{{ end }}
        echo "Checking that all Data nodes with new version have been already started"

        while kubectl get pods --selector=role=data -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:false'; do
            echo "Waiting for all ES client nodes to start with new version";
            sleep 10;
        done

        RET=$?
        echo "Result $RET"
        exit $RET

  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
{{- end -}}


{{- define "searchguard.kibana-wait-container" -}}
- name: searchguard-kibana-wait-container
  image: {{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.sgctl_base_image }}:{{ .Values.common.sgctl_version }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  volumeMounts:
    - name: kubectl
      mountPath: /kubectl
  command:
    - bash
    - -c
    - |
        set -e
        echo "Checking Master nodes startup"

        echo "Checking that Master ES nodes with old version are going to be replaced"
{{ if .Values.common.xpack_basic }}
        while kubectl get pods --selector=role=master -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:true' | grep -v "{{ .Values.common.elkversion }}-{{ .Values.common.sgversion }}"; do
            echo "Waiting for all ES Master nodes to upgrade to version {{ .Values.common.elkversion }}-{{ .Values.common.sgversion }} version";
            sleep 10;
        done
{{ else }}
        while kubectl get pods --selector=role=master -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:true' | grep -v "{{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }}"; do
            echo "Waiting for all ES Master nodes to upgrade to version {{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }} version";
            sleep 10;
        done
{{ end }}
        echo "Checking that all Master nodes with new version have been already started"

        while kubectl get pods --selector=role=master -o jsonpath='{range .items[*]}{.status.containerStatuses[*]}{"\n"}{end}'|sed 's/"//g'|grep 'ready:false'; do
            echo "Waiting for all ES Master nodes to start with  new version";
            sleep 10;
        done

        RET=$?
        echo "Result $RET"
        exit $RET

  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
{{- end -}}


{{- define "searchguard.init-containers" -}}
- name: init-sysctl
  image: {{ .Values.common.images.repository }}/busybox
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

{{ include "searchguard.generate-certificates-init-container" . }}


{{- if .Values.common.plugins }}
- name: es-plugin-install
{{ if .Values.common.xpack_basic }}
  image: "{{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.elasticsearch_base_image }}:{{ .Values.common.elkversion }}-{{ .Values.common.sgversion }}"
{{ else }}
  image: "{{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.elasticsearch_base_image }}:{{ .Values.common.elkversion }}-oss-{{ .Values.common.sgversion }}"
{{ end }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  securityContext:
    capabilities:
      add:
        - IPC_LOCK
        - SYS_RESOURCE
  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
  command:
    - "sh"
    - "-c"
    - "{{- range .Values.common.plugins }}elasticsearch-plugin install -b {{ . }};{{- end }} true"
  env:
  - name: NODE_NAME
    value: es-plugin-install
  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
  volumeMounts:
  - mountPath: /storage/
    name: storage
  - mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
    name: config
    subPath: elasticsearch.yml
{{- end }}
- name: permissions
{{- if not .sg_specific }}
  image: {{ .Values.common.images.repository }}/library/busybox
{{- else }}
  image: docker.io/library/busybox
{{- end }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  command: ["sh", "-c", "chown -R 1000: /storage/; true"]
  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
  volumeMounts:
  - mountPath: /storage
    name: storage
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
image: {{ .Values.common.images.repository }}/{{ .Values.common.images.provider }}/{{ .Values.common.images.kubectl_base_image }}:{{ trimPrefix "v" .Capabilities.KubeVersion.Version  }}
{{- end -}}

{{- define "searchguard.kubectl-init-container" -}}
- name: init-kubectl
{{ include "searchguard.kubectl-image" . | indent 2 }}
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  volumeMounts:
  - name: kubectl
    mountPath: /data
  command: ["cp", "/usr/bin/kubectl", "/data/kubectl"]
{{- end -}}