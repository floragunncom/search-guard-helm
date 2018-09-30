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

{{/*
init container template

TODO: replace this with a daemon set

*/}}
{{- define "init-containers" -}}
- name: init-sysctl
  image: busybox
  imagePullPolicy: IfNotPresent
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

{{- if .Values.common.plugins }}
- name: es-plugin-install
  image: "{{ .Values.common.image.repository }}:{{ .Values.common.image.tag }}"
  imagePullPolicy: {{ .Values.common.image.pullPolicy }}
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
