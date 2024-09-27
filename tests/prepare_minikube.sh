#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION=${1:-"v1.29.5"}
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

minikube -p "$PROFILE" addons enable storage-provisioner-rancher
minikube -p "$PROFILE" addons enable metrics-server
minikube dashboard -p "$PROFILE" &

echo "******* Created minikube version $VERSION ******"


