#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION=${1:-"v1.32.1"}
killall -9 minikube
killall -9 kubectl
killall -9 helm

echo "****** Preparing minikube version $VERSION *****"

PROFILE=multinode
minikube config set memory 8192 -p "$PROFILE"
minikube config set cpus 4 -p "$PROFILE"
minikube delete -p "$PROFILE"
set -e
minikube start --kubernetes-version "$VERSION" --nodes 3 -p "$PROFILE" --wait=true

#fix minikube issues with hostpath permissions on multicluster nodes
#https://github.com/kubernetes/minikube/issues/12165
#https://stackoverflow.com/questions/60479594/minikube-volume-write-permissions
curl -Ss https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml | sed 's/\/opt\/local-path-provisioner/\/var\/opt\/local-path-provisioner/ ' | kubectl apply -f -
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
minikube -p "$PROFILE" addons enable metrics-server
minikube -p "$PROFILE" addons enable ingress
minikube dashboard -p "$PROFILE" &

echo "******* Created minikube version $VERSION ******"


