#!/bin/bash

#$1 - namespace
#$2 - yaml files folder

# Check test secrets
ES_POD_NAME=$(kubectl -n $1 get pods -l role=master -o jsonpath='{.items[0].metadata.name}')
COMMON_SECRET=$(kubectl -n $1 exec $ES_POD_NAME -c elasticsearch -- printenv COMMON_CUSTOM_SECRET)
KIBANA_POD_NAME=$(kubectl -n $1 get pods -l role=kibana -o jsonpath='{.items[0].metadata.name}')
KIBANA_SECRET=$(kubectl -n $1 exec $KIBANA_POD_NAME -c kibana -- printenv KIBANA_CUSTOM_SECRET)

if [ ${COMMON_SECRET} != 'CommonSecretPassword' ]; then
  echo "Wrong common secret ${COMMON_SECRET} (should be 'CommonCustomSecret')"
  exit 1
fi
echo "Common secret OK"

if [ ${KIBANA_SECRET} != 'KibanaSecretPassword' ]; then
  echo "Wrong kibana secret ${COMMON_SECRET} (should be 'KibanaCustomSecret')"
  exit 1
fi
echo "Kibana secret OK"

kubectl delete secret common-custom-secret -n $1 
kubectl delete secret kibana-custom-secret -n $1
