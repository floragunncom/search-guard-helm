#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
K8S_VERSION=${1:-"v1.36.1"}
killall -9 minikube
killall -9 kubectl
killall -9 helm

echo "****** Preparing minikube $(minikube version --short) for Kubernetes version $K8S_VERSION *****"

PROFILE=multinode
# Isolated, disposable runner: give each node as much of the host as possible
# rather than a fixed cap, so the app is never throttled below what the machine
# has. "max" removes the per-node cgroup limit (see the diagnostics block below).
minikube config set memory max -p "$PROFILE"
minikube config set cpus max -p "$PROFILE"
minikube delete -p "$PROFILE"
set -e
FORCE_ARG=""
if [ "$(id -u)" -eq 0 ]; then
  FORCE_ARG="--force"
fi
minikube start --kubernetes-version "$K8S_VERSION"  --container-runtime=containerd  --nodes 3 -p "$PROFILE" --wait=true $FORCE_ARG

#fix minikube issues with hostpath permissions on multicluster nodes
#https://github.com/kubernetes/minikube/issues/12165
#https://stackoverflow.com/questions/60479594/minikube-volume-write-permissions
curl -Ss https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml | sed 's/\/opt\/local-path-provisioner/\/var\/opt\/local-path-provisioner/ ' | kubectl apply -f -
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

if [ "${CI:-}" = "true" ]; then
  # In CI, force writable permissions on newly provisioned local-path volumes.
  # This avoids ES startup failure when the JVM tries to write logs/gc.log.
  cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-path-config
  namespace: local-path-storage
data:
  config.json: |-
    {
      "nodePathMap":[
      {
        "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
        "paths":["/var/opt/local-path-provisioner"]
      }
      ]
    }
  setup: |-
    #!/bin/sh
    set -eu
    mkdir -m 0777 -p "$VOL_DIR"
    chown 1000:1000 "$VOL_DIR" || true
    chmod 0777 "$VOL_DIR" || true
  teardown: |-
    #!/bin/sh
    set -eu
    rm -rf "$VOL_DIR"
  helperPod.yaml: |-
    apiVersion: v1
    kind: Pod
    metadata:
      name: helper-pod
    spec:
      priorityClassName: system-node-critical
      tolerations:
        - key: node.kubernetes.io/disk-pressure
          operator: Exists
          effect: NoSchedule
      containers:
      - name: helper-pod
        image: busybox
        imagePullPolicy: IfNotPresent
EOF
  kubectl -n local-path-storage rollout restart deploy/local-path-provisioner || true
  kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=120s || true
fi

minikube -p "$PROFILE" addons enable metrics-server
minikube -p "$PROFILE" addons enable ingress

# Resource diagnostics: --memory/--cpus are applied *per node*, so with
# --nodes 3 the requested totals are 3x the configured per-node values
# (e.g. 8192Mi/4cpu -> ~24Gi/12cpu). Print the real per-node Capacity and
# Allocatable the scheduler sees, so every run records the resource picture.
echo "******* minikube resource diagnostics ($PROFILE) *******"
minikube node list -p "$PROFILE" || true
echo "--- node Capacity / Allocatable (cpu, memory) ---"
kubectl get nodes -o custom-columns=\
'NODE:.metadata.name,'\
'CAP_CPU:.status.capacity.cpu,CAP_MEM:.status.capacity.memory,'\
'ALLOC_CPU:.status.allocatable.cpu,ALLOC_MEM:.status.allocatable.memory' || true
echo "--- per-node-container docker limits vs host memory ---"
# Goal on this (isolated, disposable) runner: let the app use as much of the
# host as possible. With the docker driver the node's kubelet advertises the
# *host's* full memory/cpu, but Docker still applies the --memory value as a
# cgroup cap on the node container. If that cap is below the advertised host
# memory the app is throttled below what the machine actually has -> warn, so
# it is obvious the --memory setting is leaving RAM on the table. A dropped
# cpu cap (0 nanocpus) is what we want here, not a problem.
for node in $(minikube node list -p "$PROFILE" 2>/dev/null | awk '{print $1}'); do
  dock_mem=$(docker inspect "$node" --format '{{.HostConfig.Memory}}' 2>/dev/null || echo "")
  dock_cpu=$(docker inspect "$node" --format '{{.HostConfig.NanoCpus}}' 2>/dev/null || echo "")
  cap_mem_ki=$(kubectl get node "$node" -o jsonpath='{.status.capacity.memory}' 2>/dev/null | tr -dc '0-9')
  if [ -z "$dock_mem" ] || [ -z "$cap_mem_ki" ]; then
    echo "$node: unable to inspect (docker/kubectl returned nothing)"
    continue
  fi
  host_bytes=$((cap_mem_ki * 1024))
  cpu_note="cpu: uncapped (all host cores)"
  [ "${dock_cpu:-0}" != "0" ] && cpu_note="cpu: CAPPED at $dock_cpu nanocpus"
  if [ "$dock_mem" = "0" ]; then
    printf '%s: mem cgroup cap: none (can use full host RAM), %s\n' "$node" "$cpu_note"
  else
    cap_gib=$(awk "BEGIN{printf \"%.1f\", $dock_mem/1073741824}")
    host_gib=$(awk "BEGIN{printf \"%.1f\", $host_bytes/1073741824}")
    printf '%s: mem cgroup cap: %sGi of %sGi host, %s\n' "$node" "$cap_gib" "$host_gib" "$cpu_note"
    if [ "$dock_mem" -lt "$host_bytes" ]; then
      echo "  [WARN] node is memory-capped at ${cap_gib}Gi but the host has ${host_gib}Gi."
      echo "  [WARN] The app cannot use ~$(awk "BEGIN{printf \"%.1f\", ($host_bytes-$dock_mem)/1073741824}")Gi of available RAM on this node."
      echo "  [WARN] For max headroom set 'minikube config set memory max' (or 'no-limit') instead of a fixed value."
    fi
  fi
done
echo "*********************************************************"

if [ "${CI:-}" != "true" ]; then
  minikube dashboard -p "$PROFILE" &
fi

echo "******* Created minikube version $K8S_VERSION ******"
