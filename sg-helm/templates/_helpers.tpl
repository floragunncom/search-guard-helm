{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name }}
{{- end -}}

{{- define "lifecycle-cleanup-certs" -}}
exec:
  command:
    - sh
    - -c
    - |
        #!/usr/bin/env bash +e
        kubectl patch secret {{ template "fullname" . }}-nodes-cert-secret -p="[{\"op\": \"remove\", \"path\": \"/data/$NODE_NAME.pem\"}]" -v=5 --type json || true
        kubectl patch secret {{ template "fullname" . }}-nodes-cert-secret -p="[{\"op\": \"remove\", \"path\": \"/data/$NODE_NAME.key\"}]" -v=5 --type json || true
{{- end -}}

{{- define "remove-demo-certs" -}}
exec:
  command:
    - sh
    - -c
    - |
        #!/usr/bin/env bash +e
        shopt -s dotglob
        rm -f /usr/share/elasticsearch/config/*.pem
{{- end -}}


{{/*
init container template

TODO: replace this with a daemon set

*/}}
{{- define "generate-certificates-init-container" -}}
- name: generate-certificates
  image: "floragunncom/sg-sgadmin:{{ .Values.common.elkversion }}-{{ .Values.common.sgversion }}"
  imagePullPolicy: {{ .Values.common.pullPolicy }}
  volumeMounts:
    - name: kubectl
      mountPath: /kubectl
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
    - sh
    - -c
    - |
        #!/usr/bin/env bash -e

        cp /usr/bin/kubectl /kubectl/kubectl

        until kubectl get secrets {{ template "fullname" . }}-root-ca-secret; do
          echo 'Wait for {{ template "fullname" . }}-root-ca-secret'; 
          sleep 10 ; 
        done

        echo "OK, {{ template "fullname" . }}-root-ca-secret exists now"

        KIBANA_ELB="$(kubectl get svc {{ template "fullname" . }} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
        ES_ELB="$(kubectl get svc {{ template "fullname" . }}-clients -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

        cat >"{{ template "fullname" . }}-$NODE_NAME-node-cert.yml" <<EOL
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
              - {{ template "fullname" . }}-discovery.{{ .Release.Namespace }}.svc
              - {{ template "fullname" . }}-clients.{{ .Release.Namespace }}.svc
              - $KIBANA_ELB
              - $ES_ELB
            ip: $POD_IP
        EOL

        cat {{ template "fullname" . }}-$NODE_NAME-node-cert.yml

        kubectl get secrets {{ template "fullname" . }}-root-ca-secret -o jsonpath="{.data.crt\.pem}" | base64 -d > /tmp/root-ca.pem
        kubectl get secrets {{ template "fullname" . }}-root-ca-secret -o jsonpath="{.data.key\.pem}" | base64 -d > /tmp/root-ca.key

        /root/tlstool/tools/sgtlstool.sh -crt -v -c "{{ template "fullname" . }}-$NODE_NAME-node-cert.yml" -t /tmp/

        kubectl patch secret {{ template "fullname" . }}-nodes-cert-secret -p="{\"data\":{\"$NODE_NAME.pem\": \"$(cat /tmp/$NODE_NAME.pem | base64 -w0)\", \"$NODE_NAME.key\": \"$(cat /tmp/$NODE_NAME.key | base64 -w0)\", \"root-ca.pem\": \"$(cat /tmp/root-ca.pem | base64 -w0)\"}}" -v=5
        #cat /tmp/*snippet.yml

  resources:
    limits:
      cpu: "500m"
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
{{- end -}}

{{- define "init-containers" -}}
- name: init-sysctl
  image: busybox
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

{{ include "generate-certificates-init-container" . }}

{{- if .Values.common.plugins }}
- name: es-plugin-install
  image: "floragunncom/sg-elasticsearch:{{ .Values.common.elkversion }}-{{ .Values.common.sgversion }}"
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
  image: busybox
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
