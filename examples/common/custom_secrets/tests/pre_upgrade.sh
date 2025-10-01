#!/bin/bash
set -x
#$1 - namespace
#$2 - yaml files folder

# Create test secrets
kubectl create secret generic common-super-secret -n $1 --from-literal=secret=CommonSecretPassword
kubectl create secret generic kibana-super-secret -n $1 --from-literal=secret=KibanaSecretPassword
