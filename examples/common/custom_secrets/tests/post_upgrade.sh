#!/bin/bash

#$1 - namespace
#$2 - yaml files folder

# Check test secrets
POD_NAME=$(kubectl -n $1 get pods -l role=kibana -o jsonpath='{.items[0].metadata.name}')
COMMON_SECRET=$(kubectl -n $1 exec $POD_NAME -c kibana -- printenv COMMON_SUPER_SECRET)
KIBANA_SECRET=$(kubectl -n $1 exec $POD_NAME -c kibana -- printenv KIBANA_SUPER_SECRET)

if [ ${COMMON_SECRET} != 'CommonSecretPassword' ]; then
  echo "Wrong common secret ${COMMON_SECRET} (should be 'CommonSuperSecret')"
  exit 1
fi
echo "Common secret OK"

if [ ${KIBANA_SECRET} != 'KibanaSecretPassword' ]; then
  echo "Wrong kibana secret ${COMMON_SECRET} (should be 'KibanaSuperSecret')"
  exit 1
fi
echo "Kibana secret OK"

kubectl delete secret common-super-secret -n $1 
kubectl delete secret kibana-super-secret -n $1
