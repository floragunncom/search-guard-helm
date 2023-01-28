#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

NSP="$1"

CONTEXT="$(kubectl config current-context)"

if [ "$4" != "nocontext" ]; then
  if [ "$CONTEXT" != "multinode" ] && [ "$CONTEXT" != "kind-kind" ]; then
    echo "Assume AWS ($CONTEXT)"
    OVERRIDE="$SCRIPT_DIR/initial_values_aws.yaml"
  else
    echo "Assume Minikube ($CONTEXT)"
    OVERRIDE="$SCRIPT_DIR/initial_values_minikube.yaml"
  fi
else
  OVERRIDE="$SCRIPT_DIR/empty.yaml"
  echo "${CONTEXT}, no override"
fi

if [ -z "$CI" ]; then
  kill -9 $(pgrep -d ' ' -f "kubectl port-forward")  > /dev/null 2>&1
fi


kubectl delete jobs -n ${NSP} -l app=sg-elk-search-guard-flx > /dev/null 2>&1
kubectl delete secrets -n ${NSP} -l app=sg-elk-search-guard-flx > /dev/null 2>&1
helm del sg-elk --wait --timeout 30m0s -n ${NSP}
helm del sg-elk --wait --timeout 30m0s -n "defaultinstall"
kubectl delete pvc -n ${NSP} -l component=sg-elk-search-guard-flx -o name


echo ""
echo ""
echo ""
echo "---------------------- Installing via helm $2 $3... --------------------------------------------------------------------------------------------------"
#--debug 
helm install sg-elk "$SCRIPT_DIR/.." --create-namespace  --wait --timeout 30m0s -n ${NSP} -f "$2" -f "$3" -f "$OVERRIDE"
retVal=$?

if [ $retVal -ne 0 ]; then
  echo ""
  echo "Installation failed"
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
    echo "Kibana not ready, initial installation failed"
    exit -1
  fi
else
  echo "No Kibana pods to wait for"
fi

echo ""
echo "Installing OK ($(date))"
SG_ADMIN_PWD=$(kubectl get secrets sg-elk-search-guard-flx-passwd-secret -n ${NSP} -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d)
POD_NAME=$(kubectl get pods -n ${NSP} -l "component=sg-elk-search-guard-flx,role=client" -o jsonpath="{.items[0].metadata.name}")
#KPOD_NAME=$(kubectl get pods -n ${NSP} -l "component=sg-elk-search-guard-flx,role=kibana" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward -n ${NSP} $POD_NAME 9200:9200 &
#kubectl port-forward -n ${NSP} $KPOD_NAME 5601:5601 &
sleep 5
until curl --fail -k -u "admin:$SG_ADMIN_PWD" "https://localhost:9200/_cluster/health?wait_for_status=green&wait_for_no_initializing_shards=true&wait_for_no_relocating_shards=true&wait_for_nodes=7&pretty"; do
     echo "Wait for port forward ... ($?)"
     curl -k -u "admin:$SG_ADMIN_PWD" "https://localhost:9200/_cluster/health?pretty"
     sleep 5
done

echo "Initial cluster is up !!"
echo "SG_ADMIN_PWD: $SG_ADMIN_PWD"