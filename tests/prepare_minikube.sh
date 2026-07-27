#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
K8S_VERSION=${1:-"v1.36.1"}
killall -9 minikube
killall -9 kubectl
killall -9 helm

echo "****** Preparing minikube $(minikube version --short) for Kubernetes version $K8S_VERSION *****"

PROFILE=multinode
minikube config set memory 8192 -p "$PROFILE"
minikube config set cpus 4 -p "$PROFILE"
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

if [ "${CI:-}" != "true" ]; then
  minikube dashboard -p "$PROFILE" &
fi

echo "******* Created minikube version $K8S_VERSION ******"
