#!/bin/bash
set -x
#$1 - namespace
#$2 - yaml files folder

# Create test secrets
kubectl create secret generic common-custom-secret -n $1 --from-literal=password=CommonSecretPassword  --from-literal=key2=supersecret
kubectl create secret generic kibana-custom-secret -n $1 --from-literal=password=KibanaSecretPassword  --from-literal=key2=topsecret