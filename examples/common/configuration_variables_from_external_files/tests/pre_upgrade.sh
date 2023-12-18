#!/bin/bash
#$1 - namespace
#$2 - yaml files folder

#create jwks configuration variable
# POD_NAME=$(kubectl -n $1 get pods -l role=sgctl-cli -o jsonpath='{.items[0].metadata.name}')
# kubectl -n $1 cp $2/keys.json $POD_NAME:/tmp/keys.json
# kubectl -n $1 exec $POD_NAME -- /usr/share/sg/sgctl/sgctl.sh add-var jwks -h sg-elk-search-guard-flx-discovery.integtests.svc --key /sgcerts/key.pem --cert /sgcerts/crt.pem --ca-cert /sgcerts/root-ca.pem --input-file /tmp/keys.json
#Disable license tests