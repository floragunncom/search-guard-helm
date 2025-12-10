#!/bin/bash
set -x
#$1 - namespace
#$2 - yaml files folder
kubectl -n $1 delete sts -l role=data
kubectl -n $1 wait --for=delete pod -l role=data --timeout=300s
kubectl -n $1 delete sts -l role=data-content
kubectl -n $1 wait --for=delete pod -l role=data-content --timeout=300s
