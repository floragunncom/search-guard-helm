#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

K8S_VERSION="${1:-"v1.34.0"}"
KIND_CLUSTER_NAME="${2:-"kind"}"

K8S_VERSION_STRIPPED="${K8S_VERSION#v}"
KIND_NODE_IMAGE="kindest/node:v${K8S_VERSION_STRIPPED}"
KIND_CONTEXT="${KIND_CLUSTER_NAME}-${KIND_CLUSTER_NAME}"

echo "****** Preparing kind cluster (image: ${KIND_NODE_IMAGE}, context: ${KIND_CONTEXT}) *****"

kind delete cluster --name "${KIND_CLUSTER_NAME}" >/dev/null 2>&1 || true

cat > "${SCRIPT_DIR}/kind-config.yaml" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  # Bind apiserver on all interfaces so the CI job container can reach it.
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
nodes:
  - role: control-plane
  # Single-node kind cluster.
  # Elasticsearch node-count (used by tests) is independent of Kubernetes node-count.
EOF

# Create a single-node kind cluster.
kind create cluster --name "${KIND_CLUSTER_NAME}" --image "${KIND_NODE_IMAGE}" --config "${SCRIPT_DIR}/kind-config.yaml" --wait=60s

# Ensure local-path host root is writable for Elasticsearch uid/gid (1000).
# This is CI/runtime-specific and keeps chart values untouched.
KIND_NODE_CONTAINER="${KIND_CLUSTER_NAME}-control-plane"
docker exec "${KIND_NODE_CONTAINER}" sh -c '
  mkdir -p /opt/local-path-provisioner
  chown -R 1000:1000 /opt/local-path-provisioner
  chmod -R g+rwX /opt/local-path-provisioner
'

# Switch to kind context and rewrite the kubeconfig server to point to the DinD service hostname.
# Default kind kubeconfig uses 127.0.0.1:<random_port>, which isn't reachable from the CI job container.
kubectl config use-context "${KIND_CONTEXT}"
SERVER_URL="$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')"
CLUSTER_NAME="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')"
kubectl config set-cluster "${CLUSTER_NAME}" \
  --server "https://docker:6443" \
  --insecure-skip-tls-verify=true >/dev/null

# Ensure local-path storage exists (chart defaults expect storageClass "local-path").
curl -Ss https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml \
  | kubectl apply --validate=false -f -

# In CI, force writable permissions on newly provisioned local-path volumes.
# This avoids ES startup failure when JVM tries to write logs/gc.log.
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
        "paths":["/opt/local-path-provisioner"]
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

# Make sure provisioner picks up updated setup script.
kubectl -n local-path-storage rollout restart deploy/local-path-provisioner || true
kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=120s || true

echo "******* Created kind cluster ${KIND_CLUSTER_NAME} *******"

