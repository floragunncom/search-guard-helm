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
  # The job container can reach the DinD service via the hostname `docker`.
  # Using 127.0.0.1 here breaks kubectl connectivity inside CI.
  apiServerAddress: docker
nodes:
  - role: control-plane
  # Single-node kind cluster.
  # Elasticsearch node-count (used by tests) is independent of Kubernetes node-count.
EOF

# Create a single-node kind cluster.
kind create cluster --name "${KIND_CLUSTER_NAME}" --image "${KIND_NODE_IMAGE}" --config "${SCRIPT_DIR}/kind-config.yaml" --wait=60s

# Ensure local-path storage exists (chart defaults expect storageClass "local-path").
curl -Ss https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml \
  | kubectl apply -f -

kubectl config use-context "${KIND_CONTEXT}"

echo "******* Created kind cluster ${KIND_CLUSTER_NAME} *******"

