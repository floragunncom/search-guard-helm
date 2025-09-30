#!/bin/bash
set -x
#$1 - namespace
#$2 - yaml files folder

#create jwks configuration variable
POD_NAME=$(kubectl -n $1 get pods -l role=kibana -o jsonpath='{.items[0].metadata.name}')
cp -f $2/values.yaml $2/values.yaml.bak

# Create test secrets
kubectl create secret generic common-super-secret -n $1 --from-literal=password=CommonSecretPassword
kubectl create secret generic kibana-super-secret -n $1 --from-literal=password=KibanaSecretPassword
