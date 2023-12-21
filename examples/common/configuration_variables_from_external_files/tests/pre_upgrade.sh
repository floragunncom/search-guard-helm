#!/bin/bash

#$1 - namespace
#$2 - yaml files folder

SECRET_NAME=sg-elk-search-guard-flx-external-files

echo "Create the secret $SECRET_NAME"
if kubectl -n $1 get secret "$SECRET_NAME" &> /dev/null; then
    kubectl -n $1 delete secret "$SECRET_NAME"
fi

kubectl -n $1  create  secret generic $SECRET_NAME --from-file=$2/jwks-secret


#Disable license tests
cp -f $2/values.yaml $2/values.yaml.bak
sed -i '/^[[:space:]]*license:/s/^/#/' $2/values.yaml
