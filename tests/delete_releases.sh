#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

helm del sg-elk -n defaultinstall --wait
helm del sg-elk -n integtests --wait

kubectl delete jobs -n defaultinstall -l app=sg-elk-search-guard-flx
kubectl delete secrets -n defaultinstall -l app=sg-elk-search-guard-flx
kubectl delete pvc -n defaultinstall -l component=sg-elk-search-guard-flx -o name

kubectl delete jobs -n integtests -l app=sg-elk-search-guard-flx
kubectl delete secrets -n integtests -l app=sg-elk-search-guard-flx
kubectl delete pvc -n integtests -l component=sg-elk-search-guard-flx -o name
sleep 5
echo "Finished"

