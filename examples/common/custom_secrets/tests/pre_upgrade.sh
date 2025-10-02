#!/bin/bash
set -x
#$1 - namespace
#$2 - yaml files folder

# Create test secrets
kubectl create secret generic common-custom-secret -n $1 --from-literal=secret=CommonSuperSecret --from-literal=password=CommonSecretPassword
kubectl create secret generic kibana-custom-secret -n $1 --from-literal=secret=KibanaSuperSecret --from-literal=password=KibanaSecretPassword
