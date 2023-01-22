#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$CI" ]; then
  kill -9 $(pgrep -d ' ' -f "kubectl port-forward")  > /dev/null 2>&1
fi

NSP="$1"

echo ""
echo ""
echo "############################## Upgrade $2 ... ######################################################"
echo ""
#--force
#--atomic 
#--debug
helm upgrade sg-elk "$SCRIPT_DIR/.."  --timeout 30m0s -n ${NSP} --reuse-values -f "$2"
retVal=$?
echo ""
if [ $retVal -ne 0 ]; then
  echo "Upgrade failed"
  exit -1
fi
echo ""
KIBANA_REPLICAS=$(kubectl get sts sg-elk-search-guard-flx-kibana -n ${NSP} -o=jsonpath='{.status.replicas}')

if [ "$KIBANA_REPLICAS" != "0" ];then
  echo "Waiting for kibana ($(date)) ..."
  kubectl wait --for=condition=Ready pod/sg-elk-search-guard-flx-kibana-0 --timeout=300s -n ${NSP}
  retVal=$?
  echo ""
  if [ $retVal -ne 0 ]; then
    echo "Kibana not ready, upgrade failed"
    exit -1
  fi
else
  echo "No Kibana pods to wait for"
fi

echo ""
echo "Upgrade OK"
SG_ADMIN_PWD=$(kubectl get secrets sg-elk-search-guard-flx-passwd-secret -n ${NSP} -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d)
#POD_NAME=$(kubectl get pods -n ${NSP} -l "component=sg-elk-search-guard-flx,role=client" -o jsonpath="{.items[0].metadata.name}")
#KPOD_NAME=$(kubectl get pods -n ${NSP} -l "component=sg-elk-search-guard-flx,role=kibana" -o jsonpath="{.items[0].metadata.name}")

kubectl port-forward -n ${NSP} service/sg-elk-search-guard-flx-clients 9200:9200 &
kctlpid="$!"
#kubectl port-forward -n ${NSP} service/sg-elk-search-guard-flx 5601:5601 &
sleep 5
until curl --fail -k -u "admin:$SG_ADMIN_PWD" "https://localhost:9200/_cluster/health?wait_for_status=green&wait_for_no_initializing_shards=true&wait_for_no_relocating_shards=true&pretty&wait_for_nodes=$3"; do
     
     if ! ps -p $kctlpid > /dev/null
     then
        kubectl port-forward -n ${NSP} service/sg-elk-search-guard-flx-clients 9200:9200 &
        kctlpid="$!"
         echo "Wait for port forward after restarted port forwarding ..."
     else
         echo "Wait for port forward ... ($?)"
     fi

     curl -k -u "admin:$SG_ADMIN_PWD" "https://localhost:9200/_cluster/health?pretty"
     sleep 5
done

echo "Update $2 done"

