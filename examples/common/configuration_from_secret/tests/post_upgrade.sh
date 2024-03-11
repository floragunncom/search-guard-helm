#!/bin/bash

#$1 - namespace
#$2 - yaml files folder
waitport() {
    while ! nc -z localhost $1 ; do sleep 1 ; done
}


SECRET_NAME=sg-elk-search-guard-flx-sg-dynamic-configuration-secret

if ! netstat -tuln | grep -q ":9200 "; then
  kubectl port-forward -n $1 service/sg-elk-search-guard-flx-clients 9200:9200 &
fi

waitport 9200

curl --fail-with-body -i  -k https://127.0.0.1:9200/_searchguard/authinfo -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbiIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMiwicm9sZXMiOiJhZG1pbiJ9.eTgf-bQfD9XSF2mHsumdbAMoSVwLYoytv2K5LkRDJyQ"


if [ $? -ne 0 ]; then
  echo "curl command failed or received a non-200 HTTP response code"
  exit -1
fi


if kubectl -n $1 get secret "$SECRET_NAME" &> /dev/null; then
    kubectl -n $1 delete secret "$SECRET_NAME"
fi
