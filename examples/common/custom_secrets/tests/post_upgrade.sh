#!/bin/bash

#$1 - namespace
#$2 - yaml files folder

# Check test secrets
POD_NAME=$(kubectl -n $1 get pods -l role=kibana -o jsonpath='{.items[0].metadata.name}')
COMMON_SECRET=$(kubectl -n $1 exec $POD_NAME -c kibana -- printenv COMMON_CUSTOM_SECRET)
COMMON_PASSWORD=$(kubectl -n $1 exec $POD_NAME -c kibana -- printenv COMMON_CUSTOM_PASSWORD)
KIBANA_SECRET=$(kubectl -n $1 exec $POD_NAME -c kibana -- printenv KIBANA_CUSTOM_SECRET)
KIBANA_PASSWORD=$(kubectl -n $1 exec $POD_NAME -c kibana -- printenv KIBANA_CUSTOM_PASSWORD)

if [ ${COMMON_SECRET} != 'CommonSuperSecret' ]; then
  echo "Wrong common secret ${COMMON_SECRET} (should be 'CommonSuperSecret')"
  exit 1
fi
echo "Common secret OK"

if [ ${COMMON_PASSWORD} != 'CommonSecretPassword' ]; then
  echo "Wrong common password '${COMMON_PASSWORD}' should be 'CommonSecretPassword'"
  exit 1
fi
echo "Common password OK"

if [ ${KIBANA_SECRET} != 'KibanaSuperSecret' ]; then
  echo "Wrong kibana secret found '${KIBANA_SECRET}' should be 'KibanaSuperSecret'"
  exit 1
fi

echo "Kibana secret OK"

if [ ${KIBANA_PASSWORD} != 'KibanaSecretPassword' ]; then
  echo "Wrong kibana password ${KIBANA_PASSWORD} (should be 'KibanaSecretPassword')"
  exit 1
fi
echo "Kibana password OK"
echo "Custom env-secrets OK"
